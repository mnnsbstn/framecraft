import SwiftUI

struct TimelineView: View {
    @ObservedObject var studio: StudioStore
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ZEITLEISTE").font(.system(size: 10, weight: .semibold)).tracking(1.2).foregroundStyle(.secondary)
                Spacer()
                Button { studio.addZoom() } label: { Label("Zoom hinzufügen", systemImage: "plus.magnifyingglass") }.font(.caption)
            }
            GeometryReader { geometry in
                let width = geometry.size.width
                let duration = max(0.01, studio.project.duration)
                VStack(spacing: 9) {
                    HStack {
                        ForEach(0..<5) { tick in
                            Text(timeLabel(duration * Double(tick) / 4)).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
                            if tick < 4 { Spacer() }
                        }
                    }
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5).fill(StudioTheme.accent.opacity(0.06))
                        RoundedRectangle(cornerRadius: 5).fill(StudioTheme.accent.opacity(0.16))
                            .frame(width: max(1, width * studio.project.outputDuration / duration))
                            .offset(x: width * studio.project.trimStart / duration)
                        Label("Originalvideo", systemImage: "film")
                            .font(.system(size: 10, weight: .medium)).foregroundStyle(StudioTheme.accent)
                            .padding(.horizontal, 12).allowsHitTesting(false)
                        Rectangle().fill(.primary).frame(width: 1.5).offset(x: min(width - 1, width * studio.currentTime / duration))
                    }
                    .frame(height: 42)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0).onChanged { studio.seek(min(1, max(0, $0.location.x / width)) * duration) })
                    ScrollView(.vertical) {
                        VStack(spacing: 5) {
                            ForEach(studio.project.zooms) { zoom in
                                ZoomTimelineItem(studio: studio, zoom: zoom, width: width)
                            }
                            if studio.project.zooms.isEmpty {
                                Text("Noch keine Zooms").font(.caption2).foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, minHeight: 35)
                            }
                        }.padding(.vertical, 3)
                    }
                    .coordinateSpace(name: "zoomTimeline")
                    .frame(height: 84)

                }
            }.frame(height: 164)
            HStack {
                Label("Video", systemImage: "film").foregroundStyle(.secondary)
                Text("·")
                Label("Zooms", systemImage: "plus.magnifyingglass").foregroundStyle(StudioTheme.accent)
                Spacer()
                if let zoom = studio.project.zooms.first(where: { $0.id == studio.selectedZoom }) {
                    Text(String(format: "Zoom: %.2f – %.2f s", zoom.start, zoom.end)).monospacedDigit()
                } else {
                    Text("Kanten ziehen · Mitte verschieben").foregroundStyle(.secondary)
                }
            }.font(.system(size: 10))
            Text("Pfeile: 0,1 s · Umschalt + Pfeile: 0,5 s · Jede Zeile ist ein Zoom")
                .font(.system(size: 9)).foregroundStyle(.secondary)
        }
        .padding(22).frame(height: 278)
        .background(StudioTheme.panel)
        .disabled(studio.sourceURL == nil)
    }
}
