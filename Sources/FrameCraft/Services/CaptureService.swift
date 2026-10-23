import AppKit
import AVFoundation
import Combine
import CoreMedia
import ScreenCaptureKit

struct CaptureSource: Identifiable {
    enum Kind: String { case display = "Bildschirm", window = "Fenster" }
    let id: String
    let title: String
    let kind: Kind
    let display: SCDisplay?
    let window: SCWindow?
}

/// Captures only after an explicit start action. The output delegate is the
/// authority for completion: stopping the stream alone does not finalize a file.
@MainActor
final class CaptureService: NSObject, ObservableObject {
    @Published var sources: [CaptureSource] = []
    @Published var selectedID: String?
    @Published private(set) var isRecording = false
    @Published private(set) var isPreparing = false
    @Published private(set) var elapsed: Double = 0
    @Published var errorMessage: String?
    @Published private(set) var isRefreshingSources = false
    @Published private(set) var needsScreenPermission = false
    private let loadShareableContent: () async throws -> SCShareableContent
    var captureSystemAudio = true
    var captureMicrophone = false
    var onFinished: ((URL, [ClickSample], CursorTrack) -> Void)?

    private var stream: SCStream?
    private var recording: SCRecordingOutput?
    private var firstFrameObserver: FirstCaptureFrame?
    private var sessionID: UUID?
    private var outputURL: URL?
    private var activeSource: CaptureSource?
    private var content: SCShareableContent?
    private var recordingEpoch: Double?
    private var clicks: [ClickSample] = []
    private var cursorSamples: [CursorSample] = []
    private var mouseTimer: Timer?
    private var lastLeftCount: UInt32 = 0
    private var lastRightCount: UInt32 = 0
    private var windowInventory: [[String: Any]] = []
    private var lastInventoryTime = -Double.infinity
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var timer: Timer?
    private var watchdog: Task<Void, Never>?
    private var isStopping = false
    private var startWaiter: CheckedContinuation<Void, Never>?
    private var stopWaiters: [CheckedContinuation<Void, Never>] = []

    init(loadShareableContent: @escaping () async throws -> SCShareableContent = {
        try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
    }) {
        self.loadShareableContent = loadShareableContent
        super.init()
    }

    func refreshSources() async {
        guard sessionID == nil, !isRefreshingSources else { return }
        isRefreshingSources = true
        errorMessage = nil
        defer { isRefreshingSources = false }
        do {
            let available = try await loadShareableContent()
            guard sessionID == nil else { return }
            needsScreenPermission = false
            content = available
            let displays = available.displays.enumerated().map { index, display in
                CaptureSource(id: "display-\(display.displayID)", title: "Bildschirm \(index + 1) · \(display.width) × \(display.height)", kind: .display, display: display, window: nil)
            }
            let windows = available.windows.filter {
                $0.owningApplication?.processID != ProcessInfo.processInfo.processIdentifier &&
                $0.windowLayer == 0 && $0.frame.width > 100 && $0.frame.height > 80 &&
                !($0.title ?? "").isEmpty
            }.sorted { ($0.owningApplication?.applicationName ?? "") < ($1.owningApplication?.applicationName ?? "") }.map { window in
                CaptureSource(id: "window-\(window.windowID)", title: "\(window.owningApplication?.applicationName ?? "App") — \(window.title ?? "Fenster")", kind: .window, display: nil, window: window)
            }
            sources = displays + windows
            if !sources.contains(where: { $0.id == selectedID }) { selectedID = sources.first?.id }
            errorMessage = sources.isEmpty ? "Keine Aufnahmequelle gefunden." : nil
        } catch {
            // Never retain a selectable source after permission was revoked or
            // enumeration failed. A stale selection must not start a recording.
            sources = []
            selectedID = nil
            content = nil
            let failure = error as NSError
            needsScreenPermission = failure.domain == SCStreamErrorDomain &&
                failure.code == SCStreamError.Code.userDeclined.rawValue
            errorMessage = needsScreenPermission
                ? "FrameCraft hat noch keinen Zugriff auf deinen Bildschirm. Aktiviere FrameCraft in den Systemeinstellungen und klicke danach auf „Erneut prüfen“. Falls macOS es verlangt, speichere dein Projekt und öffne die App erneut."
                : "Aufnahmequellen konnten nicht geladen werden. Versuche es erneut. \(error.localizedDescription)"
        }
    }

