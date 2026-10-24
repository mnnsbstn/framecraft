import AppKit
import AVFoundation
import Combine
import UniformTypeIdentifiers

@MainActor
final class StudioStore: ObservableObject {
    @Published var project = Project() { didSet { if project != oldValue { saved = false } } }
    @Published var sourceURL: URL?
    @Published var projectFolder: URL?
    @Published var currentTime: Double = 0
    @Published var selectedZoom: UUID?
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published private(set) var isSaving = false
    @Published var message: String?
    @Published var saved = true
    let player = AVPlayer()
    private var observer: Any?
    private var renderTask: Task<Void, Never>?
    private var revision = 0
    private var cancellables = Set<AnyCancellable>()

    init() {
        observer = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1 / 30, preferredTimescale: 600), queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self else { return }
                self.currentTime = max(0, time.seconds.isFinite ? time.seconds : 0)
                if self.isPlaying && self.currentTime >= self.project.trimEnd {
                    self.player.pause(); self.isPlaying = false
                    self.seek(self.project.trimStart)
                }
            }
        }
        $project.dropFirst().debounce(for: .milliseconds(150), scheduler: RunLoop.main).sink { [weak self] _ in
            guard let self else { return }
            self.refreshPreview()
        }.store(in: &cancellables)
    }

    func importVideo() {
        guard !isLoading else { return }
        guard confirmReplace() else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .mpeg4Movie, .quickTimeMovie]
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        isLoading = true
        Task { await loadVideo(url) }
    }

    func loadVideo(_ url: URL, clicks: [ClickSample] = [], cursor: CursorTrack? = nil) async {
        isLoading = true; defer { isLoading = false }
        do {
            let asset = AVURLAsset(url: url)
            let duration = try await asset.load(.duration).seconds
            let tracks = try await asset.loadTracks(withMediaType: .video)
            guard duration.isFinite, duration > 0, !tracks.isEmpty else { throw StudioError.invalidVideo }
            player.pause(); isPlaying = false
            projectFolder = nil
            sourceURL = url
            project = Project(title: url.deletingPathExtension().lastPathComponent, duration: duration, trimEnd: duration, clicks: clicks)
            project.cursor = cursor
            project.generateZooms()
            selectedZoom = project.zooms.first?.id
            currentTime = 0
            refreshPreview()
        } catch { message = error.localizedDescription }
    }

    func makeDemo() {
        guard !isLoading else { return }
        guard confirmReplace() else { return }
        isLoading = true
        Task {
            do {
                let folder = try recordingsFolder()
                let url = folder.appendingPathComponent("FrameCraft-Demo-\(UUID().uuidString.prefix(8)).mp4")
                try await DemoMovie.generate(at: url)
                let positions = DemoMovie.cursorSamples
                let clicks = [positions[72], positions[246]].map { ClickSample(time: $0.time, x: $0.x, y: $0.y) }
                await loadVideo(url, clicks: clicks, cursor: CursorTrack(samples: positions))
                project.title = "Meine erste Demo"
            } catch { message = error.localizedDescription; isLoading = false }
        }
    }

    func refreshPreview() {
        guard let url = sourceURL else { return }
        revision += 1
        let expectedRevision = revision, snapshot = project
        renderTask?.cancel()
        renderTask = Task {
            do {
                let asset = AVURLAsset(url: url)
                let composition = try await VideoRenderer.composition(asset: asset, project: snapshot)
                guard !Task.isCancelled, revision == expectedRevision else { return }
                let time = currentTime
                let item = AVPlayerItem(asset: asset)
                item.videoComposition = composition
                player.replaceCurrentItem(with: item)
                player.isMuted = snapshot.muted
                player.seek(to: CMTime(seconds: time, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: { _ in })
                if isPlaying { player.play() }
            } catch { if !Task.isCancelled { message = error.localizedDescription } }
        }
    }

    func togglePlayback() {
        guard sourceURL != nil else { return }
        if isPlaying { player.pause() } else {
            if currentTime < project.trimStart || currentTime >= project.trimEnd { seek(project.trimStart) }
            player.play()
        }
        isPlaying.toggle()
    }

    func seek(_ time: Double) {
        currentTime = min(project.duration, max(0, time))
        player.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func addZoom() {
        guard sourceURL != nil, project.outputDuration >= 0.3 else { return }
        let start = min(max(project.trimStart, currentTime), max(project.trimStart, project.trimEnd - 0.3))
        let z = ZoomRegion(start: start, end: min(project.trimEnd, start + 2.5))
        project.zooms.append(z); selectedZoom = z.id
    }

    func saveProject(asNew: Bool = false) {
        guard !isLoading, let source = sourceURL else { return }
        var folder = projectFolder
        if folder == nil || asNew {
            let panel = NSSavePanel(); panel.title = "FrameCraft-Projekt speichern"
            panel.nameFieldStringValue = project.title + ".framecraft"
            panel.canCreateDirectories = true
            guard panel.runModal() == .OK, let url = panel.url else { return }
            folder = url.pathExtension == "framecraft" ? url : url.appendingPathExtension("framecraft")
        }
        guard let folder else { return }
        let snapshot = project
        isLoading = true; isSaving = true
        Task {
            defer { isLoading = false; isSaving = false }
            do {
                let media = try await ProjectPersistence.shared.save(project: snapshot, source: source, folder: folder)
                guard sourceURL == source else { return }
                sourceURL = media; projectFolder = folder; saved = project == snapshot
            } catch { message = StorageFailure.message(for: error) }
        }
    }

    func openProject() {
        guard !isLoading else { return }
        guard confirmReplace() else { return }
        let panel = NSOpenPanel(); panel.title = "FrameCraft-Projekt öffnen"
        panel.canChooseDirectories = true; panel.canChooseFiles = false
        guard panel.runModal() == .OK, let folder = panel.url else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let file = try await ProjectPersistence.shared.read(folder: folder)
                guard file.project.version == 1, file.mediaFilename == URL(fileURLWithPath: file.mediaFilename).lastPathComponent else { throw StudioError.invalidProject }
                let media = folder.appendingPathComponent(file.mediaFilename)
                let actual = try await AVURLAsset(url: media).load(.duration).seconds
                guard actual.isFinite, actual > 0, file.project.duration.isFinite, abs(file.project.duration - actual) < 0.1, file.project.trimStart >= 0,
                      file.project.trimEnd <= actual + 0.1, file.project.trimEnd > file.project.trimStart,
                      file.project.padding.isFinite, (0...0.25).contains(file.project.padding),
                      file.project.cornerRadius.isFinite, (0...100).contains(file.project.cornerRadius),
                      file.project.zooms.allSatisfy({ $0.start.isFinite && $0.end.isFinite && $0.start >= 0 && $0.end > $0.start && $0.end <= actual + 0.1 && (1...4).contains($0.scale) && (0...1).contains($0.x) && (0...1).contains($0.y) }) else { throw StudioError.invalidProject }
                if let cursor = file.project.cursor {
                    guard (0...0.3).contains(cursor.smoothing), (0.5...3).contains(cursor.size),
                          cursor.samples.count <= 4_000_000,
                          cursor.samples.allSatisfy({ $0.time.isFinite && (0...actual + 0.1).contains($0.time) && (0...1).contains($0.x) && (0...1).contains($0.y) }),
                          zip(cursor.samples, cursor.samples.dropFirst()).allSatisfy({ $0.time < $1.time }) else { throw StudioError.invalidProject }
                }
                let videoTracks = try await AVURLAsset(url: media).loadTracks(withMediaType: .video)
                guard !videoTracks.isEmpty, file.project.clicks.allSatisfy({ $0.time.isFinite && (0...actual).contains($0.time) && (0...1).contains($0.x) && (0...1).contains($0.y) }) else { throw StudioError.invalidProject }
                player.pause(); isPlaying = false
                project = file.project; sourceURL = media; projectFolder = folder
                currentTime = project.trimStart; selectedZoom = nil
                refreshPreview(); saved = true
            } catch { message = error.localizedDescription }
        }
    }

    func confirmReplace() -> Bool {
        guard sourceURL != nil, !saved else { return true }
        let alert = NSAlert(); alert.messageText = "Aktuelles Projekt verlassen?"
        alert.informativeText = "Nicht gespeicherte Bearbeitungen gehen verloren. Die Videoaufnahme bleibt erhalten."
        alert.addButton(withTitle: "Abbrechen"); alert.addButton(withTitle: "Verlassen")
        return alert.runModal() == .alertSecondButtonReturn
    }

    func recordingsFolder() throws -> URL {
        let folder = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Movies/FrameCraft", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}

enum StudioError: LocalizedError {
    case invalidVideo, invalidProject, existingMedia
    var errorDescription: String? {
        switch self {
        case .invalidVideo: return "Diese Datei enthält kein lesbares Video."
        case .invalidProject: return "Das Projekt ist unvollständig oder enthält ungültige Einstellungen."
        case .existingMedia: return "Im Zielordner liegt bereits ein anderes Originalvideo. Bitte einen neuen Projektnamen wählen."
        }
    }
}
