import XCTest
@testable import FrameCraft

final class ZoomInspectorTests: XCTestCase {
    @MainActor func testBindingSurvivesReorderRemovalAndProjectReplacement() {
        let studio = StudioStore()
        let a = ZoomRegion(start: 1, end: 3, automatic: true)
        let b = ZoomRegion(start: 4, end: 7)
        studio.project.zooms = [b, a]
        let start = InspectorView(studio: studio).zoomBinding(a, \.start)
        studio.project.zooms.swapAt(0, 1)
        start.wrappedValue = 4
        XCTAssertEqual(studio.project.zooms[0].start, 2.9)
        XCTAssertFalse(studio.project.zooms[0].automatic)
        studio.project.zooms.removeAll()
        XCTAssertEqual(start.wrappedValue, a.start)
        studio.project = Project(zooms: [b])
        start.wrappedValue = 2
        XCTAssertEqual(studio.project.zooms, [b])
    }
}
