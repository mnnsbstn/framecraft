import SwiftUI
import AVKit
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var studio: StudioStore
    @ObservedObject var capture: CaptureService
    @ObservedObject var exporter: ExportService
    @State private var showRecording = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            HStack(spacing: 0) {
                sidebar
                Divider()
                VStack(spacing: 0) {
                    preview.disabled(capture.isRecording || capture.isPreparing || studio.isLoading)
                    Divider()
                    TimelineView(studio: studio)
                        .disabled(capture.isRecording || capture.isPreparing || studio.isLoading || exporter.isExporting)
                }
                Divider()
                InspectorView(studio: studio)
                    .frame(width: 270)
                    .disabled(studio.sourceURL == nil || exporter.isExporting || capture.isRecording || capture.isPreparing || studio.isLoading)
            }
            footer
        }
        .sheet(isPresented: $showRecording) { RecordingView(studio: studio, capture: capture) }
        .alert("FrameCraft", isPresented: Binding(get: { studio.message != nil || capture.errorMessage != nil || exporter.errorMessage != nil }, set: { if !$0 { studio.message = nil; capture.errorMessage = nil; exporter.clearError() } })) {
            Button("OK") { studio.message = nil; capture.errorMessage = nil; exporter.clearError() }
        } message: { Text(studio.message ?? capture.errorMessage ?? exporter.errorMessage ?? "") }
        .onAppear {
            capture.onFinished = { url, clicks, cursor in
                showRecording = false
                NSApp.activate(ignoringOtherApps: true)
                Task { await studio.loadVideo(url, clicks: clicks, cursor: cursor) }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "viewfinder").font(.system(size: 24, weight: .semibold)).foregroundStyle(.purple)
            VStack(alignment: .leading, spacing: 3) {
                Text("FrameCraft").font(.system(size: 17, weight: .bold, design: .rounded))
                Text("Dein Bildschirm. Deine Geschichte.").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if capture.isRecording {
                Label(timeLabel(capture.elapsed), systemImage: "record.circle.fill").foregroundStyle(.red).monospacedDigit()
                Button("Aufnahme beenden") { Task { await capture.stop() } }.tint(.red).buttonStyle(.borderedProminent)
            } else {
                Button { if studio.confirmReplace() { showRecording = true } } label: { Label("Aufnehmen", systemImage: "record.circle") }
                    .disabled(capture.isPreparing || exporter.isExporting || studio.isLoading)
            }
            Button { studio.saveProject() } label: { Image(systemName: "square.and.arrow.down") }.help("Projekt speichern · ⌘S").disabled(studio.sourceURL == nil || exporter.isExporting || studio.isLoading || capture.isRecording || capture.isPreparing)
            Button(action: exportMovie) { Label("Video exportieren", systemImage: "square.and.arrow.up") }
                .buttonStyle(.borderedProminent).disabled(studio.sourceURL == nil || exporter.isExporting || studio.isLoading || capture.isRecording || capture.isPreparing)
        }
        .padding(.horizontal, 22).padding(.vertical, 15)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("ARBEITSPLATZ").font(.system(size: 10, weight: .semibold)).tracking(1.6).foregroundStyle(.secondary)
            Label("Studio", systemImage: "rectangle.stack").font(.system(size: 13, weight: .semibold)).foregroundStyle(.purple)
            Button { studio.importVideo() } label: { Label("Video importieren", systemImage: "film") }
            Button { studio.openProject() } label: { Label("Projekt öffnen", systemImage: "folder") }
            Divider()
            Text("PROJEKT").font(.system(size: 10, weight: .semibold)).tracking(1.6).foregroundStyle(.secondary)
            if studio.sourceURL != nil {
                Label(studio.project.title, systemImage: "doc.richtext").lineLimit(2)
                Text(studio.saved ? "Gespeichert" : "Ungespeicherte Änderungen").font(.caption).foregroundStyle(.secondary)
                Text("\(timeLabel(studio.project.duration)) · Original").font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Alles beginnt mit einer Aufnahme.").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button { studio.makeDemo() } label: { Label("Demo ausprobieren", systemImage: "sparkles") }
            Text("Lokal auf deinem Mac").font(.caption2).foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain).font(.system(size: 12))
        .padding(20).frame(width: 185).frame(maxHeight: .infinity, alignment: .topLeading)
        .background(.bar)
        .disabled(exporter.isExporting || studio.isLoading || capture.isRecording || capture.isPreparing)
    }

    private var preview: some View {
        VStack(spacing: 12) {
            HStack {
                Text(studio.sourceURL == nil ? "VORSCHAU" : studio.project.title.uppercased()).font(.system(size: 10, weight: .semibold)).tracking(1.3).foregroundStyle(.secondary)
                Spacer()
                Text(studio.project.format.title).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 26).padding(.top, 22)
            ZStack {
                if studio.isLoading {
                    ProgressView("Video wird vorbereitet …").frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if studio.sourceURL != nil {
                    PlayerCanvas(player: studio.player)
                        .aspectRatio(studio.project.format.size.width / studio.project.format.size.height, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(26)
                } else {
                    welcome
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 18) {
                Button { studio.seek(studio.project.trimStart) } label: { Image(systemName: "backward.end.fill") }.help("Zum Anfang")
                Button { studio.togglePlayback() } label: { Image(systemName: studio.isPlaying ? "pause.fill" : "play.fill").font(.title3).frame(width: 34, height: 30) }.keyboardShortcut(.space, modifiers: [])
                Text("\(timeLabel(studio.currentTime)) / \(timeLabel(studio.project.duration))").font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
                Spacer()
                Button { studio.project.muted.toggle() } label: { Image(systemName: studio.project.muted ? "speaker.slash" : "speaker.wave.2") }.help("Ton umschalten")
            }
            .buttonStyle(.plain).disabled(studio.sourceURL == nil).padding(.horizontal, 28).padding(.bottom, 20)
        }
        .background(.background)
    }

    private var welcome: some View {
        VStack(spacing: 22) {
            ZStack {
                RoundedRectangle(cornerRadius: 28).fill(LinearGradient(colors: Backdrop.aurora.colors, startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 300, height: 180)
                RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial).frame(width: 236, height: 132).shadow(color: .black.opacity(0.25), radius: 18, y: 8)
                Image(systemName: "play.rectangle.fill").font(.system(size: 46)).foregroundStyle(.white.opacity(0.9))
            }
            VStack(spacing: 8) {
                Text("Mach aus einem Ablauf eine Geschichte.").font(.system(size: 21, weight: .semibold, design: .rounded)).multilineTextAlignment(.center)
                Text("Aufnehmen, die wichtigen Momente vergrößern\nund mit deinem eigenen Look exportieren.").font(.system(size: 13)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            HStack(spacing: 12) {
                Button("Neue Aufnahme") { showRecording = true }.buttonStyle(.borderedProminent)
                Button("Video importieren") { studio.importVideo() }.buttonStyle(.bordered)
            }
            Button("Erst mit einer Demo ausprobieren") { studio.makeDemo() }.buttonStyle(.link).font(.caption)
        }.padding(25)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Circle().fill(capture.isRecording ? Color.red : Color.green).frame(width: 5, height: 5)
                Text(capture.isRecording ? "Aufnahme läuft — Stop auch in der Menüleiste" : "Bereit")
                Spacer()
                if exporter.isExporting {
                    ProgressView(value: exporter.progress).frame(width: 140)
                    Text("Export \(Int(exporter.progress * 100)) %").monospacedDigit()
                    Button("Abbrechen") { exporter.cancel() }.buttonStyle(.link)
                } else {
                    Text("MP4 · 30 fps · lokal")
                        .help("FrameCraft \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–") · Build \(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "–")")
                }
            }.font(.system(size: 10)).foregroundStyle(.secondary).padding(.horizontal, 20).padding(.vertical, 9)
        }
    }

    private func exportMovie() {
        guard let source = studio.sourceURL else { return }
        studio.player.pause(); studio.isPlaying = false
        let panel = NSSavePanel(); panel.allowedContentTypes = [.mpeg4Movie]
        panel.nameFieldStringValue = studio.project.title + ".mp4"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let snapshot = studio.project
        Task {
            if await exporter.export(source: source, project: snapshot, destination: url) {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        }
    }
}
