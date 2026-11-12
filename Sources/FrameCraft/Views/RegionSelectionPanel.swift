import AppKit

@MainActor
final class RegionSelectionPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }

    static func choose(on screen: NSScreen, initial: CGRect?) -> CGRect? {
        let panel = RegionSelectionPanel(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        panel.setFrame(screen.frame, display: false)
        panel.worksWhenModal = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.isReleasedWhenClosed = false
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let view = RegionSelectionView(frame: CGRect(origin: .zero, size: screen.frame.size))
        view.selection = initial
        panel.contentView = view
        let sheet = NSApp.keyWindow
        let parent = sheet?.sheetParent ?? sheet
        parent?.orderOut(nil)
        let screensChanged = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { _ in MainActor.assumeIsolated { if NSApp.modalWindow === panel { NSApp.abortModal() } } }
        defer {
            NotificationCenter.default.removeObserver(screensChanged)
            panel.orderOut(nil)
            parent?.makeKeyAndOrderFront(nil)
            sheet?.makeKey()
        }
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(view)
        return NSApp.runModal(for: panel) == .OK ? view.selection : nil
    }
}

private final class RegionSelectionView: NSView {
    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { true }
    private var anchor: CGPoint?
    var selection: CGRect? { didSet { needsDisplay = true } }

    override func resetCursorRects() { addCursorRect(bounds, cursor: .crosshair) }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    private func point(_ event: NSEvent) -> CGPoint {
        let p = convert(event.locationInWindow, from: nil)
        return CGPoint(x: min(bounds.maxX, max(0, p.x.rounded())), y: min(bounds.maxY, max(0, p.y.rounded())))
    }

    override func mouseDown(with event: NSEvent) {
        anchor = point(event)
        selection = nil
    }

    override func mouseDragged(with event: NSEvent) {
        guard let anchor else { return }
        let end = point(event)
        let rect = CGRect(x: min(anchor.x, end.x), y: min(anchor.y, end.y),
                          width: abs(end.x - anchor.x), height: abs(end.y - anchor.y))
        selection = rect.width >= 2 && rect.height >= 2 ? rect : nil
    }

    override func mouseUp(with event: NSEvent) {
        mouseDragged(with: event)
        anchor = nil
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: NSApp.abortModal()
        case 36, 76:
            if selection != nil { NSApp.stopModal(withCode: .OK) } else { NSSound.beep() }
        default: super.keyDown(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        // Keep the clear-looking interior mouse-active when the user redraws.
        NSColor.black.withAlphaComponent(0.015).setFill()
        bounds.fill(using: .copy)
        let dim = NSBezierPath(rect: bounds)
        if let selection { dim.appendRect(selection) }
        dim.windingRule = .evenOdd
        NSColor.black.withAlphaComponent(0.50).setFill()
        dim.fill()
        if let selection {
            let outline = NSBezierPath(rect: selection.insetBy(dx: 0.5, dy: 0.5))
            NSColor(srgbRed: 229/255, green: 1, blue: 66/255, alpha: 1).setStroke()
            outline.lineWidth = 1
            outline.stroke()
        }
        let prefix = selection.map { "\(Int($0.width)) × \(Int($0.height)) pt    " } ?? ""
        let hint = NSAttributedString(string: prefix + "Bereich aufziehen   ·   ↩ Übernehmen   ·   esc Abbrechen",
                                     attributes: [.font: NSFont.systemFont(ofSize: 14, weight: .medium), .foregroundColor: NSColor.white])
        let text = hint.size()
        let badge = CGRect(x: (bounds.width - text.width) / 2 - 12, y: bounds.height - text.height - 54,
                           width: text.width + 24, height: text.height + 16)
        NSColor.black.withAlphaComponent(0.9).setFill()
        NSBezierPath(roundedRect: badge, xRadius: 8, yRadius: 8).fill()
        hint.draw(at: CGPoint(x: badge.minX + 12, y: badge.minY + 8))
    }
}
