import AVFoundation
import CoreImage

struct EditedMovie {
    let asset: AVAsset
    let composition: AVVideoComposition

    static func prepare(source: URL, project: Project, size: CGSize? = nil, fps: Int = 30) async throws -> Self {
        guard let cuts = project.cuts else {
            let asset = try await WebcamComposition.asset(source: source, project: project)
            return try await Self(asset: asset, composition: VideoRenderer.composition(asset: asset, project: project, outputSize: size, fps: fps))
        }
        try cuts.validate()
        let canvas = CGRect(origin: .zero, size: size ?? project.format.size)
        let asset = AVMutableComposition()
        func track(_ type: AVMediaType, _ id: CMPersistentTrackID) throws -> AVMutableCompositionTrack {
            guard let track = asset.addMutableTrack(withMediaType: type, preferredTrackID: id) else { throw RenderError.exportUnavailable }
            return track
        }
        let video = try track(.video, WebcamComposition.screenID)
        var camera: AVMutableCompositionTrack?
        var audio: [AVMutableCompositionTrack] = []
        var instructions: [WebcamInstruction] = []
        var position = CMTime.zero
        var inputs: [UUID: Input] = [:]
        for clip in cuts.segments {
            try Task.checkCancellation()
            if inputs[clip.sourceID] == nil {
                guard let source = cuts.sources.first(where: { $0.id == clip.sourceID }) else { throw StudioError.invalidProject }
                inputs[clip.sourceID] = try await Input(source, canvas: canvas, style: project)
            }
            guard let input = inputs[clip.sourceID] else { throw StudioError.invalidProject }
            let range = CMTimeRange(start: time(clip.start), end: time(clip.end))
            let start = position, end = start + range.duration
            let videoRange = CMTimeRangeGetIntersection(input.videoRange, otherRange: range)
            if videoRange.duration > .zero {
                try video.insertTimeRange(videoRange, of: input.video, at: start + (videoRange.start - range.start))
            }
            for (i, lane) in input.audio.enumerated() {
                let overlap = CMTimeRangeGetIntersection(lane.range, otherRange: range)
                guard overlap.duration > .zero else { continue }
                while audio.count <= i { audio.append(try track(.audio, CMPersistentTrackID(3 + audio.count))) }
                try audio[i].insertTimeRange(overlap, of: lane.track, at: start + (overlap.start - range.start))
            }
            var cameraStart = end, cameraEnd = end
            if let inset = input.inset {
                let sourceRange = CMTimeRange(start: inset.offset, duration: inset.range.duration)
                let overlap = CMTimeRangeGetIntersection(range, otherRange: sourceRange)
                if overlap.duration > .zero {
                    if camera == nil { camera = try track(.video, WebcamComposition.cameraID) }
                    cameraStart = start + (overlap.start - range.start)
                    cameraEnd = cameraStart + overlap.duration
                    let movieRange = CMTimeRange(start: inset.range.start + (overlap.start - inset.offset), duration: overlap.duration)
                    try camera?.insertTimeRange(movieRange, of: inset.track, at: cameraStart)
                }
            }
            let delta = range.start.seconds - start.seconds
            for (lo, hi, active) in [(start, cameraStart, false), (cameraStart, cameraEnd, true), (cameraEnd, end, false)] where hi > lo {
                instructions.append(WebcamInstruction(range: CMTimeRange(start: lo, end: hi), cameraActive: active) { frame, face, t in
                    input.draw(frame, face, t + delta)
                })
            }
            position = end
        }
        let filled = try await asset.load(.duration)
        if filled < position { asset.insertEmptyTimeRange(CMTimeRange(start: filled, end: position)) }
        let composition = AVMutableVideoComposition()
        composition.customVideoCompositorClass = WebcamCompositor.self
        composition.instructions = instructions
        composition.frameDuration = CMTime(value: 1, timescale: Int32(fps))
        composition.renderSize = canvas.size
        return Self(asset: asset, composition: composition)
    }

    private static func time(_ seconds: Double) -> CMTime { CMTime(seconds: seconds, preferredTimescale: 60000) }

    private struct Input {
        let video: AVAssetTrack
        let videoRange: CMTimeRange
        var audio: [(track: AVAssetTrack, range: CMTimeRange)] = []
        var inset: (track: AVAssetTrack, range: CMTimeRange, offset: CMTime)?
        let draw: (CIImage, CIImage?, Double) -> CIImage

        init(_ source: CutSource, canvas: CGRect, style: Project) async throws {
            guard let url = source.url else { throw StudioError.invalidProject }
            let original = AVURLAsset(url: url)
            guard let primary = try await original.loadTracks(withMediaType: .video).first else { throw RenderError.missingVideo }
            video = primary
            videoRange = try await primary.load(.timeRange)
            var settings = source.project
            settings.format = style.format
            settings.backdrop = style.backdrop
            settings.padding = style.padding
            settings.cornerRadius = style.cornerRadius
            for track in try await original.loadTracks(withMediaType: .audio) where !source.project.muted {
                audio.append((track, try await track.load(.timeRange)))
            }
            let (size, transform) = try await primary.load(.naturalSize, .preferredTransform)
            let bounds = CGRect(origin: .zero, size: CGRect(origin: .zero, size: size).applying(transform).size)
            let render = VideoRenderer.screenRenderer(project: settings, canvas: canvas, sourceBounds: bounds)
            let captions = CaptionRenderer(project: settings, canvas: canvas)
            let overlay = settings.webcam
            var cameraTransform = CGAffineTransform.identity
            if let overlay, overlay.enabled {
                let camera = AVURLAsset(url: WebcamOverlay.movie(for: url))
                guard let track = try await camera.loadTracks(withMediaType: .video).first else { throw RenderError.missingVideo }
                inset = (track, try await track.load(.timeRange), EditedMovie.time(overlay.startOffset))
                cameraTransform = try await track.load(.preferredTransform)
            }
            func orient(_ image: CIImage, _ transform: CGAffineTransform) -> CIImage {
                let rotated = image.transformed(by: transform)
                return rotated.transformed(by: CGAffineTransform(translationX: -rotated.extent.minX, y: -rotated.extent.minY))
            }
            draw = { screen, face, seconds in
                var result = render(orient(screen, transform), seconds)
                if let face, let overlay {
                    result = WebcamComposition.overlay(orient(face, cameraTransform), on: result, settings: overlay, canvas: canvas)
                }
                return captions.draw(on: result, at: seconds)
            }
        }
    }
}
