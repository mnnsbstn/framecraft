import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins

enum WebcamComposition {
    static let screenID: CMPersistentTrackID = 1
    static let cameraID: CMPersistentTrackID = 2

    static func asset(source: URL, project: Project) async throws -> AVAsset {
        let screen = AVURLAsset(url: source)
        guard let overlay = project.webcam, overlay.enabled else { return screen }
        let camera = AVURLAsset(url: WebcamOverlay.movie(for: source))
        guard let screenTrack = try await screen.loadTracks(withMediaType: .video).first,
              let cameraTrack = try await camera.loadTracks(withMediaType: .video).first else { throw RenderError.missingVideo }
        let duration = try await screen.load(.duration)
        let clip = try await cameraTrack.load(.timeRange)
        let offset = CMTime(seconds: overlay.startOffset, preferredTimescale: 60000)
        let start = CMTimeMaximum(.zero, offset)
        let skip = CMTimeMaximum(.zero, .zero - offset)
        let length = CMTimeMinimum(clip.duration - skip, duration - start)
        guard length > .zero else { return screen }
        let combined = AVMutableComposition()
        func add(_ type: AVMediaType, _ id: CMPersistentTrackID) throws -> AVMutableCompositionTrack {
            guard let track = combined.addMutableTrack(withMediaType: type, preferredTrackID: id) else { throw RenderError.exportUnavailable }
            return track
        }
        let primary = try add(.video, screenID)
        let range = CMTimeRange(start: .zero, duration: duration)
        primary.preferredTransform = try await screenTrack.load(.preferredTransform)
        try primary.insertTimeRange(range, of: screenTrack, at: .zero)
        let inset = try add(.video, cameraID)
        inset.preferredTransform = try await cameraTrack.load(.preferredTransform)
        try inset.insertTimeRange(CMTimeRange(start: clip.start + skip, duration: length), of: cameraTrack, at: start)
        for audio in try await screen.loadTracks(withMediaType: .audio) {
            let track = try add(.audio, kCMPersistentTrackID_Invalid)
            let audioRange = CMTimeRangeGetIntersection(try await audio.load(.timeRange), otherRange: range)
            if audioRange.duration > .zero { try track.insertTimeRange(audioRange, of: audio, at: audioRange.start) }
        }
        return combined
    }

    static func overlay(_ frame: CIImage, on screen: CIImage, settings: WebcamOverlay, canvas: CGRect) -> CIImage {
        let side = min(canvas.width, canvas.height)
        let diameter = side * settings.size, margin = side * 0.035
        let left = settings.corner == .topLeft || settings.corner == .bottomLeft
        let top = settings.corner == .topLeft || settings.corner == .topRight
        let box = CGRect(x: left ? margin : canvas.maxX - margin - diameter,
                         y: top ? canvas.maxY - margin - diameter : margin, width: diameter, height: diameter)
        let scale = diameter / min(frame.extent.width, frame.extent.height)
        let scaled = frame.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let positioned = scaled.transformed(by: CGAffineTransform(translationX: box.midX - scaled.extent.midX,
                                                                   y: box.midY - scaled.extent.midY))
        let mask = CIFilter.roundedRectangleGenerator()
        mask.extent = box; mask.radius = Float(diameter / 2); mask.color = .white
        return positioned.cropped(to: box).applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: screen, kCIInputMaskImageKey: mask.outputImage!.cropped(to: canvas)
        ]).cropped(to: canvas)
    }
}

final class WebcamInstruction: NSObject, AVVideoCompositionInstructionProtocol, @unchecked Sendable {
    let timeRange: CMTimeRange
    let enablePostProcessing = false
    let containsTweening = true
    let passthroughTrackID = kCMPersistentTrackID_Invalid
    let requiredSourceTrackIDs: [NSValue]?
    let cameraActive: Bool
    let draw: (CIImage, CIImage?, Double) -> CIImage

    init(range: CMTimeRange, cameraActive: Bool, draw: @escaping (CIImage, CIImage?, Double) -> CIImage) {
        self.timeRange = range
        self.cameraActive = cameraActive
        self.draw = draw
        let ids = cameraActive ? [WebcamComposition.screenID, WebcamComposition.cameraID] : [WebcamComposition.screenID]
        self.requiredSourceTrackIDs = ids.map { NSNumber(value: $0) }
    }
}

final class WebcamCompositor: NSObject, AVVideoCompositing {
    let sourcePixelBufferAttributes: [String: any Sendable]? = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    let requiredPixelBufferAttributesForRenderContext: [String: any Sendable] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    private let context = CIContext(options: [.cacheIntermediates: false])

    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {}

    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        autoreleasepool {
            guard let instruction = request.videoCompositionInstruction as? WebcamInstruction,
                  let screen = request.sourceFrame(byTrackID: WebcamComposition.screenID),
                  let destination = request.renderContext.newPixelBuffer() else {
                request.finish(with: RenderError.missingVideo)
                return
            }
            let camera = instruction.cameraActive ? request.sourceFrame(byTrackID: WebcamComposition.cameraID) : nil
            let image = instruction.draw(CIImage(cvPixelBuffer: screen), camera.map { CIImage(cvPixelBuffer: $0) }, request.compositionTime.seconds)
            context.render(image, to: destination, bounds: image.extent, colorSpace: CGColorSpace(name: CGColorSpace.sRGB))
            request.finish(withComposedVideoFrame: destination)
        }
    }
}