    func openScreenRecordingSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"),
              NSWorkspace.shared.open(url) else {
            errorMessage = "Öffne Systemeinstellungen → Datenschutz & Sicherheit → Bildschirm- & Systemaudioaufnahme und aktiviere FrameCraft."
            return
        }
    }

    func start(to url: URL) async {
        guard sessionID == nil, !isPreparing, !isRecording, !isRefreshingSources else { return }
        guard let source = sources.first(where: { $0.id == selectedID }), let content else {
            errorMessage = "Wähle zuerst eine Aufnahmequelle."; return
        }
        guard url.isFileURL, !FileManager.default.fileExists(atPath: url.path) else {
            errorMessage = "Das Aufnahmeziel muss eine neue lokale Datei sein."; return
        }
        let id = UUID()
        sessionID = id
        isPreparing = true
        errorMessage = nil
        elapsed = 0
        clicks = []; cursorSamples = []
        lastInventoryTime = -Double.infinity
        recordingEpoch = nil
        outputURL = url
        activeSource = source

        if captureMicrophone {
            let granted: Bool
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized: granted = true
            case .notDetermined: granted = await AVCaptureDevice.requestAccess(for: .audio)
            default: granted = false
            }
            guard sessionID == id, !isStopping else { return }
            guard granted else {
                fail("Mikrofonzugriff ist nicht erlaubt. Erlaube ihn in den Systemeinstellungen oder deaktiviere das Mikrofon.")
                return
            }
        }

        let filter: SCContentFilter
        if let display = source.display {
            let ownApps = content.applications.filter { $0.processID == ProcessInfo.processInfo.processIdentifier }
            filter = SCContentFilter(display: display, excludingApplications: ownApps, exceptingWindows: [])
        } else if let window = source.window {
            filter = SCContentFilter(desktopIndependentWindow: window)
        } else { fail("Die Aufnahmequelle ist nicht mehr verfügbar."); return }

        let configuration = SCStreamConfiguration()
        let scale = CGFloat(filter.pointPixelScale)
        let size = filter.contentRect.size
        // H.264 accepts even dimensions. Limit to 3840 × 2160 while preserving ratio.
        let pixelWidth = max(2, size.width * scale)
        let pixelHeight = max(2, size.height * scale)
        let factor = min(1, min(3840 / pixelWidth, 2160 / pixelHeight))
        configuration.width = max(2, Int(pixelWidth * factor) / 2 * 2)
        configuration.height = max(2, Int(pixelHeight * factor) / 2 * 2)
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        configuration.queueDepth = 5
        configuration.showsCursor = false
        configuration.showMouseClicks = false
        configuration.ignoreShadowsSingleWindow = true
        configuration.capturesAudio = captureSystemAudio
        configuration.excludesCurrentProcessAudio = true
        configuration.captureMicrophone = captureMicrophone
        configuration.sampleRate = 48_000
        configuration.channelCount = 2
        configuration.streamName = "FrameCraft Aufnahme"

        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let newStream = SCStream(filter: filter, configuration: configuration, delegate: self)
            let settings = SCRecordingOutputConfiguration()
            settings.outputURL = url
            settings.videoCodecType = .h264
            settings.outputFileType = .mp4
            let newRecording = SCRecordingOutput(configuration: settings, delegate: self)
            let observer = FirstCaptureFrame { [weak self] timestamp in
                Task { @MainActor in
                    guard let self, self.sessionID == id else { return }
                    // ScreenCaptureKit video PTS uses the host clock. Reject an
                    // unexpected clock rather than producing invalid click times.
                    let now = ProcessInfo.processInfo.systemUptime
                    if timestamp.isFinite, abs(now - timestamp) < 30 { self.recordingEpoch = timestamp }
                }
            }
            try newStream.addStreamOutput(observer, type: .screen, sampleHandlerQueue: DispatchQueue(label: "FrameCraft.capture.clock"))
            try newStream.addRecordingOutput(newRecording)
            stream = newStream
            recording = newRecording
            firstFrameObserver = observer
            await withCheckedContinuation { continuation in
                startWaiter = continuation
                armWatchdog(seconds: 20, id: id, message: "Die Aufnahme hat nicht rechtzeitig begonnen. Bitte prüfe die Bildschirmfreigabe und versuche es erneut.")
                newStream.startCapture { [weak self] error in
                    guard let error else { return }
                    Task { @MainActor in
                        guard let self, self.sessionID == id else { return }
                        self.fail("Aufnahme konnte nicht gestartet werden: \(error.localizedDescription)")
                    }
                }
            }
        } catch { if sessionID == id { fail("Aufnahme konnte nicht vorbereitet werden: \(error.localizedDescription)") } }
    }

    func stop() async {
        guard let id = sessionID else { return }
        await withCheckedContinuation { continuation in
            stopWaiters.append(continuation)
            guard !isStopping else { return }
            isStopping = true
            isPreparing = true
            isRecording = false
            removeMonitors()
            timer?.invalidate(); timer = nil
            guard let stream else { reset(); return }
            armWatchdog(seconds: 15, id: id, message: "Das Abschließen der Aufnahme hat zu lange gedauert. Die Datei wurde nicht als fertige Aufnahme übernommen.")
            stream.stopCapture { [weak self] error in
                guard let error else { return }
                Task { @MainActor in
                    guard let self, self.sessionID == id else { return }
                    self.fail("Aufnahme konnte nicht abgeschlossen werden: \(error.localizedDescription)")
                }
            }
        }
    }

    private func armWatchdog(seconds: UInt64, id: UUID, message: String) {
        watchdog?.cancel()
        watchdog = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: seconds * 1_000_000_000) } catch { return }
            guard let self, self.sessionID == id else { return }
            self.fail(message)
        }
    }

    private func fail(_ message: String) {
        errorMessage = message
        let oldStream = stream
        reset()
        // Completion is deliberately ignored: a failed or timed-out file is never imported.
        oldStream?.stopCapture(completionHandler: { _ in })
    }

    private func reset() {
        watchdog?.cancel(); watchdog = nil
        timer?.invalidate(); timer = nil
        removeMonitors()
        stream = nil; recording = nil; firstFrameObserver = nil
        sessionID = nil; outputURL = nil; activeSource = nil; recordingEpoch = nil
        isPreparing = false; isRecording = false; isStopping = false
        startWaiter?.resume(); startWaiter = nil
        let waiters = stopWaiters; stopWaiters = []
        for waiter in waiters { waiter.resume() }
    }

    private func addMonitors() {
        removeMonitors()
        lastLeftCount = CGEventSource.counterForEventType(.combinedSessionState, eventType: .leftMouseDown)
        lastRightCount = CGEventSource.counterForEventType(.combinedSessionState, eventType: .rightMouseDown)
        let mouseTimer = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.sampleMouse() }
        }
        self.mouseTimer = mouseTimer
        RunLoop.main.add(mouseTimer, forMode: .common)
        sampleMouse()
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            // AppKit delivers event monitor handlers on the main thread.
            MainActor.assumeIsolated { self?.recordClick(event) }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            MainActor.assumeIsolated { self?.recordClick(event) }
            return event
        }
    }

    private func removeMonitors() {
        mouseTimer?.invalidate(); mouseTimer = nil
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil; localMonitor = nil
    }

    private func mouseSample(at time: Double, point: CGPoint? = nil) -> CursorSample? {
        guard isRecording, !isStopping, let source = activeSource else { return nil }
        let now = ProcessInfo.processInfo.systemUptime
        if now - lastInventoryTime > 0.1 {
            windowInventory = (CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]) ?? []
            lastInventoryTime = now
        }
        let location = point ?? CGEvent(source: nil)?.location ?? .zero
        func frame(_ info: [String: Any]) -> CGRect? {
            guard let dictionary = info[kCGWindowBounds as String] as? [String: Any] else { return nil }
            return CGRect(dictionaryRepresentation: dictionary as CFDictionary)
        }
        let bounds: CGRect
        if let display = source.display { bounds = display.frame }
        else if let window = source.window,
                let info = windowInventory.first(where: { ($0[kCGWindowNumber as String] as? UInt32) == window.windowID }),
                let current = frame(info) { bounds = current }
        else { return CursorSample(time: time, x: 0, y: 0, visible: false) }
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        let top = windowInventory.first { info in
            (info[kCGWindowLayer as String] as? Int) == 0 && frame(info)?.contains(location) == true
        }
        let ownWindow = (top?[kCGWindowOwnerPID as String] as? Int32) == ProcessInfo.processInfo.processIdentifier
        let windowMatches = source.window == nil || (top?[kCGWindowNumber as String] as? UInt32) == source.window?.windowID
        return CursorSample(time: time,
                            x: min(1, max(0, (location.x - bounds.minX) / bounds.width)),
                            y: min(1, max(0, (location.y - bounds.minY) / bounds.height)),
                            visible: bounds.contains(location) && !ownWindow && windowMatches)
    }

    private func sampleMouse() {
        let time = ProcessInfo.processInfo.systemUptime
        guard let sample = mouseSample(at: time) else { return }
        cursorSamples.append(sample)
        // Counters retain fast down/up clicks between timer ticks. Event monitors
        // provide exact timestamps when available; both paths are deduplicated.
        let left = CGEventSource.counterForEventType(.combinedSessionState, eventType: .leftMouseDown)
        let right = CGEventSource.counterForEventType(.combinedSessionState, eventType: .rightMouseDown)
        if left != lastLeftCount || right != lastRightCount { appendClick(sample) }
        lastLeftCount = left; lastRightCount = right
    }

    private func appendClick(_ sample: CursorSample) {
        guard sample.visible, !clicks.contains(where: { abs($0.time - sample.time) < 0.04 }) else { return }
        clicks.append(ClickSample(time: sample.time, x: sample.x, y: sample.y))
        cursorSamples.append(sample)
    }

    private func recordClick(_ event: NSEvent) {
        guard let sample = mouseSample(at: event.timestamp, point: event.cgEvent?.location) else { return }
        appendClick(sample)
    }

}

