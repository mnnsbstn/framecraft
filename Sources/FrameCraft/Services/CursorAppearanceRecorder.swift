import AppKit

/// Keep one copy of each observed shape. Cursor objects returned by other apps may have different identities for the same pixels.
@MainActor
struct CursorAppearanceRecorder {
    private(set) var appearances: [CursorAppearance] = []
    private var indices: [CursorAppearance: Int] = [:]
    private var totalBytes = 0
    private var lastCursor: NSCursor?
    private var lastIndex: Int?

    mutating func currentIndex() -> Int? {
        guard let cursor = NSCursor.currentSystem else { return nil }
        if cursor === lastCursor { return lastIndex }
        lastCursor = cursor
        lastIndex = nil
        let image = cursor.image
        var rect = CGRect(origin: .zero, size: image.size)
        guard let cg = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else { return nil }
        let factor = min(1, CGFloat(CursorAppearance.maxDimension) / CGFloat(max(cg.width, cg.height)))
        let width = max(1, Int((CGFloat(cg.width) * factor).rounded()))
        let height = max(1, Int((CGFloat(cg.height) * factor).rounded()))
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                      space: CursorAppearance.colorSpace, bitmapInfo: CursorAppearance.bitmapInfo.rawValue),
              let bytes = context.data else { return nil }
        context.setBlendMode(.copy)
        context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        let appearance = CursorAppearance(width: width, height: height, pointSize: image.size, hotSpot: cursor.hotSpot,
                                          pixels: Data(bytes: bytes, count: width * height * 4))
        guard appearance.isValid else { return nil }
        if let index = indices[appearance] {
            lastIndex = index
        } else if appearances.count < CursorAppearance.maxCount, totalBytes + appearance.pixels.count <= CursorAppearance.byteBudget {
            lastIndex = appearances.count
            indices[appearance] = appearances.count
            appearances.append(appearance)
            totalBytes += appearance.pixels.count
        }
        return lastIndex
    }
}
