import Foundation

struct Caption: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var start: Double
    var end: Double
    var text: String
}

enum CaptionStyle: String, CaseIterable, Codable, Sendable {
    case standard, large, top
    var title: String {
        switch self {
        case .standard: return "Unten"
        case .large: return "Unten · groß"
        case .top: return "Oben"
        }
    }
}

extension Project {
    var validCaptions: Bool {
        let cues = captions ?? []
        return Set(cues.map(\.id)).count == cues.count && cues.allSatisfy {
            $0.start.isFinite && $0.end.isFinite && $0.start >= 0 && $0.end <= duration &&
            $0.start < $0.end && !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.text.count <= 300
        } && zip(cues, cues.dropFirst()).allSatisfy { $0.end <= $1.start }
    }
}
