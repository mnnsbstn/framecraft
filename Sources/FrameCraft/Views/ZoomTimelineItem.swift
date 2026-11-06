import SwiftUI

struct ZoomTimelineItem: View {
    @ObservedObject var studio: StudioStore
    @Environment(\.isEnabled) private var isEnabled
    let zoom: ZoomRegion
    let width: CGFloat
    @State private var dragOrigin: ZoomRegion?
    @FocusState private var focusedPart: ZoomTiming.Part?

    private var duration: Double { max(0.01, studio.project.duration) }
    private var pointsPerSecond: Double { max(1, width) / duration }
    private var actualWidth: CGFloat { max(1, (zoom.end - zoom.start) * pointsPerSecond) }
    private var gripWidth: CGFloat { min(width, max(64, actualWidth)) }
    private var selected: Bool { studio.selectedZoom == zoom.id }
    private var timing: String { String(format: "%.2f – %.2f s", zoom.start, zoom.end) }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4).fill(StudioTheme.raised)
            HStack(spacing: 0) {
                target(.start, label: "Zoomanfang", symbol: "chevron.left")
                    .frame(width: 16)
                target(.move, label: "Zoom verschieben", symbol: nil)
                    .frame(maxWidth: .infinity)
                target(.end, label: "Zoomende", symbol: "chevron.right")
                    .frame(width: 16)
            }
            .frame(width: gripWidth, height: 27)
            .background(selected ? StudioTheme.accent : StudioTheme.accent.opacity(0.18), in: RoundedRectangle(cornerRadius: 4))
            .foregroundStyle(selected ? StudioTheme.onAccent : StudioTheme.accent)
            .offset(x: min(max(0, width - gripWidth), zoom.start * pointsPerSecond))
            // Exact temporal span remains visible even when the grab area is expanded.
            Rectangle().fill(StudioTheme.accent).frame(width: actualWidth, height: 2)
                .offset(x: zoom.start * pointsPerSecond, y: 16)
                .allowsHitTesting(false)
        }
        .frame(height: 35)
        .help("\(timing) · Kanten ziehen oder Mitte verschieben. Pfeile: 0,1 s; Umschalt + Pfeil: 0,5 s.")
    }

    private func target(_ part: ZoomTiming.Part, label: String, symbol: String?) -> some View {
        Group {
            if let symbol { Image(systemName: symbol).font(.system(size: 8, weight: .bold)) }
            else { Text(String(format: "%.1f×", zoom.scale)).font(.system(size: 9, weight: .medium)).lineLimit(1) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .focusable()
        .focused($focusedPart, equals: part)
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(focusedPart == part ? Color.white : Color.clear, lineWidth: 2))
        .onTapGesture { select(part) }
        .gesture(DragGesture(minimumDistance: 3, coordinateSpace: .named("zoomTimeline"))
            .onChanged { value in
                if dragOrigin == nil { dragOrigin = zoom; select(part) }
                if let origin = dragOrigin { apply(origin, part: part, delta: value.translation.width / pointsPerSecond) }
            }
            .onEnded { _ in dragOrigin = nil })
        .onKeyPress(keys: [.leftArrow, .rightArrow]) { press in
            let direction = press.key == .leftArrow ? -1.0 : 1.0
            apply(zoom, part: part, delta: direction * (press.modifiers.contains(.shift) ? 0.5 : 0.1))
            return .handled
        }
        .onKeyPress(.space) { select(part); return .handled }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(timing)
        .accessibilityHint("Pfeiltasten ändern die Zeit um 0,1 Sekunden, mit Umschalt um 0,5 Sekunden.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { select(part) }
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: apply(zoom, part: part, delta: 0.1)
            case .decrement: apply(zoom, part: part, delta: -0.1)
            @unknown default: break
            }
        }
    }

    private func select(_ part: ZoomTiming.Part) {
        guard isEnabled else { return }
        focusedPart = part
        studio.selectedZoom = zoom.id
        studio.player.pause(); studio.isPlaying = false
        studio.seek(part == .start ? zoom.start : part == .end ? zoom.end : (zoom.start + zoom.end) / 2)
    }

    private func apply(_ origin: ZoomRegion, part: ZoomTiming.Part, delta: Double) {
        guard isEnabled, let index = studio.project.zooms.firstIndex(where: { $0.id == origin.id }) else { return }
        let updated = ZoomTiming.edited(origin, part: part, delta: delta, duration: studio.project.duration)
        studio.selectedZoom = origin.id
        studio.player.pause(); studio.isPlaying = false
        if studio.project.zooms[index] != updated { studio.project.zooms[index] = updated }
        studio.seek(part == .start ? updated.start : part == .end ? updated.end : (updated.start + updated.end) / 2)
    }
}
