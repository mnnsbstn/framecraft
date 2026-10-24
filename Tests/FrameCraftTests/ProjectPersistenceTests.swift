import XCTest
@testable import FrameCraft

final class ProjectPersistenceTests: XCTestCase {
    private func fixture() throws -> (URL, URL) {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("FrameCraft-project-tests-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let source = root.appendingPathComponent("original.mp4")
        try Data("untouched original media".utf8).write(to: source)
        return (root, source)
    }

    func testLargeCursorTrackRoundTripAndMetadataOnlyResave() async throws {
        let (root, source) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        var project = Project(duration: 3600, trimEnd: 3600)
        project.cursor = CursorTrack(samples: (0...216_000).map {
            CursorSample(time: Double($0) / 60, x: Double($0 % 100) / 100, y: 0.5)
        })
        let store = ProjectPersistence()
        let folder = root.appendingPathComponent("large.framecraft")
        let media = try await store.save(project: project, source: source, folder: folder)
        let loaded = try await store.read(folder: folder)
        XCTAssertEqual(loaded.project, project)
        XCTAssertEqual(try Data(contentsOf: media), try Data(contentsOf: source))
        project.title = "Updated metadata"
        _ = try await store.save(project: project, source: media, folder: folder)
        let updated = try await store.read(folder: folder)
        XCTAssertEqual(updated.project.title, project.title)
        XCTAssertEqual(Set(try FileManager.default.contentsOfDirectory(atPath: root.path)), ["original.mp4", "large.framecraft"])
    }

    func testFullDiskDuringNewSaveLeavesNoPartialProjectAndCanRetry() async throws {
        let (root, source) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appendingPathComponent("new.framecraft")
        let store = ProjectPersistence { _, _ in throw CocoaError(.fileWriteOutOfSpace) }
        do {
            _ = try await store.save(project: Project(), source: source, folder: folder)
            XCTFail("Expected storage failure")
        } catch {
            XCTAssertTrue(StorageFailure.message(for: error).contains("Speicherplatz"))
        }
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: root.path), ["original.mp4"])
        let media = try await ProjectPersistence().save(project: Project(), source: source, folder: folder)
        XCTAssertEqual(try Data(contentsOf: media), try Data(contentsOf: source))
    }

    func testFailedResavePreservesPreviouslySavedProject() async throws {
        let (root, source) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appendingPathComponent("saved.framecraft")
        let media = try await ProjectPersistence().save(project: Project(title: "Before"), source: source, folder: folder)
        let previous = try Data(contentsOf: folder.appendingPathComponent("project.json"))
        let failing = ProjectPersistence { _, _ in throw CocoaError(.fileWriteOutOfSpace) }
        do {
            _ = try await failing.save(project: Project(title: "After"), source: media, folder: folder)
            XCTFail("Expected storage failure")
        } catch {}
        XCTAssertEqual(try Data(contentsOf: folder.appendingPathComponent("project.json")), previous)
        XCTAssertEqual(try Data(contentsOf: media), try Data(contentsOf: source))
    }

    func testDestinationCreatedDuringSaveIsNotReplaced() async throws {
        let (root, source) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appendingPathComponent("race.framecraft")
        let sentinel = Data("other process owns this".utf8)
        let racing = ProjectPersistence { data, metadata in
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
            try sentinel.write(to: folder.appendingPathComponent("sentinel"))
            try data.write(to: metadata, options: .atomic)
        }
        do {
            _ = try await racing.save(project: Project(), source: source, folder: folder)
            XCTFail("Must not overwrite a competing destination")
        } catch {}
        XCTAssertEqual(try Data(contentsOf: folder.appendingPathComponent("sentinel")), sentinel)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: folder.path), ["sentinel"])
        XCTAssertEqual(Set(try FileManager.default.contentsOfDirectory(atPath: root.path)), ["original.mp4", "race.framecraft"])
    }

    @MainActor
    func testSavingDoesNotBlockMainActor() async throws {
        let (root, source) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        let started = expectation(description: "Worker started")
        let release = DispatchSemaphore(value: 0)
        let store = ProjectPersistence { data, target in
            started.fulfill()
            guard release.wait(timeout: .now() + 3) == .success else { throw CocoaError(.fileWriteUnknown) }
            try data.write(to: target, options: .atomic)
        }
        let job = Task { try await store.save(project: Project(), source: source, folder: root.appendingPathComponent("async.framecraft")) }
        await fulfillment(of: [started], timeout: 2)
        // Only a responsive MainActor can release the deliberately blocked writer.
        release.signal()
        _ = try await job.value
    }

    func testWrappedFullDiskErrorIsRecognized() {
        let inner = NSError(domain: NSPOSIXErrorDomain, code: Int(ENOSPC))
        let wrapped = NSError(domain: "AVFoundationErrorDomain", code: -11800, userInfo: [NSUnderlyingErrorKey: inner])
        XCTAssertTrue(StorageFailure.message(for: wrapped).contains("Speicherplatz"))
    }
}
