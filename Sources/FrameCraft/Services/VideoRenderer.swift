import AVFoundation
import Combine
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

enum RenderError: LocalizedError {
    case missingVideo, invalidDuration, destinationExists, exportUnavailable, failed(String)
    var errorDescription: String? {
        switch self {
        case .missingVideo: return "Die Datei enthält keine Videospur."
        case .invalidDuration: return "Der gewählte Ausschnitt ist leer oder ungültig."
        case .destinationExists: return "Die Zieldatei existiert bereits. Bitte wähle einen neuen Dateinamen."
        case .exportUnavailable: return "Der MP4-Export konnte nicht gestartet werden."
        case .failed(let message): return message
        }
    }
}

/// One Core Image pipeline is shared by the player and the exported file.
enum VideoRenderer {
    static func composition(asset: AVAsset, project: Project, outputSize: CGSize? = nil, fps: Int = 30) async throws -> AVVideoComposition {
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw RenderError.missingVideo
        }
        _ = try await asset.load(.duration)
        let (naturalSize, preferredTransform) = try await track.load(.naturalSize, .preferredTransform)
        let displayBounds = CGRect(origin: .zero, size: naturalSize).applying(preferredTransform)
        let sourceBounds = CGRect(origin: .zero,
                                  size: CGSize(width: abs(displayBounds.width), height: abs(displayBounds.height)))
        let canvas = CGRect(origin: .zero, size: outputSize ?? project.format.size)
        var scaledProject = project
        scaledProject.cornerRadius *= canvas.height / project.format.size.height
        let renderProject = scaledProject
        let background = backdrop(project.backdrop, bounds: canvas)
        let cursorSamples = project.cursor?.prepared(clicks: project.clicks) ?? []
        let camera = CameraPath(project: project)
        let pointer = pointerImage()
        let context = CIContext(options: [.cacheIntermediates: false])
        func drawScreen(_ frame: CIImage, at time: Double) -> CIImage {
            let source = cursorOverlay(source: frame.cropped(to: sourceBounds), project: project,
                                       samples: cursorSamples, pointer: pointer, time: time)
            return render(source: source, project: renderProject, zoom: camera.zoom(at: time),
                          canvas: canvas, background: background)
        }
        let result: AVMutableVideoComposition
        if let overlay = project.webcam, overlay.enabled, let combined = asset as? AVComposition,
           let inset = try await combined.loadTrack(withTrackID: WebcamComposition.cameraID) {
            let transform = try await inset.load(.preferredTransform)
            let segments = try await inset.load(.segments)
            guard let active = segments.first(where: { !$0.isEmpty })?.timeMapping.target else { throw RenderError.missingVideo }
            let duration = try await asset.load(.duration)
            func oriented(_ image: CIImage, _ transform: CGAffineTransform) -> CIImage {
                let rotated = image.transformed(by: transform)
                return rotated.transformed(by: CGAffineTransform(translationX: -rotated.extent.minX, y: -rotated.extent.minY))
            }
            let draw: (CIImage, CIImage?, Double) -> CIImage = { frame, webcam, time in
                let background = drawScreen(oriented(frame, preferredTransform), at: time)
                guard let webcam else { return background }
                return WebcamComposition.overlay(oriented(webcam, transform), on: background, settings: overlay, canvas: canvas)
            }
            let ranges: [(CMTime, CMTime, Bool)] = [(.zero, active.start, false), (active.start, active.end, true), (active.end, duration, false)]
            result = AVMutableVideoComposition()
            result.customVideoCompositorClass = WebcamCompositor.self
            result.instructions = ranges.compactMap { start, end, enabled in
                guard end > start else { return nil }
                return WebcamInstruction(range: CMTimeRange(start: start, end: end), cameraActive: enabled, draw: draw)
            }
        } else {
            result = AVMutableVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
                request.finish(with: drawScreen(request.sourceImage, at: request.compositionTime.seconds), context: context)
            })
        }
        result.renderSize = canvas.size
        result.frameDuration = CMTime(value: 1, timescale: Int32(fps))
        result.sourceTrackIDForFrameTiming = kCMPersistentTrackID_Invalid
        return result
    }

    private static func pointerImage() -> CIImage {
        let context = CGContext(data: nil, width: 48, height: 64, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(CGColor(gray: 0.08, alpha: 1))
        context.setStrokeColor(CGColor(gray: 1, alpha: 1))
        context.setLineWidth(2.5); context.setLineJoin(.round)
        context.move(to: CGPoint(x: 8, y: 60))
        for p in [CGPoint(x: 8, y: 17), CGPoint(x: 19, y: 28), CGPoint(x: 28, y: 7),
                  CGPoint(x: 36, y: 11), CGPoint(x: 26, y: 32), CGPoint(x: 42, y: 32)] { context.addLine(to: p) }
        context.closePath(); context.drawPath(using: .fillStroke)
        return CIImage(cgImage: context.makeImage()!)
    }

    private static func cursorOverlay(source: CIImage, project: Project, samples: [CursorSample], pointer: CIImage, time: Double) -> CIImage {
        guard let track = project.cursor, track.enabled,
              let position = CursorTrack.position(at: time, samples: samples) else { return source }
        let extent = source.extent
        let point = CGPoint(x: extent.minX + position.x * extent.width, y: extent.minY + (1 - position.y) * extent.height)
        var result = source
        if track.highlightClicks, let click = project.clicks.last(where: { $0.time <= time && time - $0.time < 0.35 }) {
            let progress = (time - click.time) / 0.35
            let pulse = CIFilter.radialGradient()
            pulse.center = CGPoint(x: extent.minX + click.x * extent.width, y: extent.minY + (1 - click.y) * extent.height)
            pulse.radius0 = Float(extent.height * (0.008 + progress * 0.014))
            pulse.radius1 = pulse.radius0 + 3
            pulse.color0 = CIColor(red: 0.72, green: 0.35, blue: 1, alpha: 0.45 * (1 - progress))
            pulse.color1 = .clear
            result = pulse.outputImage!.cropped(to: extent).composited(over: result)
        }
        let scale = max(18, extent.height * 0.035) * track.size / 53
        let transform = CGAffineTransform(a: scale, b: 0, c: 0, d: scale,
                                         tx: point.x - 8 * scale, ty: point.y - 60 * scale)
        return pointer.transformed(by: transform).composited(over: result).cropped(to: extent)
    }

    private static func backdrop(_ style: Backdrop, bounds: CGRect) -> CIImage {
        let (a, b) = style.rgb
        let filter = CIFilter.linearGradient()
        filter.point0 = CGPoint(x: bounds.minX, y: bounds.maxY)
        filter.point1 = CGPoint(x: bounds.maxX, y: bounds.minY)
        filter.color0 = CIColor(red: a.0, green: a.1, blue: a.2)
        filter.color1 = CIColor(red: b.0, green: b.1, blue: b.2)
        return filter.outputImage!.cropped(to: bounds)
    }

    private static func render(source: CIImage, project: Project, zoom: (scale: Double, x: Double, y: Double),
                               canvas: CGRect, background: CIImage) -> CIImage {
        let extent = source.extent
        guard extent.width > 0, extent.height > 0, !extent.isInfinite else { return background }
        let padding = min(0.30, max(0, project.padding)) * min(canvas.width, canvas.height)
        let available = canvas.insetBy(dx: padding, dy: padding)
        let fit = min(available.width / extent.width, available.height / extent.height)
        let panel = CGRect(x: (canvas.width - extent.width * fit) / 2,
                           y: (canvas.height - extent.height * fit) / 2,
                           width: extent.width * fit, height: extent.height * fit)
        let scale = max(1, min(4, zoom.scale))
        let cropSize = CGSize(width: extent.width / scale, height: extent.height / scale)
        // Project coordinates are top-down; Core Image coordinates are bottom-up.
        let focusX = extent.minX + min(1, max(0, zoom.x)) * extent.width
        let focusY = extent.minY + (1 - min(1, max(0, zoom.y))) * extent.height
        let crop = CGRect(x: min(extent.maxX - cropSize.width, max(extent.minX, focusX - cropSize.width / 2)),
                          y: min(extent.maxY - cropSize.height, max(extent.minY, focusY - cropSize.height / 2)),
                          width: cropSize.width, height: cropSize.height)
        let factor = panel.width / crop.width
        let transform = CGAffineTransform(a: factor, b: 0, c: 0, d: factor,
                                         tx: panel.minX - crop.minX * factor,
                                         ty: panel.minY - crop.minY * factor)
        let content = source.cropped(to: crop).transformed(by: transform).cropped(to: panel)
        let radius = min(max(0, project.cornerRadius), min(panel.width, panel.height) / 2)
        let maskFilter = CIFilter.roundedRectangleGenerator()
        maskFilter.extent = panel
        maskFilter.radius = Float(radius)
        maskFilter.color = CIColor.white
        let mask = maskFilter.outputImage!.cropped(to: canvas)
        let clear = CIImage(color: .clear).cropped(to: canvas)

        let outputScale = canvas.height / project.format.size.height
        let shadowMask = mask.transformed(by: CGAffineTransform(translationX: 0, y: -10 * outputScale))
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 18 * outputScale])
            .cropped(to: canvas)
        let shadow = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0.24))
            .cropped(to: canvas)
            .applyingFilter("CIBlendWithMask", parameters: [kCIInputBackgroundImageKey: clear,
                                                         kCIInputMaskImageKey: shadowMask])
        let base = shadow.composited(over: background)
        return content.applyingFilter("CIBlendWithMask", parameters: [kCIInputBackgroundImageKey: base,
                                                                    kCIInputMaskImageKey: mask])
            .cropped(to: canvas)
    }
}
