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
    static func composition(asset: AVAsset, project: Project) async throws -> AVVideoComposition {
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw RenderError.missingVideo
        }
        _ = try await asset.load(.duration)
        let (naturalSize, preferredTransform) = try await track.load(.naturalSize, .preferredTransform)
        let displayBounds = CGRect(origin: .zero, size: naturalSize).applying(preferredTransform)
        let sourceBounds = CGRect(origin: .zero,
                                  size: CGSize(width: abs(displayBounds.width), height: abs(displayBounds.height)))
        let canvas = CGRect(origin: .zero, size: project.format.size)
        let background = backdrop(project.backdrop, bounds: canvas)
        let cursorSamples = project.cursor?.prepared(clicks: project.clicks) ?? []
        let camera = CameraPath(project: project)
        let pointer = pointerImage()
        let context = CIContext(options: [.cacheIntermediates: false])
        // Preloading above avoids synchronous metadata I/O in this compatibility initializer.
        let result = AVMutableVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
            // AVFoundation applies the track's preferred transform before this callback.
            // Keep the original display bounds independent of the chosen output canvas.
            let source = cursorOverlay(source: request.sourceImage.cropped(to: sourceBounds),
                                       project: project, samples: cursorSamples, pointer: pointer,
                                       time: request.compositionTime.seconds)
            let image = render(source: source, project: project,
                               zoom: camera.zoom(at: request.compositionTime.seconds),
                               canvas: canvas, background: background)
            request.finish(with: image, context: context)
        })
        result.renderSize = canvas.size
        result.frameDuration = CMTime(value: 1, timescale: 30)
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

        let shadowMask = mask.transformed(by: CGAffineTransform(translationX: 0, y: -10))
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 18])
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

@MainActor
final class ExportService: ObservableObject {
    @Published private(set) var isExporting = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var errorMessage: String?
    private var activeTask: Task<Void, Error>?
    private var cancelled = false

    func clearError() { errorMessage = nil }

    func cancel() {
        cancelled = true
        activeTask?.cancel()
    }

    func export(source: URL, project: Project, destination: URL) async -> Bool {
        guard !isExporting else { return false }
        isExporting = true
        progress = 0
        errorMessage = nil
        cancelled = false
        let temporary = destination.deletingLastPathComponent()
            .appendingPathComponent(".framecraft-\(UUID().uuidString).mp4")
        var progressTask: Task<Void, Never>?
        defer {
            progressTask?.cancel()
            activeTask = nil
            isExporting = false
            try? FileManager.default.removeItem(at: temporary)
        }
        do {
            guard source.resolvingSymlinksInPath().standardizedFileURL != destination.resolvingSymlinksInPath().standardizedFileURL,
                  !FileManager.default.fileExists(atPath: destination.path) else {
                throw RenderError.destinationExists
            }
            let asset = AVURLAsset(url: source)
            let duration = try await asset.load(.duration).seconds
            let start = max(0, project.trimStart)
            let end = min(duration, project.trimEnd)
            guard duration.isFinite, start.isFinite, end.isFinite, end > start else {
                throw RenderError.invalidDuration
            }
            let composition = try await VideoRenderer.composition(asset: asset, project: project)
            guard !cancelled else { throw CancellationError() }
            try Task.checkCancellation()
            guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
                throw RenderError.exportUnavailable
            }
            session.shouldOptimizeForNetworkUse = true
            session.videoComposition = composition
            session.timeRange = CMTimeRange(start: CMTime(seconds: start, preferredTimescale: 600),
                                           end: CMTime(seconds: end, preferredTimescale: 600))
            if project.muted {
                let tracks = try await asset.loadTracks(withMediaType: .audio)
                let mix = AVMutableAudioMix()
                mix.inputParameters = tracks.map { track in
                    let parameters = AVMutableAudioMixInputParameters(track: track)
                    parameters.setVolume(0, at: .zero)
                    return parameters
                }
                session.audioMix = mix
            }
            guard !cancelled else { throw CancellationError() }
            progressTask = Task { [weak self] in
                for await state in session.states(updateInterval: 0.1) {
                    guard !Task.isCancelled, let self else { return }
                    if case .exporting(let value) = state {
                        self.progress = min(1, max(0, value.fractionCompleted))
                    }
                }
            }
            let operation = Task { try await session.export(to: temporary, as: .mp4) }
            activeTask = operation
            try await withTaskCancellationHandler {
                try await operation.value
            } onCancel: {
                operation.cancel()
            }
            guard !cancelled else { throw CancellationError() }
            try Task.checkCancellation()
            // moveItem refuses to overwrite an existing file, including one created during export.
            try FileManager.default.moveItem(at: temporary, to: destination)
            progress = 1
            return true
        } catch is CancellationError {
            errorMessage = nil
            return false
        } catch {
            // Framework cancellation may arrive as an NSError, not CancellationError.
            errorMessage = cancelled || Task.isCancelled ? nil : StorageFailure.message(for: error)
            return false
        }
    }
}
