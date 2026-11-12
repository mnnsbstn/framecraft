import SwiftUI

struct CaptionEditor: View {
    @ObservedObject var studio: StudioStore
    @Environment(\.dismiss) private var dismiss
    @State private var cues: [Caption]
    @State private var style: CaptionStyle
    @State private var error: String?
    let original: Project
    let sourceID: UUID?
    let position: Double

    init(studio: StudioStore) {
        self.studio = studio
        let project = studio.project
        if let list = project.cuts, let i = list.index(at: studio.currentTime),
           let source = list.sources.first(where: { $0.id == list.segments[i].sourceID }) {
            original = source.project
            sourceID = source.id
            position = list.segments[i].start + studio.currentTime - list.start(of: i)
        } else {
            original = project
            sourceID = nil
            position = studio.currentTime
        }
        _cues = State(initialValue: original.captions ?? [])
        _style = State(initialValue: original.captionStyle ?? .standard)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Untertitel · " + original.title).font(.headline)
            Text("Die Zeiten beziehen sich auf das Originalvideo. Beim Schneiden wandern die Untertitel mit.").font(.caption)
            HStack {
                Text("Text")
                Spacer()
                Text("Von (s)").frame(width: 62)
                Text("Bis (s)").frame(width: 62)
                Color.clear.frame(width: 26, height: 1)
            }.font(.caption).foregroundStyle(.secondary)
            Picker("Darstellung", selection: $style) {
                ForEach(CaptionStyle.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            ScrollView {
                VStack(spacing: 12) {
                    ForEach($cues) { $cue in
                        HStack {
                            TextField("Text", text: $cue.text, axis: .vertical)
                            TextField("Von (s)", value: $cue.start, format: .number).frame(width: 62).help("Start in Sekunden")
                            TextField("Bis (s)", value: $cue.end, format: .number).frame(width: 62).help("Ende in Sekunden")
                            Button { cues.removeAll { $0.id == cue.id } } label: { Image(systemName: "trash") }
                        }
                    }
                }
            }.frame(minHeight: 160)
            if let error { Text(error).foregroundStyle(.red).font(.caption) }
            HStack {
                Button("Untertitel an Abspielposition") {
                    let start = min(max(0, position), max(0, original.duration - 0.1))
                    cues.append(Caption(start: start, end: min(original.duration, start + 2), text: ""))
                }
                Spacer()
                Button("Abbrechen") { dismiss() }
                Button("Übernehmen") { commit() }.keyboardShortcut(.defaultAction)
            }
        }.padding(20).frame(width: 640)
    }

    private func commit() {
        var edited = original
        edited.captions = cues.isEmpty ? nil : cues.sorted { $0.start < $1.start }
        edited.captionStyle = cues.isEmpty ? nil : style
        edited.version = edited.requiredVersion
        guard edited.validCaptions else {
            error = "Jeder Untertitel braucht 1–300 Zeichen und einen eigenen Zeitraum innerhalb der Videodauer. Prüfe Anfang, Ende und Überschneidungen."
            return
        }
        if edited != original {
            studio.rememberEdit()
            if let sourceID, var list = studio.project.cuts, let i = list.sources.firstIndex(where: { $0.id == sourceID }) {
                list.sources[i].project = edited
                studio.project.cuts = list
            } else { studio.project = edited }
        }
        dismiss()
    }
}
