import AVFoundation
import ImageIO
import XCTest
@testable import FrameCraft

@MainActor
final class ExportOptionsTests: XCTestCase {
    private func fixture() async throws -> (URL, URL) {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("FrameCraft-options-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let source = root.appendingPathComponent("source.mp4")
        try await DemoMovie.generate(at: source)
        return (root, source)
    }

    func testOutputSizesRatesAndLimits() {
        var settings = ExportSettings()
        XCTAssertEqual(settings.size(for: .landscape), CGSize(width: 1920, height: 1080))
        settings.resolution = .hd
        XCTAssertEqual(settings.size(for: .portrait), CGSize(width: 720, height: 1280))
        settings.resolution = .ultraHD
        XCTAssertEqual(settings.size(for: .square), CGSize(width: 2160, height: 2160))
        let high = settings.bitRate(for: .landscape)
        settings.quality = .compact
        XCTAssertLessThan(settings.bitRate(for: .landscape), high)
        settings.fps = 0
        XCTAssertNotNil(settings.validationMessage(duration: 1))
        settings.format = .gif; settings.gifLongEdge = 720
        XCTAssertEqual(settings.size(for: .portrait), CGSize(width: 404, height: 720))
        XCTAssertNotNil(settings.validationMessage(duration: 11))
        XCTAssertNotNil(settings.validationMessage(duration: .infinity))
        XCTAssertNil(settings.validationMessage(duration: 10))
        XCTAssertNil(settings.estimatedBytes(duration: 10, canvas: .landscape))
    }

    func testConfiguredMP4ResolutionFrameRateAndTrim() async throws {
        let (root, source) = try await fixture(); defer { try? FileManager.default.removeItem(at: root) }
        let service = ExportService()
        for (resolution, fps, format, quality) in [(ExportSettings.Resolution.hd, 24, CanvasFormat.portrait, ExportSettings.Quality.compact), (.ultraHD, 60, .landscape, .high)] {
            let settings = ExportSettings(resolution: resolution, fps: fps, quality: quality)
            let destination = root.appendingPathComponent("\(fps).mp4")
            let project = Project(duration: 6, trimStart: 1, trimEnd: 1.5, format: format, zooms: [.init(start: 0.8, end: 2, scale: 2)])
            let success = await service.export(source: source, project: project, destination: destination, settings: settings)
            XCTAssertTrue(success, service.errorMessage ?? "")
            guard success else { continue }
            let asset = AVURLAsset(url: destination)
            let tracks = try await asset.loadTracks(withMediaType: .video)
            let track = try XCTUnwrap(tracks.first)
            let size = try await track.load(.naturalSize), rate = try await track.load(.nominalFrameRate)
            XCTAssertEqual(size, settings.size(for: format)); XCTAssertEqual(Double(rate), Double(fps), accuracy: 0.1)
            let duration = try await asset.load(.duration).seconds
            XCTAssertEqual(duration, 0.5, accuracy: 1 / Double(fps))
            let frame = try await AVAssetImageGenerator(asset: asset).image(at: CMTime(seconds: 0.2, preferredTimescale: 600))
            XCTAssertEqual(frame.image.width, Int(size.width))
        }
    }

    func testGIFFramesDimensionsDelayAndLoop() async throws {
        let (root, source) = try await fixture(); defer { try? FileManager.default.removeItem(at: root) }
        let destination = root.appendingPathComponent("loop.gif")
        let service = ExportService()
        let settings = ExportSettings(format: .gif, gifLongEdge: 480, gifFPS: 10)
        let project = Project(duration: 6, trimStart: 1, trimEnd: 2, format: .portrait, zooms: [.init(start: 0.5, end: 3, scale: 2)])
        let success = await service.export(source: source, project: project, destination: destination, settings: settings)
        XCTAssertTrue(success, service.errorMessage ?? "")
        guard success else { return }
        let image = try XCTUnwrap(CGImageSourceCreateWithURL(destination as CFURL, nil))
        XCTAssertEqual(CGImageSourceGetCount(image), 10)
        let properties = try XCTUnwrap(CGImageSourceCopyProperties(image, nil) as? [CFString: Any])
        let gif = try XCTUnwrap(properties[kCGImagePropertyGIFDictionary] as? [CFString: Any])
        XCTAssertEqual(gif[kCGImagePropertyGIFLoopCount] as? Int, 0)
        for index in 0..<10 {
            let frame = try XCTUnwrap(CGImageSourceCreateImageAtIndex(image, index, nil))
            XCTAssertEqual(frame.width, 270); XCTAssertEqual(frame.height, 480)
            let props = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(image, index, nil) as? [CFString: Any])
            let timing = try XCTUnwrap(props[kCGImagePropertyGIFDictionary] as? [CFString: Any])
            XCTAssertEqual(try XCTUnwrap(timing[kCGImagePropertyGIFDelayTime] as? Double), 0.1, accuracy: 0.001)
        }
        XCTAssertEqual(service.progress, 1)
    }

