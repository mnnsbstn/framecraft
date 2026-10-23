import SwiftUI
import AppKit

@main
struct FrameCraftApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var studio = StudioStore()
    @StateObject private var capture = CaptureService()
    @StateObject private var exporter = ExportService()

    private var busy: Bool { capture.isRecording || capture.isPreparing || exporter.isExporting || studio.isLoading }

    var body: some Scene {
        WindowGroup("FrameCraft", id: "studio") {
            ContentView(studio: studio, capture: capture, exporter: exporter)
                .frame(minWidth: 1080, minHeight: 700)
                .tint(.purple)
                .onAppear {
                    delegate.shouldPreventQuit = { capture.isRecording || capture.isPreparing || exporter.isExporting || studio.isLoading }
                    delegate.hasUnsavedEdits = { studio.sourceURL != nil && !studio.saved }
                }
        }
        .defaultSize(width: 1360, height: 860)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Video importieren …") { studio.importVideo() }.keyboardShortcut("i").disabled(busy)
                Button("Projekt öffnen …") { studio.openProject() }.keyboardShortcut("o").disabled(busy)
                Divider()
                Button("Projekt speichern") { studio.saveProject() }.keyboardShortcut("s").disabled(studio.sourceURL == nil || busy)
                Button("Projekt speichern unter …") { studio.saveProject(asNew: true) }.keyboardShortcut("s", modifiers: [.command, .shift]).disabled(studio.sourceURL == nil || busy)
            }
            CommandMenu("Wiedergabe") {
                Button(studio.isPlaying ? "Pause" : "Abspielen") { studio.togglePlayback() }.keyboardShortcut(.space, modifiers: []).disabled(busy)
                Button("Zoom hinzufügen") { studio.addZoom() }.keyboardShortcut("z", modifiers: [.command, .shift]).disabled(studio.sourceURL == nil || busy)
            }
        }
        MenuBarExtra(capture.isRecording ? "Aufnahme läuft" : "FrameCraft", systemImage: capture.isRecording ? "record.circle.fill" : "rectangle.inset.filled.and.person.filled") {
            if capture.isRecording {
                Text("Aufnahme · \(timeLabel(capture.elapsed))")
                Button("Aufnahme beenden") { Task { await capture.stop() } }
            } else { Text("FrameCraft ist bereit") }
            Button("Fenster anzeigen") { NSApp.activate(ignoringOtherApps: true); NSApp.windows.first(where: { $0.title == "FrameCraft" })?.makeKeyAndOrderFront(nil) }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    var shouldPreventQuit: () -> Bool = { false }
    var hasUnsavedEdits: () -> Bool = { false }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if shouldPreventQuit() {
            let alert = NSAlert()
            alert.messageText = "Ein Vorgang läuft noch."
            alert.informativeText = "Beende die Aufnahme oder warte auf den Export, bevor du FrameCraft schließt."
            alert.addButton(withTitle: "Zurück")
            alert.runModal()
            return .terminateCancel
        }
        guard hasUnsavedEdits() else { return .terminateNow }
        let alert = NSAlert()
        alert.messageText = "Ungespeicherte Bearbeitungen verwerfen?"
        alert.informativeText = "Das Originalvideo bleibt erhalten. Speichere das Projekt, um deine Bearbeitungen zu behalten."
        alert.addButton(withTitle: "Zurück"); alert.addButton(withTitle: "Verwerfen und beenden")
        return alert.runModal() == .alertSecondButtonReturn ? .terminateNow : .terminateCancel
    }
}
