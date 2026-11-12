import Foundation

struct WebcamOverlay: Codable, Equatable, Sendable {
    enum Corner: String, Codable, CaseIterable, Sendable {
        case topLeft, topRight, bottomLeft, bottomRight
        var title: String {
            switch self {
            case .topLeft: return "Oben links"
            case .topRight: return "Oben rechts"
            case .bottomLeft: return "Unten links"
            case .bottomRight: return "Unten rechts"
            }
        }
    }
    var startOffset: Double
    var enabled = true
    var corner = Corner.bottomRight
    var size = 0.24

    static func movie(for source: URL) -> URL {
        source.deletingPathExtension().appendingPathExtension("webcam.mov")
    }
}