    func testGIFLimitsOverwriteCancellationAndRecovery() async throws {
        let (root, source) = try await fixture(); defer { try? FileManager.default.removeItem(at: root) }
        let service = ExportService(), settings = ExportSettings(format: .gif, gifLongEdge: 720, gifFPS: 20)
        let destination = root.appendingPathComponent("test.gif")
        let tooLong = await service.export(source: source, project: Project(duration: 20, trimEnd: 20), destination: destination, settings: settings)
        XCTAssertFalse(tooLong); XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        let sentinel = Data("preserve".utf8); try sentinel.write(to: destination)
        let overwrite = await service.export(source: source, project: Project(duration: 6, trimEnd: 6), destination: destination, settings: settings)
        XCTAssertFalse(overwrite); XCTAssertEqual(try Data(contentsOf: destination), sentinel)
        let cancelled = root.appendingPathComponent("cancel.gif")
        let task = Task { await service.export(source: source, project: Project(duration: 6, trimEnd: 6), destination: cancelled, settings: settings) }
        for _ in 0..<1000 where service.progress == 0 { try await Task.sleep(for: .milliseconds(5)) }
        XCTAssertTrue(service.isExporting); XCTAssertGreaterThan(service.progress, 0)
        service.cancel(); let result = await task.value
        XCTAssertFalse(result); XCTAssertNil(service.errorMessage)
        XCTAssertFalse(FileManager.default.fileExists(atPath: cancelled.path))
        let retry = await service.export(source: source, project: Project(duration: 6, trimEnd: 0.2), destination: cancelled, settings: settings)
        XCTAssertTrue(retry, service.errorMessage ?? "")
        XCTAssertFalse(try FileManager.default.contentsOfDirectory(atPath: root.path).contains { $0.hasPrefix(".framecraft-") })
    }

    func testSyntheticAudioSurvivesTrimAndMuteRemovesAudioTrack() async throws {
        let (root, source) = try await fixture(); defer { try? FileManager.default.removeItem(at: root) }
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2))
        let pcm = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 96_000)); pcm.frameLength = pcm.frameCapacity
        let channels = try XCTUnwrap(pcm.floatChannelData)
        for channel in 0..<2 { for index in 0..<Int(pcm.frameLength) { channels[channel][index] = Float(sin(Double(index) * 2 * .pi * 440 / 48_000) * 0.1) } }
        let tone = root.appendingPathComponent("tone.caf")
        do { let file = try AVAudioFile(forWriting: tone, settings: format.settings); try file.write(from: pcm) }
        let mix = AVMutableComposition()
        try await mix.insertTimeRange(CMTimeRange(start: .zero, duration: CMTime(seconds: 2, preferredTimescale: 600)), of: AVURLAsset(url: source), at: .zero)
        let toneAsset = AVURLAsset(url: tone)
        let audioTracks = try await toneAsset.loadTracks(withMediaType: .audio)
        let audio = try XCTUnwrap(audioTracks.first)
        // Two synthetic tracks also exercise the mixing path.
        for _ in 0..<2 {
            let track = try XCTUnwrap(mix.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid))
            try track.insertTimeRange(CMTimeRange(start: .zero, duration: CMTime(seconds: 2, preferredTimescale: 600)), of: audio, at: .zero)
        }
        let av = root.appendingPathComponent("av.mov")
        let preparation = try XCTUnwrap(AVAssetExportSession(asset: mix, presetName: AVAssetExportPresetPassthrough))
        do { try await preparation.export(to: av, as: .mov) }
        catch { XCTFail("Synthetic fixture preparation failed: \(error)"); return }
        let service = ExportService()
        for muted in [false, true] {
            let output = root.appendingPathComponent("audio-\(muted).mp4")
            let project = Project(duration: 2, trimStart: 0.5, trimEnd: 1.5, muted: muted)
            let success = await service.export(source: av, project: project, destination: output, settings: ExportSettings(resolution: .hd))
            XCTAssertTrue(success, service.errorMessage ?? "")
            guard success else { continue }
            let asset = AVURLAsset(url: output)
            let tracks = try await asset.loadTracks(withMediaType: .audio)
            XCTAssertEqual(tracks.count, muted ? 0 : 1)
            let duration = try await asset.load(.duration).seconds
            XCTAssertEqual(duration, 1, accuracy: 0.05)
            if let track = tracks.first {
                let reader = try AVAssetReader(asset: asset)
                let audio = AVAssetReaderTrackOutput(track: track, outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM])
                reader.add(audio); XCTAssertTrue(reader.startReading())
                XCTAssertNotNil(audio.copyNextSampleBuffer())
                reader.cancelReading()
            }
        }
    }
}
