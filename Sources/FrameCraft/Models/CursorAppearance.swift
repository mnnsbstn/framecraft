import Foundation
import CoreGraphics

/// Packed premultiplied RGBA, with logical size and hotspot in top-left-origin AppKit points.
struct CursorAppearance: Codable, Equatable, Hashable, Sendable {
    static let maxDimension = 256
    static let maxCount = 256
    static let byteBudget = 16 * 1024 * 1024

    let width: Int
    let height: Int
    let pointSize: CGSize
    let hotSpot: CGPoint
    let pixels: Data

    var isValid: Bool {
        (1...Self.maxDimension).contains(width) && (1...Self.maxDimension).contains(height) &&
        pixels.count == width * height * 4 &&
        pointSize.width.isFinite && pointSize.height.isFinite &&
        pointSize.width > 0 && pointSize.height > 0 && pointSize.width <= 1024 && pointSize.height <= 1024 &&
        hotSpot.x.isFinite && hotSpot.y.isFinite && abs(hotSpot.x) <= 1024 && abs(hotSpot.y) <= 1024
    }

    static let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue))
    static let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

    func image() -> CGImage? {
        guard isValid, let provider = CGDataProvider(data: pixels as CFData) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                       space: Self.colorSpace, bitmapInfo: Self.bitmapInfo, provider: provider,
                       decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }
}
