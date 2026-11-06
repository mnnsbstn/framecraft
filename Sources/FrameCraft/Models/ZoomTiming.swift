import Foundation

/// All deltas are relative to an immutable gesture snapshot, never the last update.
enum ZoomTiming {
    enum Part: Hashable { case start, move, end }

    static func edited(_ original: ZoomRegion, part: Part, delta: Double, duration: Double) -> ZoomRegion {
        guard duration.isFinite, duration > 0, delta.isFinite,
              original.start.isFinite, original.end.isFinite,
              original.start >= 0, original.end <= duration, original.end > original.start else { return original }
        let minimum = min(0.1, duration, original.end - original.start)
        var result = original
        switch part {
        case .start:
            result.start = min(original.end - minimum, max(0, original.start + delta))
        case .end:
            result.end = max(original.start + minimum, min(duration, original.end + delta))
        case .move:
            let shift = min(duration - original.end, max(-original.start, delta))
            result.start = original.start + shift
            result.end = original.end + shift
        }
        if result.start != original.start || result.end != original.end { result.automatic = false }
        return result
    }
}
