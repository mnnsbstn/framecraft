import XCTest
@testable import FrameCraft

final class ProjectTests: XCTestCase {
    func testZoomEntersAndLeavesSmoothly() {
        let region = ZoomRegion(start: 1, end: 4, scale: 2)
        XCTAssertEqual(region.strength(at: 0), 0)
        XCTAssertEqual(region.strength(at: 1), 0)
        XCTAssertEqual(region.strength(at: 2), 1)
        XCTAssertEqual(region.strength(at: 4), 0)
        XCTAssertGreaterThan(region.strength(at: 1.1), 0)
        XCTAssertLessThan(region.strength(at: 1.1), region.strength(at: 1.3))
    }
    func testAutoZoomsRespectTrimAndKeepManualEdits() {
        let manual = ZoomRegion(start: 3, end: 4)
        var project = Project(duration: 10, trimStart: 2, trimEnd: 8, zooms: [manual], clicks: [
            .init(time: 1, x: 0.2, y: 0.3), .init(time: 3, x: 0.4, y: 0.5),
            .init(time: 3.2, x: 0.4, y: 0.5), .init(time: 7.9, x: 0.8, y: 0.9)
        ])
        project.generateZooms()
        XCTAssertTrue(project.zooms.contains(where: { $0.id == manual.id }))
        let automatic = project.zooms.filter(\.automatic)
        XCTAssertEqual(automatic.count, 2)
        XCTAssertTrue(automatic.allSatisfy { $0.start >= 2 && $0.end <= 8 })
        project.generateZooms()
        XCTAssertEqual(project.zooms.count, 3)
    }
    func testProjectSerializationRetainsEditingData() throws {
        var project = Project(duration: 5, trimEnd: 5)
        project.format = .portrait
        project.zooms = [.init(start: 0.3, end: 3, scale: 2.4, x: 0.2, y: 0.9)]
        let copy = try JSONDecoder().decode(Project.self, from: JSONEncoder().encode(project))
        XCTAssertEqual(copy.zooms, project.zooms)
        XCTAssertEqual(copy.format, .portrait)
        XCTAssertEqual(copy.outputDuration, 5)
    }
}
