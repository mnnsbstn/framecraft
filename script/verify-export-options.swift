import Foundation
import AVFoundation
import ImageIO

struct Fixture: Decodable { let project: Project; let mediaFilename: String }
@main struct ExportCheck {
    @MainActor static func main() async throws {
        let folder = URL(fileURLWithPath: CommandLine.arguments[1])
        let root = URL(fileURLWithPath: CommandLine.arguments[2])
        let fixture = try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: folder.appendingPathComponent("project.json")))
        let source = folder.appendingPathComponent(fixture.mediaFilename)
        let service = ExportService()
        let settings = [ExportSettings(resolution: .hd, fps: 24, quality: .compact), ExportSettings(format: .gif)]
        var reports: [[String: Any]] = []
        for setting in settings {
            let target = root.appendingPathComponent("FrameCraft-Exporttest-0.5.0.\(setting.fileExtension)")
            guard await service.export(source: source, project: fixture.project, destination: target, settings: setting) else {
                throw NSError(domain: "ExportCheck", code: 1, userInfo: [NSLocalizedDescriptionKey: service.errorMessage ?? "Export cancelled"])
            }
            var report: [String: Any] = ["file": target.lastPathComponent, "bytes": try target.resourceValues(forKeys: [.fileSizeKey]).fileSize!, "format": setting.fileExtension]
            if setting.format == .mp4 {
                let asset = AVURLAsset(url: target)
                let tracks = try await asset.loadTracks(withMediaType: .video)
                let track = tracks[0], size = try await tracks[0].load(.naturalSize)
                let reader = try AVAssetReader(asset: asset)
                let output = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
                reader.add(output); guard reader.startReading() else { throw reader.error! }
                var frames = 0
                while let _ = autoreleasepool(invoking: { output.copyNextSampleBuffer() }) { frames += 1 }
                guard reader.status == .completed else { throw reader.error! }
                report["decoded_frames"] = frames; report["dimensions"] = [Int(size.width), Int(size.height)]
                report["fps"] = try await track.load(.nominalFrameRate)
                report["duration_seconds"] = try await asset.load(.duration).seconds
                report["audio_tracks"] = try await asset.loadTracks(withMediaType: .audio).count
            } else {
                let image = CGImageSourceCreateWithURL(target as CFURL, nil)!
                let count = CGImageSourceGetCount(image)
                var total = 0.0
                for index in 0..<count {
                    let frame = CGImageSourceCreateImageAtIndex(image, index, nil)!
                    report["dimensions"] = [frame.width, frame.height]
                    let props = CGImageSourceCopyPropertiesAtIndex(image, index, nil)! as NSDictionary
                    let gif = props[kCGImagePropertyGIFDictionary] as! NSDictionary
                    total += gif[kCGImagePropertyGIFUnclampedDelayTime] as? Double ?? gif[kCGImagePropertyGIFDelayTime] as! Double
                }
                let props = CGImageSourceCopyProperties(image, nil)! as NSDictionary
                report["loop_count"] = (props[kCGImagePropertyGIFDictionary] as! NSDictionary)[kCGImagePropertyGIFLoopCount]
                report["decoded_frames"] = count; report["duration_seconds"] = total
            }
            reports.append(report)
        }
        let data = try JSONSerialization.data(withJSONObject: reports, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: root.appendingPathComponent("export-media-0.5.0.json"))
        print(String(decoding: data, as: UTF8.self))
    }
}
