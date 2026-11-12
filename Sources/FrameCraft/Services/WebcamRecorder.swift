import AVFoundation

/// Session, writer and sample callbacks share one serial queue.
final class WebcamRecorder: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    private let queue = DispatchQueue(label: "FrameCraft.webcam")
    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let url: URL
    private let warn: @Sendable (String) -> Void
    private var observers: [NSObjectProtocol] = []
    private var writer: AVAssetWriter?
    private var input: AVAssetWriterInput?
    private var firstFrame: Double?
    private var accepting = false
    private var ownsFile = false
    private var warned = false

    init(url: URL, warn: @escaping @Sendable (String) -> Void) {
        self.url = url
        self.warn = warn
    }

    func start() {
        queue.async { [self] in
            do {
                guard !FileManager.default.fileExists(atPath: url.path),
                      let device = AVCaptureDevice.default(for: .video) else { throw StudioError.invalidVideo }
                let camera = try AVCaptureDeviceInput(device: device)
                guard session.canAddInput(camera) else { throw StudioError.invalidVideo }
                session.addInput(camera)
                if session.canSetSessionPreset(.hd1280x720) { session.sessionPreset = .hd1280x720 }
                output.alwaysDiscardsLateVideoFrames = true
                output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                guard session.canAddOutput(output) else { throw StudioError.invalidVideo }
                session.addOutput(output)
                output.setSampleBufferDelegate(self, queue: queue)
                for (name, object) in [(AVCaptureSession.runtimeErrorNotification, session as AnyObject),
                                       (AVCaptureDevice.wasDisconnectedNotification, device as AnyObject)] {
                    observers.append(NotificationCenter.default.addObserver(forName: name, object: object, queue: nil) { [weak self] _ in
                        guard let self else { return }
                        self.queue.async { if self.accepting { self.interrupted() } }
                    })
                }
                accepting = true
                session.startRunning()
                if !session.isRunning { interrupted() }
            } catch { interrupted() }
        }
    }

    private func interrupted() {
        guard !warned else { return }
        warned = true
        stopSession()
        warn("Die Webcam ist nicht verfügbar. Die Bildschirmaufnahme läuft ohne weitere Kamerabilder weiter.")
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard accepting, let buffer = sampleBuffer.imageBuffer else { return }
        do {
            if writer == nil {
                let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
                let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: CVPixelBufferGetWidth(buffer),
                    AVVideoHeightKey: CVPixelBufferGetHeight(buffer)
                ])
                input.expectsMediaDataInRealTime = true
                guard writer.canAdd(input) else { throw StudioError.invalidVideo }
                writer.add(input)
                guard writer.startWriting() else { throw writer.error ?? StudioError.invalidVideo }
                self.writer = writer
                self.input = input
                ownsFile = true
            }
            guard let writer, let input, writer.status == .writing else { throw StudioError.invalidVideo }
            if firstFrame == nil {
                guard let clock = session.synchronizationClock else { throw StudioError.invalidVideo }
                let stamp = sampleBuffer.presentationTimeStamp
                let host = CMSyncConvertTime(stamp, from: clock, to: CMClockGetHostTimeClock()).seconds
                guard host.isFinite else { throw StudioError.invalidVideo }
                writer.startSession(atSourceTime: stamp)
                firstFrame = host
            }
            guard input.isReadyForMoreMediaData else { return }
            guard input.append(sampleBuffer) else { throw writer.error ?? StudioError.invalidVideo }
        } catch { interrupted() }
    }

    private func stopSession() {
        accepting = false
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        observers.removeAll()
        output.setSampleBufferDelegate(nil, queue: nil)
        if session.isRunning { session.stopRunning() }
    }

    func stopInput() { queue.async { self.stopSession() } }

    func discard() {
        queue.async { [self] in
            stopSession()
            if writer?.status == .writing { writer?.cancelWriting() }
            if ownsFile { try? FileManager.default.removeItem(at: url) }
        }
    }

    func finish() async -> Double? {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                stopSession()
                guard let writer, writer.status == .writing, let firstFrame else {
                    if self.writer?.status == .writing { self.writer?.cancelWriting() }
                    if ownsFile { try? FileManager.default.removeItem(at: url) }
                    continuation.resume(returning: nil)
                    return
                }
                input?.markAsFinished()
                writer.finishWriting { [self] in
                    let ok = writer.status == .completed
                    if !ok && ownsFile { try? FileManager.default.removeItem(at: url) }
                    continuation.resume(returning: ok ? firstFrame : nil)
                }
            }
        }
    }
}
