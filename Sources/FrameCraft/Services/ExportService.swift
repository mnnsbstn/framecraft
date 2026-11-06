import Combine
import Foundation

@MainActor
final class ExportService: ObservableObject {
    @Published private(set) var isExporting = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var errorMessage: String?
    private var activeTask: Task<Void, Error>?
    private var cancelled = false

    func clearError() { errorMessage = nil }
    func cancel() { cancelled = true; activeTask?.cancel() }

    func export(source: URL, project: Project, destination: URL, settings: ExportSettings = ExportSettings()) async -> Bool {
        guard !isExporting else { return false }
        isExporting = true; progress = 0; errorMessage = nil; cancelled = false
        let temporaryDirectory = destination.deletingLastPathComponent()
            .appendingPathComponent(".framecraft-\(UUID().uuidString)", isDirectory: true)
        let temporary = temporaryDirectory.appendingPathComponent("export.\(settings.fileExtension)")
        defer {
            activeTask = nil; isExporting = false
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
        do {
            guard source.isFileURL, destination.isFileURL,
                  source.resolvingSymlinksInPath().standardizedFileURL != destination.resolvingSymlinksInPath().standardizedFileURL,
                  !FileManager.default.fileExists(atPath: destination.path) else { throw RenderError.destinationExists }
            if let message = settings.validationMessage(duration: project.outputDuration) { throw RenderError.failed(message) }
            try Task.checkCancellation()
            try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: false)
            let reportProgress: @Sendable (Double) async -> Void = { [weak self] value in
                await self?.setProgress(value)
            }
            let operation = Task.detached(priority: .userInitiated) {
                try await MediaExportWorker.write(source: source, project: project, settings: settings,
                                                  destination: temporary, progress: reportProgress)
            }
            activeTask = operation
            try await withTaskCancellationHandler { try await operation.value } onCancel: { operation.cancel() }
            guard !cancelled else { throw CancellationError() }
            try Task.checkCancellation()
            // A competing destination created while encoding must never be replaced.
            try FileManager.default.moveItem(at: temporary, to: destination)
            progress = 1
            return true
        } catch is CancellationError {
            return false
        } catch {
            errorMessage = cancelled || Task.isCancelled ? nil : StorageFailure.message(for: error)
            return false
        }
    }
    private func setProgress(_ value: Double) { progress = min(0.99, max(progress, value)) }
}
