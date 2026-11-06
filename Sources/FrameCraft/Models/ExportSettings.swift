import Foundation
import CoreGraphics

struct ExportSettings: Equatable, Sendable {
    enum Format: String, CaseIterable, Identifiable, Sendable {
        case mp4, gif
        var id: String { rawValue }
        var title: String { rawValue.uppercased() }
    }
    enum Resolution: Int, CaseIterable, Identifiable, Sendable {
        case hd = 720, fullHD = 1080, ultraHD = 2160
        var id: Int { rawValue }
        var title: String { switch self { case .hd: "HD · 720p"; case .fullHD: "Full HD · 1080p"; case .ultraHD: "4K · 2160p" } }
    }
    enum Quality: String, CaseIterable, Identifiable, Sendable {
        case compact, balanced, high
        var id: String { rawValue }
        var title: String { switch self { case .compact: "Kompakt"; case .balanced: "Ausgewogen"; case .high: "Hoch" } }
        var bitsPerPixel: Double { switch self { case .compact: 0.04; case .balanced: 0.08; case .high: 0.14 } }
    }
    var format: Format = .mp4
    var resolution: Resolution = .fullHD
    var fps = 30
    var quality: Quality = .high
    var gifLongEdge = 480
    var gifFPS = 10

    var fileExtension: String { format.rawValue }
    var frameRate: Int { format == .gif ? gifFPS : fps }
    func size(for canvas: CanvasFormat) -> CGSize {
        let base = canvas.size
        let scale = format == .gif ? Double(gifLongEdge) / max(base.width, base.height) : Double(resolution.rawValue) / 1080
        return CGSize(width: max(2, Int(base.width * scale) / 2 * 2), height: max(2, Int(base.height * scale) / 2 * 2))
    }
    func bitRate(for canvas: CanvasFormat) -> Int {
        let size = size(for: canvas)
        return Int(min(80_000_000, max(500_000, size.width * size.height * Double(fps) * quality.bitsPerPixel)))
    }
    func estimatedBytes(duration: Double, canvas: CanvasFormat) -> Int64? {
        guard format == .mp4, duration.isFinite, duration > 0, duration < 1_000_000 else { return nil }
        return Int64(Double(bitRate(for: canvas) + 192_000) * duration / 8)
    }
    func validationMessage(duration: Double) -> String? {
        guard duration.isFinite, duration > 0 else { return "Der gewählte Ausschnitt ist leer oder ungültig." }
        if format == .gif {
            guard [480, 720].contains(gifLongEdge), [10, 20].contains(gifFPS) else { return "Ungültige GIF-Einstellungen." }
            if duration > 10.0001 { return "GIF ist auf 10 Sekunden begrenzt. Kürze den Ausschnitt unter „Zoom & Schnitt“ oder wähle MP4." }
        } else if ![24, 30, 60].contains(fps) { return "Wähle 24, 30 oder 60 Bilder pro Sekunde." }
        return nil
    }
}
