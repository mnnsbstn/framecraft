import XCTest
@testable import FrameCraft

final class ZoomTimingTests: XCTestCase {
    private let original = ZoomRegion(start: 2, end: 4, scale: 2.2, x: 0.3, y: 0.7, automatic: true)

    func testMovingClampsAtBothEdgesWithoutChangingLengthOrFocus() {
        for (delta, start, end) in [(-10.0, 0.0, 2.0), (10.0, 8.0, 10.0), (0.5, 2.5, 4.5)] {
            let result = ZoomTiming.edited(original, part: .move, delta: delta, duration: 10)
            XCTAssertEqual(result.start, start, accuracy: 1e-9)
            XCTAssertEqual(result.end, end, accuracy: 1e-9)
            XCTAssertEqual(result.id, original.id)
            XCTAssertEqual(result.scale, original.scale)
            XCTAssertEqual(result.x, original.x); XCTAssertEqual(result.y, original.y)
            XCTAssertFalse(result.automatic)
        }
    }

    func testResizingCannotCrossOtherEdgeOrVideoBoundary() {
        let start = ZoomTiming.edited(original, part: .start, delta: 20, duration: 10)
        XCTAssertEqual(start.start, 3.9, accuracy: 1e-9); XCTAssertEqual(start.end, 4)
        let end = ZoomTiming.edited(original, part: .end, delta: -20, duration: 10)
        XCTAssertEqual(end.end, 2.1, accuracy: 1e-9); XCTAssertEqual(end.start, 2)
        XCTAssertEqual(ZoomTiming.edited(original, part: .start, delta: -20, duration: 10).start, 0)
        XCTAssertEqual(ZoomTiming.edited(original, part: .end, delta: 20, duration: 10).end, 10)
    }

    func testInvalidInputAndNoOpPreserveAutomaticStatus() {
        for delta in [Double.nan, .infinity, -.infinity, 0] {
            XCTAssertEqual(ZoomTiming.edited(original, part: .move, delta: delta, duration: 10), original)
        }
        for duration in [Double.nan, .infinity, 0, -1, 3] {
            XCTAssertEqual(ZoomTiming.edited(original, part: .end, delta: 1, duration: duration), original)
        }
        let atEdge = ZoomRegion(start: 0, end: 2, automatic: true)
        XCTAssertEqual(ZoomTiming.edited(atEdge, part: .move, delta: -1, duration: 10), atEdge)
    }

    func testRepeatedGestureSamplesUseOriginalSnapshot() {
        _ = ZoomTiming.edited(original, part: .move, delta: 1, duration: 10)
        let later = ZoomTiming.edited(original, part: .move, delta: 1.5, duration: 10)
        XCTAssertEqual(later.start, 3.5); XCTAssertEqual(later.end, 5.5)
    }

    func testShortExistingIntervalsRemainValid() {
        let short = ZoomRegion(start: 0, end: 0.05, automatic: true)
        XCTAssertEqual(ZoomTiming.edited(short, part: .end, delta: -1, duration: 0.05), short)
        let extended = ZoomTiming.edited(short, part: .end, delta: 0.2, duration: 1)
        XCTAssertEqual(extended.end, 0.25, accuracy: 1e-9)
    }

    func testOverlapRemainsEditableAndManualTimingSurvivesRegenerationAndRoundTrip() throws {
        let edited = ZoomTiming.edited(original, part: .move, delta: 0.1, duration: 10)
        var project = Project(duration: 10, trimEnd: 10, zooms: [edited], clicks: [.init(time: 3, x: 0.5, y: 0.5)])
        project.generateZooms()
        XCTAssertEqual(project.zooms.first(where: { $0.id == edited.id }), edited)
        XCTAssertEqual(project.zooms.count, 2)
        XCTAssertTrue(project.zooms[1].start < edited.end && project.zooms[1].end > edited.start)
        project.generateZooms()
        XCTAssertEqual(project.zooms.count, 2)
        let decoded = try JSONDecoder().decode(Project.self, from: JSONEncoder().encode(project))
        XCTAssertEqual(decoded.zooms, project.zooms)
        let camera = decoded.zoom(at: 3)
        XCTAssertTrue(camera.scale.isFinite && camera.x.isFinite && camera.y.isFinite)
    }
}
