import Foundation

struct SavedProject: Codable, Sendable {
    let project: Project
    let mediaFilename: String
}

/// File copying and large JSON encoding run on this actor, never on the UI actor.
actor ProjectPersistence {
    static let shared = ProjectPersistence()
    private let writeMetadata: @Sendable (Data, URL) throws -> Void

    init(writeMetadata: @escaping @Sendable (Data, URL) throws -> Void = { data, url in
        try data.write(to: url, options: .atomic)
    }) {
        self.writeMetadata = writeMetadata
    }

    func save(project: Project, source: URL, folder: URL) throws -> URL {
        if let cuts = project.cuts { return try saveSequence(project, cuts: cuts, source: source, folder: folder) }
        let manager = FileManager.default
        let media = folder.appendingPathComponent("source.\(source.pathExtension.lowercased())")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let file = SavedProject(project: project, mediaFilename: media.lastPathComponent)
        let sameMedia = source.resolvingSymlinksInPath().standardizedFileURL == media.resolvingSymlinksInPath().standardizedFileURL
        if sameMedia {
            guard manager.fileExists(atPath: media.path), project.webcam == nil || manager.fileExists(atPath: WebcamOverlay.movie(for: media).path) else { throw StudioError.invalidProject }
            // An atomic metadata write preserves the last saved project if the disk fills.
            try writeMetadata(encoder.encode(file), folder.appendingPathComponent("project.json"))
            return media
        }
        guard !manager.fileExists(atPath: folder.path) else { throw StudioError.existingMedia }
        let staging = folder.deletingLastPathComponent().appendingPathComponent(".framecraft-project-\(UUID().uuidString)", isDirectory: true)
        try manager.createDirectory(at: staging, withIntermediateDirectories: false)
        defer { try? manager.removeItem(at: staging) }
        try manager.copyItem(at: source, to: staging.appendingPathComponent(media.lastPathComponent))
        if project.webcam != nil {
            try manager.copyItem(at: WebcamOverlay.movie(for: source),
                                 to: WebcamOverlay.movie(for: staging.appendingPathComponent(media.lastPathComponent)))
        }
        try writeMetadata(encoder.encode(file), staging.appendingPathComponent("project.json"))
        // Publish only a complete project. A destination created during the copy wins.
        try manager.moveItem(at: staging, to: folder)
        return media
    }

    private func saveSequence(_ project: Project, cuts: CutList, source: URL, folder: URL) throws -> URL {
        try cuts.validate()
        let manager = FileManager.default
        let primary = cuts.media(in: folder, at: 0)
        let inPlace = primary.standardizedFileURL == source.standardizedFileURL
        guard inPlace || !manager.fileExists(atPath: folder.path) else { throw StudioError.existingMedia }
        let staging = folder.deletingLastPathComponent().appendingPathComponent(".framecraft-\(UUID().uuidString)")
        try manager.createDirectory(at: staging, withIntermediateDirectories: false)
        defer { try? manager.removeItem(at: staging) }
        var added: [URL] = []
        do {
            for index in cuts.sources.indices {
                let clip = cuts.sources[index]
                guard let original = clip.url else { throw StudioError.invalidProject }
                let target = cuts.media(in: folder, at: index)
                var pairs = [(original, target)]
                if clip.project.webcam != nil {
                    pairs.append((WebcamOverlay.movie(for: original), WebcamOverlay.movie(for: target)))
                }
                for (from, to) in pairs {
                    guard manager.fileExists(atPath: from.path) else { throw StudioError.invalidProject }
                    if inPlace && from.standardizedFileURL == to.standardizedFileURL { continue }
                    let temporary = staging.appendingPathComponent(to.lastPathComponent)
                    try manager.copyItem(at: from.resolvingSymlinksInPath(), to: temporary)
                    if inPlace {
                        try manager.moveItem(at: temporary, to: to)
                        added.append(to)
                    }
                }
            }
            let metadata = SavedProject(project: project, mediaFilename: primary.lastPathComponent)
            let data = try JSONEncoder().encode(metadata)
            try writeMetadata(data, (inPlace ? folder : staging).appendingPathComponent("project.json"))
            if !inPlace { try manager.moveItem(at: staging, to: folder) }
            return primary
        } catch {
            for url in added { try? manager.removeItem(at: url) }
            throw error
        }
    }

    func read(folder: URL) throws -> SavedProject {
        try JSONDecoder().decode(SavedProject.self, from: Data(contentsOf: folder.appendingPathComponent("project.json")))
    }
}
