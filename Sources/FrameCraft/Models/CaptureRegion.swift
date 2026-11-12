import CoreGraphics

/// A top-left-origin rectangle in logical display points, independent of the display's desktop origin.
struct CaptureRegion {
    let displayID: CGDirectDisplayID
    let displaySize: CGSize
    let rect: CGRect

    func isCurrent() -> Bool {
        CGDisplayIsActive(displayID) != 0 && CGDisplayBounds(displayID).size == displaySize &&
            CGRect(origin: .zero, size: displaySize).contains(rect) && rect.width >= 2 && rect.height >= 2
    }

    var desktopBounds: CGRect {
        let origin = CGDisplayBounds(displayID).origin
        return rect.offsetBy(dx: origin.x, dy: origin.y)
    }
}
