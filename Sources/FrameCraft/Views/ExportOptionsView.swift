import SwiftUI

struct ExportOptionsView: View {
    let project: Project
    @Binding var settings: ExportSettings
    let onExport: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Export vorbereiten", systemImage: "square.and.arrow.up").font(.title2.bold())
            Picker("Dateiformat", selection: $settings.format) {
                ForEach(ExportSettings.Format.allCases) { Text($0.title).tag($0) }
            }.pickerStyle(.segmented)
            if settings.format == .mp4 {
                Picker("Auflösung", selection: $settings.resolution) {
                    ForEach(ExportSettings.Resolution.allCases) { Text($0.title).tag($0) }
                }
                Picker("Bildrate", selection: $settings.fps) { ForEach([24, 30, 60], id: \.self) { Text("\($0) fps").tag($0) } }
                Picker("Qualität", selection: $settings.quality) {
                    ForEach(ExportSettings.Quality.allCases) { Text($0.title).tag($0) }
                }
                Text("Höhere Qualität braucht mehr Speicher. Höhere Auflösung oder Bildrate fügt der Aufnahme keine neuen Details hinzu.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Picker("Lange Kante", selection: $settings.gifLongEdge) { ForEach([480, 720], id: \.self) { Text("\($0) Pixel").tag($0) } }
                Picker("Bildrate", selection: $settings.gifFPS) { ForEach([10, 20], id: \.self) { Text("\($0) fps").tag($0) } }
                Label("GIF ist ohne Ton und wiederholt sich endlos.", systemImage: "speaker.slash")
                    .font(.callout).foregroundStyle(StudioTheme.accent)
                Text("Bis zu 10 Sekunden und 720 Pixel. GIF hat begrenzte Farben und kann deutlich größer als MP4 sein.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Divider()
            let size = settings.size(for: project.format)
            Text("\(Int(size.width)) × \(Int(size.height)) Pixel · \(settings.frameRate) fps · \(timeLabel(project.outputDuration))")
                .font(.callout.monospacedDigit())
            if let bytes = settings.estimatedBytes(duration: project.outputDuration, canvas: project.format) {
                Text("Richtwert: etwa \(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)). Die tatsächliche Größe hängt vom Inhalt ab.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let error = settings.validationMessage(duration: project.outputDuration) {
                Text(error).font(.callout).foregroundStyle(.orange)
            }
            HStack {
                Button("Abbrechen") { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Speicherort wählen …", action: onExport).studioPrimaryAction()
                    .disabled(settings.validationMessage(duration: project.outputDuration) != nil)
            }
        }
        .padding(28).frame(width: 470)
        .background(StudioTheme.panel).preferredColorScheme(.dark).tint(StudioTheme.accent)
    }
}
