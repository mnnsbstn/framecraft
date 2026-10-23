import XCTest
@testable import FrameCraft

final class CameraPathTests: XCTestCase {
    func testLaterTargetDoesNotReboundToOlderOverlappingRegion() {
        let project = Project(duration: 8, trimEnd: 8, zooms: [
            .init(start: 1, end: 7, scale: 2, x: 0.25, y: 0.5, automatic: true),
            .init(start: 2, end: 4, scale: 2, x: 0.75, y: 0.5, automatic: true)])
        let path = CameraPath(project: project)
        var last = path.zoom(at: 2).x
        for time in stride(from: 2.0, through: 6.3, by: 1.0 / 120) {
            let pose = path.zoom(at: time)
            XCTAssertGreaterThanOrEqual(pose.x + 1e-10, last)
            XCTAssertEqual(pose.scale, 2, accuracy: 1e-9)
            last = pose.x
        }
        XCTAssertEqual(path.zoom(at: 5).x, 0.75, accuracy: 1e-9)
        XCTAssertEqual(path.zoom(at: 7).scale, 1, accuracy: 1e-9)
    }

    func testRapidRetargetingKeepsPositionAndVelocityContinuousAndCropInBounds() {
        let regions = (0..<16).map { i in
            ZoomRegion(start: 1 + Double(i) * 0.09, end: 4 + Double(i) * 0.09,
                       scale: i.isMultiple(of: 2) ? 2 : 2.4,
                       x: i.isMultiple(of: 2) ? 0 : 1,
                       y: i.isMultiple(of: 2) ? 1 : 0, automatic: true)
        }
        let path = CameraPath(project: Project(duration: 7, trimEnd: 7, zooms: regions))
        for region in regions {
            let t = region.start, h = 0.0001
            let a = path.zoom(at: t - h), b = path.zoom(at: t), c = path.zoom(at: t + h)
            XCTAssertEqual((b.x - a.x) / h, (c.x - b.x) / h, accuracy: 0.003)
            XCTAssertEqual((b.scale - a.scale) / h, (c.scale - b.scale) / h, accuracy: 0.015)
        }
        for t in stride(from: 0.0, through: 7, by: 1.0 / 120) {
            let p = path.zoom(at: t), half = 0.5 / p.scale
            XCTAssertGreaterThanOrEqual(p.x + 1e-9, half)
            XCTAssertLessThanOrEqual(p.x, 1 - half + 1e-9)
            XCTAssertGreaterThanOrEqual(p.y + 1e-9, half)
            XCTAssertLessThanOrEqual(p.y, 1 - half + 1e-9)
            let next = path.zoom(at: t + 1.0 / 60)
            XCTAssertLessThan(abs(next.x - p.x), 0.04)
        }
    }

    func testShortPauseStaysZoomedAndManualOverrideResumesLatestAutomaticTarget() {
        let path = CameraPath(project: Project(duration: 8, trimEnd: 8, zooms: [
            .init(start: 0, end: 2, scale: 2, x: 0.3, automatic: true),
            .init(start: 2.2, end: 7, scale: 2, x: 0.7, automatic: true),
            .init(start: 3, end: 5, scale: 3, x: 0.5)]))
        XCTAssertEqual(path.zoom(at: 2.1).scale, 2, accuracy: 1e-9)
        XCTAssertEqual(path.zoom(at: 4).scale, 3, accuracy: 1e-9)
        XCTAssertEqual(path.zoom(at: 4).x, 0.5, accuracy: 1e-9)
        XCTAssertEqual(path.zoom(at: 5.5).x, 0.7, accuracy: 1e-9)
        let later = path.zoom(at: 5.5)
        _ = path.zoom(at: 1.2)
        XCTAssertEqual(path.zoom(at: 5.5).x, later.x)
        XCTAssertEqual(path.zoom(at: 7).scale, 1, accuracy: 1e-9)
    }

    func testShortZoomIsNotDropped() {
        let path = CameraPath(project: Project(duration: 1, trimEnd: 1, zooms: [
            .init(start: 0, end: 0.3, scale: 2, automatic: true)]))
        XCTAssertGreaterThan(path.zoom(at: 0.25).scale, 1.05)
        XCTAssertEqual(path.zoom(at: 1).scale, 1, accuracy: 1e-9)
    }
}
