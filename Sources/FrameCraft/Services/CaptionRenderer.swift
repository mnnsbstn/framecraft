import AppKit
import CoreImage
import CoreText

final class CaptionRenderer {
    private let cues: [Caption]
    private let style: CaptionStyle
    private let canvas: CGRect
    private let cache = NSCache<NSUUID, CIImage>()

    init(project: Project, canvas: CGRect) {
        cues = project.captions ?? []
        style = project.captionStyle ?? .standard
        self.canvas = canvas
        cache.totalCostLimit = 16 * 1024 * 1024
    }

    func draw(on frame: CIImage, at time: Double) -> CIImage {
        var low = 0, high = cues.count
        while low < high {
            let middle = low + (high - low) / 2
            if cues[middle].end <= time { low = middle + 1 } else { high = middle }
        }
        guard low < cues.count, cues[low].start <= time else { return frame }
        let cue = cues[low]
        let key = cue.id as NSUUID
        let plate: CIImage
        if let cached = cache.object(forKey: key) { plate = cached }
        else {
            guard let image = makePlate(cue.text) else { return frame }
            plate = image
            cache.setObject(image, forKey: key, cost: Int(image.extent.width * image.extent.height * 4))
        }
        let margin = canvas.height * 0.06
        let origin = CGPoint(x: (canvas.width - plate.extent.width) / 2,
                             y: style == .top ? canvas.height - plate.extent.height - margin : margin)
        return plate.transformed(by: CGAffineTransform(translationX: origin.x, y: origin.y)).composited(over: frame).cropped(to: canvas)
    }

    private func makePlate(_ text: String) -> CIImage? {
        let side = min(canvas.width, canvas.height)
        let fontSize = side * (style == .large ? 0.057 : 0.04)
        let padding = ceil(fontSize * 0.4), limit = floor(canvas.width * 0.86 - 2 * padding)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let string = NSAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
            .foregroundColor: NSColor.white, .paragraphStyle: paragraph
        ])
        let setter = CTFramesetterCreateWithAttributedString(string)
        let range = CFRange(location: 0, length: string.length)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(setter, range, nil,
            CGSize(width: limit, height: .greatestFiniteMagnitude), nil)
        let w = Int(ceil(min(limit, size.width + 2) + 2 * padding))
        let h = Int(ceil(size.height + fontSize * 0.2 + 2 * padding))
        guard w > 0, h > 0, let context = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        let box = CGRect(x: 0, y: 0, width: CGFloat(w), height: CGFloat(h))
        context.setFillColor(CGColor(gray: 0.04, alpha: 0.85))
        context.addPath(CGPath(roundedRect: box, cornerWidth: padding, cornerHeight: padding, transform: nil))
        context.fillPath()
        let path = CGPath(rect: box.insetBy(dx: padding, dy: padding), transform: nil)
        CTFrameDraw(CTFramesetterCreateFrame(setter, range, path, nil), context)
        return context.makeImage().map { CIImage(cgImage: $0) }
    }
}
