import Foundation

/// Times refer to the original movie. Editing the list never changes source media.
struct CutSegment: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    let sourceID: UUID
    var start: Double
    var end: Double
    var duration: Double { end - start }
}

struct CutSource: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var project: Project
    let ext: String
    // Rebuilt from the enclosing package on open. Never serialize an absolute path.
    var url: URL? = nil
    enum CodingKeys: String, CodingKey { case id, project, ext }
}

struct CutList: Codable, Equatable, Sendable {
    var sources: [CutSource]
    var segments: [CutSegment]
    var duration: Double { segments.reduce(0) { $0 + $1.duration } }

    func start(of index: Int) -> Double {
        segments.prefix(index).reduce(0) { $0 + $1.duration }
    }

    func index(at time: Double) -> Int? {
        var end = 0.0
        for (index, segment) in segments.enumerated() {
            end += segment.duration
            if time < end { return index }
        }
        return segments.indices.last
    }

    func validate() throws {
        let ids = Set(sources.map(\.id))
        guard !sources.isEmpty, !segments.isEmpty, ids.count == sources.count,
              Set(segments.map(\.id)).count == segments.count,
              sources.allSatisfy({ $0.project.cuts == nil && !$0.ext.isEmpty && $0.ext.count <= 16 &&
                  $0.ext.utf8.allSatisfy { (48...57).contains($0) || (97...122).contains($0) } }) else {
            throw StudioError.invalidProject
        }
        let durations = Dictionary(uniqueKeysWithValues: sources.map { ($0.id, $0.project.duration) })
        guard segments.allSatisfy({ s in
            guard let length = durations[s.sourceID] else { return false }
            return s.start.isFinite && s.end.isFinite && s.start >= 0 && s.end <= length &&
                s.duration >= 1.0 / 60000
        }), duration.isFinite else { throw StudioError.invalidProject }
    }

    func media(in folder: URL, at index: Int) -> URL {
        let source = sources[index]
        let name = index == 0 ? "source" : source.id.uuidString
        return folder.appendingPathComponent(name).appendingPathExtension(source.ext)
    }
}
