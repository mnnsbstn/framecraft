import AVFoundation
import CoreImage
import ImageIO
import UniformTypeIdentifiers

/// Runs outside the main actor; only progress values cross back to the interface.
enum MediaExportWorker {
    static func write(source: URL, project: Project, settings: ExportSettings, destination: URL,
                      progress: @escaping @Sendable (Double) async -> Void) async throws {
        let asset = try await WebcamComposition.asset(source: source, project: project)
        let duration = try await asset.load(.duration).seconds
        guard project.trimStart.isFinite, project.trimEnd.isFinite, duration.isFinite else { throw RenderError.invalidDuration }
        let start = max(0, project.trimStart), end = min(duration, project.trimEnd)
        guard end > start else { throw RenderError.invalidDuration }
        if let message = settings.validationMessage(duration: end - start) { throw RenderError.failed(message) }
        try Task.checkCancellation()
        let composition = try await VideoRenderer.composition(asset: asset, project: project,
                                                               outputSize: settings.size(for: project.format), fps: settings.frameRate)
        try Task.checkCancellation()
        if settings.format == .gif {
            try await gif(asset: asset, composition: composition, settings: settings, start: start, end: end,
                          destination: destination, progress: progress)
        } else {
            try await mp4(asset: asset, composition: composition, project: project, settings: settings,
                          start: start, end: end, destination: destination, progress: progress)
        }
    }

    private static func mp4(asset: AVAsset, composition: AVVideoComposition, project: Project,
                            settings: ExportSettings, start: Double, end: Double, destination: URL,
                            progress: @escaping @Sendable (Double) async -> Void) async throws {
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard !tracks.isEmpty else { throw RenderError.missingVideo }
        let reader = try AVAssetReader(asset: asset)
        reader.timeRange = CMTimeRange(start: CMTime(seconds: start, preferredTimescale: 600),
                                       end: CMTime(seconds: end, preferredTimescale: 600))
        let video = AVAssetReaderVideoCompositionOutput(videoTracks: tracks,
                  videoSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        video.videoComposition = composition
        video.alwaysCopiesSampleData = false
        guard reader.canAdd(video) else { throw RenderError.exportUnavailable }
        reader.add(video)
        let writer = try AVAssetWriter(outputURL: destination, fileType: .mp4)
        writer.shouldOptimizeForNetworkUse = true
        let size = settings.size(for: project.format)
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: Int(size.width), AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: settings.bitRate(for: project.format),
                AVVideoExpectedSourceFrameRateKey: settings.fps, AVVideoMaxKeyFrameIntervalKey: settings.fps * 2,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel]])
        videoInput.expectsMediaDataInRealTime = false
        guard writer.canAdd(videoInput) else { throw RenderError.exportUnavailable }
        writer.add(videoInput)

        var audio: AVAssetReaderAudioMixOutput?
        var audioInput: AVAssetWriterInput?
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        if !project.muted && !audioTracks.isEmpty {
            let output = AVAssetReaderAudioMixOutput(audioTracks: audioTracks, audioSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 48_000, AVNumberOfChannelsKey: 2,
                AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsNonInterleaved: false])
            let input = AVAssetWriterInput(mediaType: .audio, outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 48_000,
                AVNumberOfChannelsKey: 2, AVEncoderBitRateKey: 192_000])
            input.expectsMediaDataInRealTime = false
            guard reader.canAdd(output), writer.canAdd(input) else { throw RenderError.exportUnavailable }
            reader.add(output); writer.add(input); audio = output; audioInput = input
        }
        do {
            guard writer.startWriting() else { throw writer.error ?? RenderError.exportUnavailable }
            writer.startSession(atSourceTime: CMTime(seconds: start, preferredTimescale: 600))
            guard reader.startReading() else { throw reader.error ?? RenderError.exportUnavailable }
            var videoDone = false, audioDone = audio == nil, lastProgress = -1.0
            while !videoDone || !audioDone {
                try Task.checkCancellation()
                if reader.status == .failed { throw reader.error ?? RenderError.exportUnavailable }
                if writer.status == .failed { throw writer.error ?? RenderError.exportUnavailable }
                var advanced = false
                if !videoDone && videoInput.isReadyForMoreMediaData {
                    let fraction: Double? = try autoreleasepool {
                        guard let sample = video.copyNextSampleBuffer() else { videoDone = true; videoInput.markAsFinished(); return nil }
                        guard videoInput.append(sample) else { throw writer.error ?? RenderError.exportUnavailable }
                        return min(0.98, max(0, (sample.presentationTimeStamp.seconds - start) / (end - start)))
                    }
                    if let fraction, fraction - lastProgress >= 0.01 { lastProgress = fraction; await progress(fraction) }
                    advanced = true
                }
                if !audioDone, let audio, let audioInput, audioInput.isReadyForMoreMediaData {
                    try autoreleasepool {
                        if let sample = audio.copyNextSampleBuffer() {
                            guard audioInput.append(sample) else { throw writer.error ?? RenderError.exportUnavailable }
                        } else { audioDone = true; audioInput.markAsFinished() }
                    }
                    advanced = true
                }
                if !advanced { try await Task.sleep(for: .milliseconds(2)) }
            }
            guard reader.status == .completed else { throw reader.error ?? RenderError.exportUnavailable }
            writer.endSession(atSourceTime: CMTime(seconds: end, preferredTimescale: 600))
            await writer.finishWriting()
            try Task.checkCancellation()
            guard writer.status == .completed else { throw writer.error ?? RenderError.exportUnavailable }
        } catch {
            reader.cancelReading(); writer.cancelWriting()
            throw error
        }
    }

    private static func gif(asset: AVAsset, composition: AVVideoComposition, settings: ExportSettings,
                            start: Double, end: Double, destination: URL,
                            progress: @escaping @Sendable (Double) async -> Void) async throws {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.videoComposition = composition
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        let count = max(1, Int(ceil((end - start) * Double(settings.gifFPS))))
        guard let output = CGImageDestinationCreateWithURL(destination as CFURL, UTType.gif.identifier as CFString, count, nil) else {
            throw RenderError.failed("Die GIF-Datei konnte nicht angelegt werden.")
        }
        CGImageDestinationSetProperties(output, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
        defer { generator.cancelAllCGImageGeneration() }
        for index in 0..<count {
            try Task.checkCancellation()
            let offset = Double(index) / Double(settings.gifFPS)
            let frame = try await generator.image(at: CMTime(seconds: start + offset, preferredTimescale: 600))
            try Task.checkCancellation()
            let delay = max(0.02, min(1 / Double(settings.gifFPS), end - start - offset))
            autoreleasepool {
                CGImageDestinationAddImage(output, frame.image, [kCGImagePropertyGIFDictionary: [
                    kCGImagePropertyGIFDelayTime: delay, kCGImagePropertyGIFUnclampedDelayTime: delay]] as CFDictionary)
            }
            await progress(Double(index + 1) / Double(count) * 0.95)
        }
        try Task.checkCancellation()
        guard CGImageDestinationFinalize(output) else { throw RenderError.failed("Die GIF-Datei konnte nicht abgeschlossen werden.") }
        try Task.checkCancellation()
    }
}
