import Foundation

/// A finite, causal camera filter. All crop coordinates share the same easing,
/// so interrupted moves keep their velocity/acceleration and remain in bounds.
struct CameraPath: Sendable {
    static let transitionDuration = 0.60
    private struct Pose: Equatable, Sendable {
        var width: Double = 1
        var x: Double = 0.5
        var y: Double = 0.5
        init() {}
        init(_ region: ZoomRegion) {
            width = 1 / min(4, max(1, region.scale))
            x = min(1 - width / 2, max(width / 2, region.x))
            y = min(1 - width / 2, max(width / 2, region.y))
        }
    }
    private struct Change: Sendable {
        let time: Double
        let before: Pose
        let target: Pose
    }
    private struct Hold {
        let start: Double
        let end: Double
        let pose: Pose
        let manual: Bool
    }
    private var changes: [Change] = []

    init(project: Project) {
        let regions = project.zooms.enumerated().filter { $0.element.end > $0.element.start }
            .sorted { a, b in a.element.start == b.element.start ? a.offset < b.offset : a.element.start < b.element.start }
            .map(\.element)
        let automatic = regions.filter(\.automatic)
        var holds: [Hold] = []
        var i = 0
        while i < automatic.count {
            let first = i
            var end = automatic[i].end
            i += 1
            // Short pauses belong to one shot; do not briefly zoom out between clicks.
            while i < automatic.count && automatic[i].start <= end + 0.30 {
                end = max(end, automatic[i].end)
                i += 1
            }
            for j in first..<i {
                let region = automatic[j]
                let stop = j + 1 < i ? automatic[j + 1].start : end - min(Self.transitionDuration, (end - region.start) / 2)
                // A superseded target never regains priority when a later region ends.
                if stop > region.start {
                    holds.append(Hold(start: region.start, end: stop, pose: Pose(region), manual: false))
                }
            }
        }
        for region in regions where !region.automatic {
            let exit = region.end - min(Self.transitionDuration, (region.end - region.start) / 2)
            holds.append(Hold(start: region.start, end: exit, pose: Pose(region), manual: true))
        }
        // Resolve manual overrides once, rather than sorting overlapping regions per frame.
        struct Event { let time: Double; let index: Int; let begins: Bool }
        let events = holds.indices.flatMap { index in
            [Event(time: holds[index].start, index: index, begins: true),
             Event(time: holds[index].end, index: index, begins: false)]
        }.sorted { $0.time < $1.time }
        var activeManual: [Int: Pose] = [:]
        var activeAuto: [Int: Pose] = [:]
        var previous = Pose()
        var eventIndex = 0
        while eventIndex < events.count {
            let time = events[eventIndex].time
            while eventIndex < events.count && events[eventIndex].time == time {
                let event = events[eventIndex], hold = holds[event.index]
                if hold.manual { activeManual[event.index] = event.begins ? hold.pose : nil }
                else { activeAuto[event.index] = event.begins ? hold.pose : nil }
                eventIndex += 1
            }
            let target: Pose
            if let index = activeManual.keys.max() { target = activeManual[index]! }
            else if let index = activeAuto.keys.max() { target = activeAuto[index]! }
            else { target = Pose() }
            if target != previous {
                changes.append(Change(time: time, before: previous, target: target))
                previous = target
            }
        }
    }

    func zoom(at time: Double) -> (scale: Double, x: Double, y: Double) {
        guard time.isFinite else { return (1, 0.5, 0.5) }
        // Only changes in the most recent response window can still be moving.
        var low = 0, high = changes.count
        while low < high {
            let middle = (low + high) / 2
            if changes[middle].time <= time - Self.transitionDuration { low = middle + 1 }
            else { high = middle }
        }
        var result = low > 0 ? changes[low - 1].target : Pose()
        while low < changes.count && changes[low].time <= time {
            let change = changes[low]
            let t = min(1, max(0, (time - change.time) / Self.transitionDuration))
            let weight = t * t * t * (10 + t * (-15 + 6 * t))
            result.width += (change.target.width - change.before.width) * weight
            result.x += (change.target.x - change.before.x) * weight
            result.y += (change.target.y - change.before.y) * weight
            low += 1
        }
        return (1 / max(0.25, min(1, result.width)), result.x, result.y)
    }
}
