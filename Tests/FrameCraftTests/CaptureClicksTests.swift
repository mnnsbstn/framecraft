import XCTest
@testable import FrameCraft

final class CaptureClicksTests: XCTestCase {
    func testLatePollsDoNotMoveFocusOrDuplicateRealClicks() {
        var log = CaptureClicks()
        let a = CursorSample(time: 1, x: 0.22, y: 0.26)
        let moved = CursorSample(time: 1.42, x: 0.62, y: 0.50)
        let b = CursorSample(time: 2.6, x: 0.52, y: 0.48)
        log.observeCounter(moved)
        log.observeNative(a)
        log.observeNative(b)
        log.observeCounter(moved)
        var project = Project(duration: 5, trimEnd: 5, clicks: log.resolved)
        project.generateZooms()
        XCTAssertEqual(project.clicks.map(\.time), [a.time, b.time])
        XCTAssertEqual(project.zooms.map(\.x), [a.x, b.x])
    }

    func testOffSourceNativeClickSuppressesCounterAfterReentry() {
        var log = CaptureClicks()
        let reentry = CursorSample(time: 2.3, x: 0.02, y: 0.64)
        log.observeCounter(reentry)
        log.observeNative(CursorSample(time: 2, x: 1, y: 0.64, visible: false))
        log.observeCounter(reentry)
        XCTAssertTrue(log.resolved.isEmpty)
    }

    func testVisibleCounterFallbackWhenNoNativeEventsArrive() {
        var log = CaptureClicks()
        log.observeCounter(CursorSample(time: 1, x: 0.2, y: 0.4))
        log.observeCounter(CursorSample(time: 2, x: 1, y: 0.4, visible: false))
        XCTAssertEqual(log.resolved, [ClickSample(time: 1, x: 0.2, y: 0.4)])
    }
}
