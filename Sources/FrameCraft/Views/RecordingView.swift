import SwiftUI

struct RecordingView: View {
    @ObservedObject var studio: StudioStore
    @ObservedObject var capture: CaptureService
    @Environment(\.dismiss) private var dismiss
    @State private var systemAudio = true
    @State private var microphone = false

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Image(systemName: "record.circle").font(.title).foregroundStyle(.purple)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Neue Aufnahme").font(.title2.bold())
                    Text("Wähle, was du zeigen möchtest.").foregroundStyle(.secondary)
                }
            }
            if capture.isRecording {
                HStack { Circle().fill(.red).frame(width: 10, height: 10); Text(timeLabel(capture.elapsed)).font(.system(size: 30, design: .monospaced)) }
                Text("Die Aufnahme läuft. Du kannst dieses Fenster ausblenden und jederzeit über die Menüleiste stoppen.").font(.callout).foregroundStyle(.secondary)
                HStack {
                    Button("Fenster ausblenden") { dismiss(); NSApp.hide(nil) }
                    Spacer()
                    Button("Aufnahme beenden") { Task { await capture.stop() } }.buttonStyle(.borderedProminent).tint(.red)
                }
            } else if capture.isPreparing {
                ProgressView("Aufnahme wird vorbereitet oder abgeschlossen …")
                Text("Bitte kurz warten. Die Videodatei wird erst nach vollständigem Abschluss geöffnet.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                if capture.isRefreshingSources { ProgressView("Aufnahmequellen werden geladen …") }
                if capture.needsScreenPermission {
                    Label("Bildschirmzugriff erforderlich", systemImage: "lock.rectangle")
                        .font(.headline)
                    Button("Systemeinstellungen öffnen") { capture.openScreenRecordingSettings() }
                }
                Picker("Quelle", selection: $capture.selectedID) {
                    Text("Bitte auswählen").tag(String?.none)
                    ForEach(capture.sources) { source in Text(source.title).tag(Optional(source.id)) }
                }
                .disabled(capture.isRefreshingSources || capture.needsScreenPermission)
                Toggle("Systemton aufnehmen", isOn: $systemAudio)
                Toggle("Mikrofon aufnehmen", isOn: $microphone)
                Text("Mausbewegungen und Klicks werden während der Aufnahme separat erfasst. Danach entstehen automatische Zooms und ein geglätteter Cursor. Es werden keine Tastatureingaben erfasst.")
                    .font(.caption).foregroundStyle(.secondary)
                if let message = capture.errorMessage { Text(message).font(.caption).foregroundStyle(.red).textSelection(.enabled) }
                HStack {
                    Button("Abbrechen") { dismiss() }.disabled(capture.isPreparing)
                    Button(capture.needsScreenPermission ? "Erneut prüfen" : "Aktualisieren") {
                        Task { await capture.refreshSources() }
                    }.disabled(capture.isRefreshingSources)
                    Spacer()
                    Button(capture.isPreparing ? "Wird gestartet …" : "Aufnahme starten") { start() }
                        .buttonStyle(.borderedProminent)
                        .disabled(capture.selectedID == nil || capture.isPreparing || capture.isRefreshingSources || capture.needsScreenPermission)
                }
            }
        }
        .padding(30).frame(width: 510)
        .interactiveDismissDisabled(capture.isPreparing)
        .task { await capture.refreshSources() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await capture.refreshSources() }
        }
    }

    private func start() {
        do {
            let folder = try studio.recordingsFolder()
            let stamp = Date().formatted(.iso8601).replacingOccurrences(of: ":", with: "-")
            let url = folder.appendingPathComponent("Aufnahme-\(stamp)-\(UUID().uuidString.prefix(4)).mp4")
            capture.captureSystemAudio = systemAudio; capture.captureMicrophone = microphone
            Task { await capture.start(to: url) }
        } catch { studio.message = error.localizedDescription }
    }
}
