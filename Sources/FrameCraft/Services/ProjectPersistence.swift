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
        let manager = FileManager.default
        let media = folder.appendingPathComponent("source.\(source.pathExtension.lowercased())")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let file = SavedProject(project: project, mediaFilename: media.lastPathComponent)
        let sameMedia = source.resolvingSymlinksInPath().standardizedFileURL == media.resolvingSymlinksInPath().standardizedFileURL
        if sameMedia {
            guard manager.fileExists(atPath: media.path) else { throw StudioError.invalidProject }
            // An atomic metadata write preserves the last saved project if the disk fills.
            try writeMetadata(encoder.encode(file), folder.appendingPathComponent("project.json"))
            return media
        }
        guard !manager.fileExists(atPath: folder.path) else { throw StudioError.existingMedia }
        let staging = folder.deletingLastPathComponent().appendingPathComponent(".framecraft-project-\(UUID().uuidString)", isDirectory: true)
        try manager.createDirectory(at: staging, withIntermediateDirectories: false)
        defer { try? manager.removeItem(at: staging) }
        try manager.copyItem(at: source, to: staging.appendingPathComponent(media.lastPathComponent))
        try writeMetadata(encoder.encode(file), staging.appendingPathComponent("project.json"))
        // Publish only a complete project. A destination created during the copy wins.
        try manager.moveItem(at: staging, to: folder)
        return media
    }

    func read(folder: URL) throws -> SavedProject {
        try JSONDecoder().decode(SavedProject.self, from: Data(contentsOf: folder.appendingPathComponent("project.json")))
    }
}
