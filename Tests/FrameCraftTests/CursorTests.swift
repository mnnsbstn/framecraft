import XCTest
@testable import FrameCraft

final class CursorTests: XCTestCase {
    func testSmoothingReducesJitterAndPinsClicks() {
        let samples = (0...120).map { i in
            CursorSample(time: Double(i) / 60, x: 0.5 + (i.isMultiple(of: 2) ? 0.02 : -0.02), y: 0.5)
        }
        let click = ClickSample(time: 1, x: samples[60].x, y: 0.5)
        let smooth = CursorTrack(samples: samples).prepared(clicks: [click])
        let rawJitter = zip(samples[10..<40], samples[11..<41]).reduce(0.0) { $0 + abs($1.0.x - $1.1.x) }
        let smoothJitter = zip(smooth[10..<40], smooth[11..<41]).reduce(0.0) { $0 + abs($1.0.x - $1.1.x) }
        XCTAssertLessThan(smoothJitter, rawJitter / 4)
        XCTAssertEqual(CursorTrack.position(at: 1, samples: smooth)?.x, click.x)
        XCTAssertEqual(CursorTrack(samples: samples, smoothing: 0).prepared(clicks: []), samples)
    }

    func testCursorDoesNotBridgeHiddenIntervalsOrLongGaps() {
        let positions = [CursorSample(time: 0, x: 0.2, y: 0.2),
                         CursorSample(time: 0.02, x: 0.2, y: 0.2, visible: false),
                         CursorSample(time: 0.04, x: 0.8, y: 0.8),
                         CursorSample(time: 1, x: 0.9, y: 0.9)]
        XCTAssertNil(CursorTrack.position(at: -0.1, samples: positions))
        XCTAssertNil(CursorTrack.position(at: 0.03, samples: positions))
        XCTAssertNil(CursorTrack.position(at: 0.5, samples: positions))
        XCTAssertNil(CursorTrack.position(at: 2, samples: positions))
    }

    func testLegacyProjectLoadsWithoutInventingCursor() throws {
        var data = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(Project())) as? [String: Any])
        data.removeValue(forKey: "cursor")
        let project = try JSONDecoder().decode(Project.self, from: JSONSerialization.data(withJSONObject: data))
        XCTAssertNil(project.cursor)
    }

    func testCursorSettingsAndPositionsRoundTrip() throws {
        var project = Project(duration: 2, trimEnd: 2)
        project.cursor = CursorTrack(samples: [.init(time: 0, x: 0.2, y: 0.8), .init(time: 1, x: 0.8, y: 0.2)], smoothing: 0.2, size: 1.6)
        XCTAssertEqual(try JSONDecoder().decode(Project.self, from: JSONEncoder().encode(project)), project)
    }

    func testNearbyClicksExtendZoomAndDistantClicksRemain() {
        var project = Project(duration: 8, trimEnd: 8, clicks: [
            .init(time: 1, x: 0.2, y: 0.2), .init(time: 1.5, x: 0.22, y: 0.2), .init(time: 2, x: 0.8, y: 0.8)])
        project.generateZooms()
        XCTAssertEqual(project.zooms.count, 2)
        XCTAssertGreaterThan(project.zooms[0].end, 3)
        XCTAssertEqual(project.zooms[1].x, 0.8)
        for time in stride(from: 0.1, through: 5, by: 0.01) {
            let before = project.zoom(at: time - 0.001), after = project.zoom(at: time + 0.001)
            XCTAssertLessThan(abs(before.scale - after.scale), 0.03)
            if before.scale > 1.02 && after.scale > 1.02 { XCTAssertLessThan(abs(before.x - after.x), 0.03) }
        }
    }
}
