import AppKit
import AVFoundation
import UniformTypeIdentifiers

extension StudioStore {
    private func initialList() throws -> CutList {
        if let cuts = project.cuts { return cuts }
        guard let url = sourceURL else { throw StudioError.invalidVideo }
        var original = project
        original.muted = false // The existing mute switch now controls the whole timeline.
        let source = CutSource(project: original, ext: url.pathExtension.lowercased(), url: url)
        return CutList(sources: [source], segments: [CutSegment(sourceID: source.id, start: original.trimStart, end: original.trimEnd)])
    }

    func appendClips() {
        guard !isLoading, sourceURL != nil else { return }
        let panel = NSOpenPanel()
        panel.title = "Videos oder FrameCraft-Einzelprojekte hinzufügen"
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        let urls = panel.urls
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                var list = try initialList()
                let firstNew = list.duration
                for url in urls {
                    let isFolder = try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true
                    let source: CutSource
                    if isFolder {
                        let file = try await ProjectPersistence.shared.read(folder: url)
                        guard file.project.cuts == nil, file.mediaFilename == URL(fileURLWithPath: file.mediaFilename).lastPathComponent else {
                            throw StudioError.invalidProject
                        }
                        let media = url.appendingPathComponent(file.mediaFilename)
                        try await Self.validateSource(file.project, media: media)
                        source = CutSource(project: file.project, ext: media.pathExtension.lowercased(), url: media)
                    } else {
                        let asset = AVURLAsset(url: url)
                        let duration = try await asset.load(.duration).seconds
                        guard duration.isFinite, duration > 0,
                              !(try await asset.loadTracks(withMediaType: .video)).isEmpty else { throw StudioError.invalidVideo }
                        source = CutSource(project: Project(title: url.deletingPathExtension().lastPathComponent,
                            duration: duration, trimEnd: duration), ext: url.pathExtension.lowercased(), url: url)
                    }
                    list.sources.append(source)
                    list.segments.append(CutSegment(sourceID: source.id, start: source.project.trimStart, end: source.project.trimEnd))
                }
                try applyCuts(list, at: firstNew)
            } catch { message = error.localizedDescription }
        }
    }

    func splitClip() {
        do {
            var list = try initialList()
            let position = currentTime - (project.cuts == nil ? project.trimStart : 0)
            guard let i = list.index(at: position) else { return }
            let old = list.segments[i]
            let offset = position - list.start(of: i)
            guard offset >= 1.0 / 30, old.duration - offset >= 1.0 / 30 else {
                message = "Setze die Abspielposition mindestens ein Bild von der Schnittkante entfernt."
                return
            }
            let cut = old.start + offset
            list.segments[i].end = cut
            list.segments.insert(CutSegment(sourceID: old.sourceID, start: cut, end: old.end), at: i + 1)
            try applyCuts(list, at: position, selected: list.segments[i + 1].id)
        } catch { message = error.localizedDescription }
    }

    func changeSegment(move: Int?) {
        guard var list = project.cuts, let i = list.segments.firstIndex(where: { $0.id == selectedSegment }) else { return }
        let target: Int
        if let move {
            target = i + move
            guard list.segments.indices.contains(target) else { return }
            list.segments.swapAt(i, target)
        } else {
            guard list.segments.count > 1 else { return }
            list.segments.remove(at: i)
            target = min(i, list.segments.count - 1)
        }
        do { try applyCuts(list, at: list.start(of: target), selected: list.segments[target].id) }
        catch { message = error.localizedDescription }
    }

    private func applyCuts(_ list: CutList, at time: Double, selected: UUID? = nil) throws {
        try list.validate()
        rememberEdit()
        player.pause(); isPlaying = false
        var next = project
        next.cuts = list
        next.duration = list.duration
        next.trimStart = 0; next.trimEnd = list.duration
        next.zooms = []; next.clicks = []; next.cursor = nil; next.webcam = nil
        next.captions = nil; next.captionStyle = nil
        next.version = next.requiredVersion
        project = next
        selectedSegment = selected ?? list.index(at: time).map { list.segments[$0].id }
        selectedZoom = nil
        seek(time)
    }

    func rememberEdit() {
        cutHistory.append(EditSnapshot(project: project, position: currentTime, selection: selectedSegment))
        if cutHistory.count > 40 { cutHistory.removeFirst() }
    }

    func undoEdit() {
        guard let previous = cutHistory.popLast() else { return }
        player.pause(); isPlaying = false
        var restored = previous.project
        restored.format = project.format
        restored.backdrop = project.backdrop
        restored.padding = project.padding
        restored.cornerRadius = project.cornerRadius
        restored.title = project.title
        restored.muted = project.muted
        project = restored
        selectedSegment = previous.selection
        selectedZoom = nil
        seek(previous.position)
    }
}
