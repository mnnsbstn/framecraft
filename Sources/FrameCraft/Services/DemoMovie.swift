import AVFoundation
import CoreGraphics
import CoreVideo
import Foundation

enum DemoMovie {
    /// Creates original animated sample pixels so the editor can be tried without screen access.
    static func generate(at destination: URL) async throws {
        guard !FileManager.default.fileExists(atPath: destination.path) else { throw RenderError.destinationExists }
        let isMP4 = destination.pathExtension.lowercased() == "mp4"
        let temporary = destination.deletingLastPathComponent()
            .appendingPathComponent(".demo-\(UUID().uuidString).\(isMP4 ? "mp4" : "mov")")
        let writer = try AVAssetWriter(outputURL: temporary, fileType: isMP4 ? .mp4 : .mov)
        defer { try? FileManager.default.removeItem(at: temporary) }
        let width = 960, height = 540
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 2_000_000,
                                             AVVideoExpectedSourceFrameRateKey: 30]
        ])
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ])
        guard writer.canAdd(input) else { throw RenderError.exportUnavailable }
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? RenderError.exportUnavailable }
        writer.startSession(atSourceTime: .zero)
        do {
            for frame in 0..<180 {
                try Task.checkCancellation()
                while !input.isReadyForMoreMediaData {
                    guard writer.status == .writing else { throw writer.error ?? RenderError.exportUnavailable }
                    try await Task.sleep(for: .milliseconds(3))
                }
                guard let pool = adaptor.pixelBufferPool else { throw RenderError.exportUnavailable }
                var buffer: CVPixelBuffer?
                guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer) == kCVReturnSuccess, let buffer else {
                    throw RenderError.failed("Das Demo-Videobild konnte nicht erstellt werden.")
                }
                try draw(buffer, frame: frame, width: width, height: height)
                guard adaptor.append(buffer, withPresentationTime: CMTime(value: Int64(frame), timescale: 30)) else {
                    throw writer.error ?? RenderError.exportUnavailable
                }
            }
            input.markAsFinished()
            writer.endSession(atSourceTime: CMTime(value: 6, timescale: 1))
            await writer.finishWriting()
            try Task.checkCancellation()
            guard writer.status == .completed else { throw writer.error ?? RenderError.exportUnavailable }
            try FileManager.default.moveItem(at: temporary, to: destination)
        } catch {
            writer.cancelWriting()
            throw error
        }
    }

    private static func draw(_ buffer: CVPixelBuffer, frame: Int, width: Int, height: Int) throws {
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) else {
            throw RenderError.failed("Das Demo-Videobild konnte nicht gezeichnet werden.")
        }
        func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) {
            context.setFillColor(CGColor(red: r, green: g, blue: b, alpha: a))
        }
        func rounded(_ rectangle: CGRect, radius: CGFloat = 12) {
            context.addPath(CGPath(roundedRect: rectangle, cornerWidth: radius, cornerHeight: radius, transform: nil))
            context.fillPath()
        }
        color(0.07, 0.08, 0.11)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        color(0.11, 0.12, 0.16)
        rounded(CGRect(x: 24, y: 24, width: 912, height: 492), radius: 18)
        color(0.16, 0.17, 0.22)
        rounded(CGRect(x: 42, y: 42, width: 162, height: 456))
        for (index, rgb) in [(0.95, 0.35, 0.38), (0.98, 0.75, 0.30), (0.36, 0.80, 0.50)].enumerated() {
            color(rgb.0, rgb.1, rgb.2)
            context.fillEllipse(in: CGRect(x: 58 + index * 22, y: 470, width: 12, height: 12))
        }
        for index in 0..<7 {
            color(index == 2 ? 0.48 : 0.26, index == 2 ? 0.40 : 0.27, index == 2 ? 0.88 : 0.33)
            rounded(CGRect(x: 57, y: 406 - index * 40, width: 132, height: 26), radius: 6)
        }
        color(0.82, 0.84, 0.92)
        rounded(CGRect(x: 232, y: 454, width: 244, height: 15), radius: 6)
        color(0.34, 0.36, 0.44)
        rounded(CGRect(x: 232, y: 425, width: 360, height: 8), radius: 4)
        let t = Double(frame) / 30
        for index in 0..<3 {
            color(0.17, 0.18, 0.24)
            rounded(CGRect(x: 232 + index * 224, y: 314, width: 206, height: 86))
            color(0.57, 0.51, 0.94)
            rounded(CGRect(x: 250 + index * 224, y: 361, width: 65 + 15 * index, height: 11), radius: 4)
            color(0.36, 0.38, 0.46)
            rounded(CGRect(x: 250 + index * 224, y: 336, width: 128, height: 8), radius: 4)
        }
        color(0.15, 0.16, 0.21)
        rounded(CGRect(x: 232, y: 66, width: 654, height: 224))
        for index in 0..<12 {
            let barHeight = 60 + 95 * (0.5 + 0.5 * sin(Double(index) * 0.5 + t))
            color(0.42 + CGFloat(index) * 0.014, 0.39, 0.80 + CGFloat(index) * 0.012)
            rounded(CGRect(x: Double(253 + index * 51), y: 87, width: 31, height: barHeight), radius: 5)
        }
    }

    static var cursorSamples: [CursorSample] {
        (0...360).map { index in
            let t = Double(index) / 60
            return CursorSample(time: t, x: (490 + sin(t * 0.8) * 215) / 960 + sin(t * 83) * 0.004,
                                y: 1 - (280 + cos(t * 1.1) * 110) / 540 + cos(t * 77) * 0.004)
        }
    }
}
