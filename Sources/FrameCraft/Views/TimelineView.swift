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
                        RoundedRectangle(cornerRadius: 5).fill(.purple.opacity(0.1))
                        RoundedRectangle(cornerRadius: 5).fill(.purple.opacity(0.28))
                            .frame(width: max(1, width * studio.project.outputDuration / duration))
                            .offset(x: width * studio.project.trimStart / duration)
                        Label("Originalvideo", systemImage: "film")
                            .font(.system(size: 10, weight: .medium)).foregroundStyle(.purple)
                            .padding(.horizontal, 12).allowsHitTesting(false)
                        Rectangle().fill(.primary).frame(width: 1.5).offset(x: min(width - 1, width * studio.currentTime / duration))
                    }
                    .frame(height: 42)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0).onChanged { studio.seek(min(1, max(0, $0.location.x / width)) * duration) })
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5).fill(.quaternary.opacity(0.5))
                        ForEach(studio.project.zooms) { zoom in
                            Button {
                                studio.selectedZoom = zoom.id
                                studio.seek((zoom.start + zoom.end) / 2)
                            } label: {
                                HStack(spacing: 4) { Image(systemName: "plus.magnifyingglass"); Text(String(format: "%.1f×", zoom.scale)) }
                                    .font(.system(size: 9, weight: .medium)).lineLimit(1)
                                    .frame(width: max(22, width * (zoom.end - zoom.start) / duration), height: 25)
                                    .background(studio.selectedZoom == zoom.id ? Color.purple : Color.purple.opacity(0.4), in: RoundedRectangle(cornerRadius: 4))
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain).offset(x: width * zoom.start / duration)
                        }
                    }.frame(height: 28).clipped()
                }
            }.frame(height: 104)
            HStack {
                Label("Video", systemImage: "film").foregroundStyle(.secondary)
                Text("·")
                Label("Zooms", systemImage: "plus.magnifyingglass").foregroundStyle(.purple)
                Spacer()
                Text("Auswahl: \(timeLabel(studio.project.outputDuration))").monospacedDigit().foregroundStyle(.secondary)
            }.font(.system(size: 10))
        }
        .padding(22).frame(height: 206)
        .disabled(studio.sourceURL == nil)
    }
}
