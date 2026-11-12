import SwiftUI

struct InspectorView: View {
    @ObservedObject var studio: StudioStore
    @State private var tab = 0
    var body: some View {
        VStack(spacing: 0) {
            Picker("Einstellungen", selection: $tab) {
                Text("Gestaltung").tag(0); Text("Zoom & Schnitt").tag(1)
            }.pickerStyle(.segmented).labelsHidden().padding(16)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if tab == 0 { appearance } else { edits }
                }.padding(.horizontal, 19).padding(.bottom, 24)
            }
        }.background(StudioTheme.panel)
        .onChange(of: studio.selectedZoom) { _, value in if value != nil { tab = 1 } }
    }

    private var appearance: some View {
        Group {
            group("FORMAT") {
                Picker("Seitenverhältnis", selection: $studio.project.format) {
                    ForEach(CanvasFormat.allCases) { Text($0.title).tag($0) }
                }.pickerStyle(.segmented).labelsHidden()
            }
            group("HINTERGRUND") {
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 10) {
                    ForEach(Backdrop.allCases) { backdrop in
                        Button { studio.project.backdrop = backdrop } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(colors: backdrop.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(height: 53)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(studio.project.backdrop == backdrop ? StudioTheme.accent : Color.clear, lineWidth: 3))
                                Text(backdrop.title).font(.caption2).foregroundStyle(.secondary)
                            }
                        }.buttonStyle(.plain)
                    }
                }
            }
            group("RAHMEN") {
                valueSlider("Abstand", value: $studio.project.padding, range: 0...0.2, valueText: "\(Int(studio.project.padding * 100)) %")
                valueSlider("Ecken", value: $studio.project.cornerRadius, range: 0...60, valueText: "\(Int(studio.project.cornerRadius)) px")
                Text("Ein weicher Schatten gibt deinem Video Tiefe.").font(.caption2).foregroundStyle(.secondary)
            }
            group("CURSOR") {
                if studio.project.cursor != nil {
                    Toggle("Cursor anzeigen", isOn: cursorBinding(\.enabled, default: true))
                    valueSlider("Glättung", value: cursorBinding(\.smoothing, default: 0.12), range: 0...0.25,
                                valueText: "\(Int((studio.project.cursor?.smoothing ?? 0) * 1000)) ms")
                    valueSlider("Größe", value: cursorBinding(\.size, default: 1.2), range: 0.5...2.5,
                                valueText: String(format: "%.1f×", studio.project.cursor?.size ?? 1.2))
                    Toggle("Klicks hervorheben", isOn: cursorBinding(\.highlightClicks, default: true))
                    Text("\(studio.project.clicks.count) Klicks · separate Mausspur").font(.caption2).foregroundStyle(.secondary)
                } else {
                    Text("Dieses Video enthält keine separat bearbeitbare Mausspur.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            if let webcam = studio.project.webcam {
                group("WEBCAM") {
                    Toggle("Webcam anzeigen", isOn: webcamBinding(\.enabled, fallback: webcam.enabled))
                    Picker("Position", selection: webcamBinding(\.corner, fallback: webcam.corner)) {
                        ForEach(WebcamOverlay.Corner.allCases, id: \.self) { corner in Text(corner.title).tag(corner) }
                    }.disabled(!webcam.enabled)
                    valueSlider("Größe", value: webcamBinding(\.size, fallback: webcam.size), range: 0.12...0.45,
                                valueText: "\(Int(webcam.size * 100)) %").disabled(!webcam.enabled)
                }
            }
            group("TON") {
                Toggle("Originalton stummschalten", isOn: $studio.project.muted).font(.caption)
            }
            group("PROJEKTNAME") { TextField("Name", text: $studio.project.title).textFieldStyle(.roundedBorder) }
        }
    }

    private var edits: some View {
        Group {
            group("SCHNITT") {
                Text("Anfang und Ende bleiben im Original erhalten.").font(.caption2).foregroundStyle(.secondary)
                valueSlider("Anfang", value: Binding(get: { studio.project.trimStart }, set: { studio.project.trimStart = min($0, studio.project.trimEnd - min(0.1, studio.project.duration)) }), range: 0...max(0.0001, studio.project.duration), valueText: timeLabel(studio.project.trimStart))
                valueSlider("Ende", value: Binding(get: { studio.project.trimEnd }, set: { studio.project.trimEnd = max($0, studio.project.trimStart + min(0.1, studio.project.duration)) }), range: 0...max(0.0001, studio.project.duration), valueText: timeLabel(studio.project.trimEnd))
            }
            group("ZOOMS") {
                Button { studio.addZoom() } label: { Label("Zoom an Abspielposition", systemImage: "plus") }.controlSize(.small)
                if let zoom = studio.project.zooms.first(where: { $0.id == studio.selectedZoom }) {
                    zoomControls(zoom)
                } else {
                    Text("Wähle einen Zoom in der Zeitleiste oder füge einen neuen hinzu.").font(.caption).foregroundStyle(.secondary)
                }
                Divider()
                Button("Zooms aus Klicks erzeugen") { studio.project.generateZooms(); studio.selectedZoom = studio.project.zooms.first?.id }
                    .controlSize(.small).disabled(studio.project.clicks.isEmpty)
                Text(studio.project.clicks.isEmpty ? "Keine Klickdaten vorhanden. Für importierte Videos kannst du manuelle Zooms setzen." : "\(studio.project.clicks.count) Klicks aufgezeichnet. Automatische Zooms lassen sich hier bearbeiten.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private func zoomControls(_ zoom: ZoomRegion) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            valueSlider("Stärke", value: zoomBinding(zoom, \.scale), range: 1...3, valueText: String(format: "%.1f×", zoom.scale))
            valueSlider("Start", value: zoomBinding(zoom, \.start), range: 0...max(0.0001, studio.project.duration), valueText: timeLabel(zoom.start))
            valueSlider("Ende", value: zoomBinding(zoom, \.end), range: 0...max(0.0001, studio.project.duration), valueText: timeLabel(zoom.end))
            Text("FOKUSPUNKT").font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
            valueSlider("Horizontal", value: zoomBinding(zoom, \.x), range: 0...1, valueText: "\(Int(zoom.x * 100)) %")
            valueSlider("Vertikal", value: zoomBinding(zoom, \.y), range: 0...1, valueText: "\(Int(zoom.y * 100)) %")
            Button(role: .destructive) {
                if studio.selectedZoom == zoom.id { studio.selectedZoom = nil }
                studio.project.zooms.removeAll { $0.id == zoom.id }
            } label: { Label("Zoom entfernen", systemImage: "trash") }.controlSize(.small)
        }
    }

    private func webcamBinding<T>(_ key: WritableKeyPath<WebcamOverlay, T>, fallback: T) -> Binding<T> {
        Binding(get: { studio.project.webcam?[keyPath: key] ?? fallback }, set: { studio.project.webcam?[keyPath: key] = $0 })
    }

    private func cursorBinding<T>(_ keyPath: WritableKeyPath<CursorTrack, T>, default value: T) -> Binding<T> {
        Binding(get: { studio.project.cursor?[keyPath: keyPath] ?? value }, set: { studio.project.cursor?[keyPath: keyPath] = $0 })
    }

    func zoomBinding(_ zoom: ZoomRegion, _ keyPath: WritableKeyPath<ZoomRegion, Double>) -> Binding<Double> {
        Binding(get: {
            let current = studio.project.zooms.first { $0.id == zoom.id } ?? zoom
            return current[keyPath: keyPath]
        }, set: { value in
            guard let index = studio.project.zooms.firstIndex(where: { $0.id == zoom.id }) else { return }
            var current = studio.project.zooms[index]
            switch keyPath {
            case \.start: current.start = min(value, current.end - 0.1)
            case \.end: current.end = max(value, current.start + 0.1)
            default: current[keyPath: keyPath] = value
            }
            current.automatic = false
            studio.project.zooms[index] = current
        })
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.system(size: 10, weight: .semibold)).tracking(1.3).foregroundStyle(.secondary)
            content()
        }
    }
    private func valueSlider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, valueText: String) -> some View {
        VStack(spacing: 5) {
            HStack { Text(title); Spacer(); Text(valueText).monospacedDigit().foregroundStyle(.secondary) }.font(.system(size: 11))
            Slider(value: value, in: range).controlSize(.small)
        }
    }
}