extension CaptureService: SCRecordingOutputDelegate, SCStreamDelegate {
    nonisolated func recordingOutputDidStartRecording(_ recordingOutput: SCRecordingOutput) {
        Task { @MainActor [weak self] in
            guard let self, self.recording === recordingOutput, !self.isStopping else { return }
            self.watchdog?.cancel(); self.watchdog = nil
            if self.recordingEpoch == nil { self.recordingEpoch = ProcessInfo.processInfo.systemUptime }
            self.isPreparing = false; self.isRecording = true
            self.addMonitors()
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, self.isRecording else { return }
                    let duration = self.recording?.recordedDuration.seconds ?? 0
                    if duration.isFinite { self.elapsed = max(0, duration) }
                }
            }
            self.startWaiter?.resume(); self.startWaiter = nil
        }
    }

    nonisolated func recordingOutput(_ recordingOutput: SCRecordingOutput, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            guard let self, self.recording === recordingOutput else { return }
            self.fail("Aufnahmedatei konnte nicht geschrieben werden: \(error.localizedDescription)")
        }
    }

    nonisolated func recordingOutputDidFinishRecording(_ recordingOutput: SCRecordingOutput) {
        Task { @MainActor [weak self] in
            guard let self, self.recording === recordingOutput, let url = self.outputURL else { return }
            let duration = recordingOutput.recordedDuration.seconds
            if duration.isFinite { self.elapsed = max(0, duration) }
            let epoch = self.recordingEpoch ?? ProcessInfo.processInfo.systemUptime
            let samples = self.clicks.map { ClickSample(time: $0.time - epoch, x: $0.x, y: $0.y) }
                .filter { $0.time >= 0 && $0.time <= self.elapsed }.sorted { $0.time < $1.time }
            var positions = self.cursorSamples.map { CursorSample(time: max(0, $0.time - epoch), x: $0.x, y: $0.y, visible: $0.visible) }
                .filter { $0.time <= self.elapsed }.sorted { $0.time < $1.time }
            // Keep timestamps strictly increasing for deterministic interpolation.
            positions = positions.enumerated().filter { $0.offset == 0 || $0.element.time > positions[$0.offset - 1].time }.map(\.element)
            let cursor = CursorTrack(samples: positions)
            let oldStream = self.stream
            let wasStopping = self.isStopping
            self.reset()
            if !wasStopping { oldStream?.stopCapture(completionHandler: { _ in }) }
            self.onFinished?(url, samples, cursor)
        }
    }

    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        Task { @MainActor [weak self] in
            guard let self, self.stream === stream else { return }
            // Stopping from macOS's sharing indicator is an ordinary user stop.
            // Keep the recording output alive until its file-finalization callback.
            let nativeError = error as NSError
            if nativeError.domain == SCStreamErrorDomain, nativeError.code == -3817,
               let id = self.sessionID {
                self.isStopping = true
                self.isPreparing = true
                self.isRecording = false
                self.removeMonitors()
                self.timer?.invalidate(); self.timer = nil
                self.armWatchdog(seconds: 15, id: id, message: "Die über macOS beendete Aufnahme konnte nicht rechtzeitig abgeschlossen werden.")
                return
            }
            self.fail("Die Bildschirmaufnahme wurde unterbrochen: \(error.localizedDescription)")
        }
    }
}

/// Reads only the first complete video frame; no screen pixels are copied or stored here.
private final class FirstCaptureFrame: NSObject, SCStreamOutput {
    private var received = false // accessed only on the serial sample queue
    private let onFirstFrame: (Double) -> Void
    init(onFirstFrame: @escaping (Double) -> Void) { self.onFirstFrame = onFirstFrame }
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, !received, sampleBuffer.isValid,
              let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
              let rawStatus = attachments.first?[.status] as? Int,
              SCFrameStatus(rawValue: rawStatus) == .complete else { return }
        received = true
        onFirstFrame(sampleBuffer.presentationTimeStamp.seconds)
    }
}
