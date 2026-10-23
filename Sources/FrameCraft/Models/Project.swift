import Foundation
import CoreGraphics

struct ZoomRegion: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var start: Double
    var end: Double
    var scale: Double = 1.8
    var x: Double = 0.5
    var y: Double = 0.5 // top-down normalized source coordinate
    var automatic: Bool = false

    func strength(at time: Double) -> Double {
        guard end > start, time >= start, time <= end else { return 0 }
        let ramp = min(0.45, (end - start) / 2)
        let t = min(1, min((time - start) / ramp, (end - time) / ramp))
        return t * t * (3 - 2 * t)
    }
}

struct ClickSample: Codable, Equatable, Sendable {
    var time: Double
    var x: Double
    var y: Double
}

enum CanvasFormat: String, CaseIterable, Codable, Identifiable, Sendable {
    case landscape, portrait, square
    var id: String { rawValue }
    var title: String { switch self { case .landscape: return "16:9"; case .portrait: return "9:16"; case .square: return "1:1" } }
    var size: CGSize { switch self { case .landscape: return CGSize(width: 1920, height: 1080); case .portrait: return CGSize(width: 1080, height: 1920); case .square: return CGSize(width: 1080, height: 1080) } }
}

enum Backdrop: String, CaseIterable, Codable, Identifiable, Sendable {
    case aurora, dusk, ocean, graphite
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var rgb: ((Double, Double, Double), (Double, Double, Double)) {
        switch self {
        case .aurora: return ((0.19, 0.12, 0.39), (0.75, 0.40, 0.61))
        case .dusk: return ((0.22, 0.12, 0.26), (0.94, 0.57, 0.32))
        case .ocean: return ((0.04, 0.20, 0.32), (0.22, 0.64, 0.65))
        case .graphite: return ((0.11, 0.12, 0.15), (0.30, 0.32, 0.37))
        }
    }
}

struct Project: Codable, Equatable, Sendable {
    var version = 1
    var title: String = "Unbenannte Aufnahme"
    var duration: Double = 0
    var trimStart: Double = 0
    var trimEnd: Double = 0
    var format: CanvasFormat = .landscape
    var backdrop: Backdrop = .aurora
    var padding: Double = 0.075 // fraction of canvas short side
    var cornerRadius: Double = 20 // output pixels
    var muted: Bool = false
    var zooms: [ZoomRegion] = []
    var clicks: [ClickSample] = []
    var cursor: CursorTrack? = nil
    var outputDuration: Double { max(0, trimEnd - trimStart) }

    func zoom(at time: Double) -> (scale: Double, x: Double, y: Double) {
        CameraPath(project: self).zoom(at: time)
    }

    mutating func generateZooms() {
        zooms.removeAll { $0.automatic }
        var generated: [ZoomRegion] = []
        for click in clicks.sorted(by: { $0.time < $1.time }) where click.time >= trimStart && click.time < trimEnd {
            let start = max(trimStart, click.time - 0.45)
            let end = min(trimEnd, click.time + 1.65)
            guard end - start >= 0.3 else { continue }
            if let last = generated.last,
               click.time < last.end - 0.25,
               hypot(click.x - last.x, click.y - last.y) < 0.18 {
                generated[generated.count - 1].end = end
            } else {
                generated.append(ZoomRegion(start: start, end: end, x: click.x, y: click.y, automatic: true))
            }
        }
        zooms += generated
    }
}
