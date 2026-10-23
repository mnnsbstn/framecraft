import AVFoundation
import XCTest
@testable import FrameCraft

@MainActor
final class VideoExportTests: XCTestCase {
    private func fixture() async throws -> (directory: URL, source: URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FrameCraft-export-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let source = directory.appendingPathComponent("source.mp4")
        do { try await DemoMovie.generate(at: source) }
        catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
        return (directory, source)
    }

    private func checkExport(format: CanvasFormat) async throws {
        let (directory, source) = try await fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        let destination = directory.appendingPathComponent("result.mp4")
        var project = Project()
        project.duration = 6
        project.trimStart = 1
        project.trimEnd = 4
        project.format = format
        project.zooms = [ZoomRegion(start: 1, end: 4, scale: 2, x: 0.95, y: 0.05)]
        let exporter = ExportService()
        let success = await exporter.export(source: source, project: project, destination: destination)
        XCTAssertTrue(success, exporter.errorMessage ?? "Export failed without an error")
        guard success else { return }
        XCTAssertEqual(exporter.progress, 1)
        XCTAssertFalse(exporter.isExporting)
        let output = AVURLAsset(url: destination)
        let duration = try await output.load(.duration).seconds
        XCTAssertEqual(duration, 3, accuracy: 0.05)
        let videoTracks = try await output.loadTracks(withMediaType: .video)
        let track = try XCTUnwrap(videoTracks.first)
        let size = try await track.load(.naturalSize)
        XCTAssertEqual(size.width, format.size.width, accuracy: 1)
        XCTAssertEqual(size.height, format.size.height, accuracy: 1)
        let generator = AVAssetImageGenerator(asset: output)
        generator.appliesPreferredTrackTransform = true
        let (frame, _) = try await generator.image(at: CMTime(seconds: 1.5, preferredTimescale: 600))
        XCTAssertEqual(frame.width, Int(format.size.width))
        XCTAssertEqual(frame.height, Int(format.size.height))
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        let files = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertEqual(Set(files), Set(["source.mp4", "result.mp4"]))
    }

    func testLandscapeExportUsesTrimAndCanvas() async throws {
        try await checkExport(format: .landscape)
    }

    func testPortraitExportUsesTrimAndCanvas() async throws {
        try await checkExport(format: .portrait)
    }

    func testOriginalAndExistingDestinationCannotBeOverwritten() async throws {
        let (directory, source) = try await fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        let original = try Data(contentsOf: source)
        var project = Project()
        project.duration = 6
        project.trimEnd = 6
        let exporter = ExportService()
        let originalResult = await exporter.export(source: source, project: project, destination: source)
        XCTAssertFalse(originalResult)
        XCTAssertNotNil(exporter.errorMessage)
        XCTAssertEqual(try Data(contentsOf: source), original)
        exporter.clearError()
        XCTAssertNil(exporter.errorMessage)
        let destination = directory.appendingPathComponent("existing.mp4")
        let sentinel = Data("Existing file must survive".utf8)
        try sentinel.write(to: destination)
        let existingResult = await exporter.export(source: source, project: project, destination: destination)
        XCTAssertFalse(existingResult)
        XCTAssertEqual(try Data(contentsOf: destination), sentinel)
    }

    func testCursorIsRenderedInExportAndCanBeHidden() async throws {
        let (directory, source) = try await fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        var project = Project(duration: 6, trimStart: 1, trimEnd: 2)
        project.cursor = CursorTrack(samples: (0...360).map { CursorSample(time: Double($0) / 60, x: 0.5, y: 0.5) }, size: 2)
        project.zooms = [ZoomRegion(start: 0, end: 3, scale: 2, x: 0.5, y: 0.5)]
        let exporter = ExportService()
        var images: [[UInt8]] = []
        for visible in [true, false] {
            project.cursor?.enabled = visible
            let destination = directory.appendingPathComponent(visible ? "cursor.mp4" : "hidden.mp4")
            let success = await exporter.export(source: source, project: project, destination: destination)
            XCTAssertTrue(success, exporter.errorMessage ?? "")
            let generator = AVAssetImageGenerator(asset: AVURLAsset(url: destination))
            let (frame, _) = try await generator.image(at: CMTime(seconds: 0.5, preferredTimescale: 600))
            let context = CGContext(data: nil, width: 1920, height: 1080, bitsPerComponent: 8, bytesPerRow: 1920 * 4,
                                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.draw(frame, in: CGRect(x: 0, y: 0, width: 1920, height: 1080))
            images.append(Array(UnsafeBufferPointer(start: context.data!.assumingMemoryBound(to: UInt8.self), count: 1920 * 1080 * 4)))
        }
        // A zoomed 2x cursor must change the rendered pixels around the center.
        var changed = 0
        for y in 400..<680 { for x in 900..<1120 {
            let offset = (y * 1920 + x) * 4
            if abs(Int(images[0][offset]) - Int(images[1][offset])) > 45 { changed += 1 }
        } }
        XCTAssertGreaterThan(changed, 300)
    }

    func testCancellationLeavesNoOutputOrTemporaryFile() async throws {
        let (directory, source) = try await fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        let destination = directory.appendingPathComponent("cancelled.mp4")
        var project = Project()
        project.duration = 6
        project.trimEnd = 6
        let exporter = ExportService()
        let job = Task { await exporter.export(source: source, project: project, destination: destination) }
        // Wait until preparation has begun. Cancel is deliberately valid during preparation too.
        for _ in 0..<100 where !exporter.isExporting {
            try await Task.sleep(for: .milliseconds(5))
        }
        XCTAssertTrue(exporter.isExporting)
        exporter.cancel()
        let result = await job.value
        XCTAssertFalse(result)
        XCTAssertFalse(exporter.isExporting)
        XCTAssertNil(exporter.errorMessage)
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), ["source.mp4"])
    }
}
