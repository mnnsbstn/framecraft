import XCTest
import ScreenCaptureKit
@testable import FrameCraft

final class CaptureAccessTests: XCTestCase {
    @MainActor
    func testDeniedAccessClearsStaleSourcesAndSelection() async {
        let service = CaptureService {
            throw NSError(domain: SCStreamErrorDomain, code: SCStreamError.Code.userDeclined.rawValue)
        }
        service.sources = [.init(id: "stale", title: "Old source", kind: .window, display: nil, window: nil)]
        service.selectedID = "stale"
        await service.refreshSources()
        XCTAssertTrue(service.needsScreenPermission)
        XCTAssertTrue(service.sources.isEmpty)
        XCTAssertNil(service.selectedID)
        XCTAssertFalse(service.isRefreshingSources)
        await service.start(to: URL(fileURLWithPath: "/tmp/framecraft-access-test-unused.mp4"))
        XCTAssertFalse(service.isRecording)
        XCTAssertFalse(service.isPreparing)
    }

    @MainActor
    func testOtherFailuresAreNotMisreportedAsPermissionDenials() async {
        var calls = 0
        let service = CaptureService {
            calls += 1
            throw NSError(domain: calls == 1 ? SCStreamErrorDomain : "FrameCraftTest",
                          code: SCStreamError.Code.userDeclined.rawValue)
        }
        await service.refreshSources()
        XCTAssertTrue(service.needsScreenPermission)
        await service.refreshSources()
        XCTAssertFalse(service.needsScreenPermission)
        XCTAssertTrue(service.errorMessage?.contains("Versuche es erneut") == true)
        XCTAssertEqual(calls, 2)
    }

    @MainActor
    func testConcurrentRefreshDoesNotStartASecondRequestOrRecording() async {
        var calls = 0
        var pending: CheckedContinuation<SCShareableContent, Error>?
        let service = CaptureService {
            calls += 1
            return try await withCheckedThrowingContinuation { pending = $0 }
        }
        let refresh = Task { await service.refreshSources() }
        while pending == nil { await Task.yield() }
        XCTAssertTrue(service.isRefreshingSources)
        await service.refreshSources()
        await service.start(to: URL(fileURLWithPath: "/tmp/framecraft-access-test-unused.mp4"))
        XCTAssertEqual(calls, 1)
        XCTAssertFalse(service.isPreparing)
        pending?.resume(throwing: NSError(domain: SCStreamErrorDomain, code: SCStreamError.Code.userDeclined.rawValue))
        await refresh.value
        XCTAssertFalse(service.isRefreshingSources)
        XCTAssertTrue(service.needsScreenPermission)
    }
}
