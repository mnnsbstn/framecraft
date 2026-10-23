import Foundation

struct CursorSample: Codable, Equatable, Sendable {
    var time: Double
    var x: Double
    var y: Double
    var visible: Bool = true
}

/// Present only when the source was captured without an embedded cursor.
struct CursorTrack: Codable, Equatable, Sendable {
    var samples: [CursorSample]
    var enabled = true
    var smoothing: Double = 0.12
    var size: Double = 1.2
    var highlightClicks = true

    func prepared(clicks: [ClickSample]) -> [CursorSample] {
        guard smoothing > 0, samples.count > 2 else { return samples }
        var result = samples
        var lower = 0
        var clickIndex = 0
        let sortedClicks = clicks.sorted { $0.time < $1.time }
        for i in samples.indices {
            let sample = samples[i]
            guard sample.visible else { continue }
            while lower < i && samples[lower].time < sample.time - smoothing { lower += 1 }
            var weight = 0.0, x = 0.0, y = 0.0
            for j in lower..<samples.count {
                let other = samples[j]
                if other.time > sample.time + smoothing { break }
                // Never blend across a hidden interval or a tracking gap.
                if !other.visible { if j <= i { weight = 0; x = 0; y = 0; continue }; break }
                let d = (other.time - sample.time) / max(0.001, smoothing * 0.45)
                let w = exp(-0.5 * d * d)
                weight += w; x += other.x * w; y += other.y * w
            }
            while clickIndex + 1 < sortedClicks.count && sortedClicks[clickIndex + 1].time < sample.time { clickIndex += 1 }
            let near = sortedClicks.isEmpty ? [] : Array(sortedClicks[max(0, clickIndex - 1)...min(sortedClicks.count - 1, clickIndex + 1)])
            let distance = near.map { abs($0.time - sample.time) }.min() ?? 1
            let blend = min(1, distance / 0.10)
            let eased = blend * blend * (3 - 2 * blend)
            if weight > 0 {
                result[i].x = sample.x * (1 - eased) + (x / weight) * eased
                result[i].y = sample.y * (1 - eased) + (y / weight) * eased
            }
        }
        // Exact click samples are inserted by the recorder, and kept at their hit point.
        return result
    }

    static func position(at time: Double, samples: [CursorSample]) -> CursorSample? {
        guard let first = samples.first, let last = samples.last,
              time >= first.time, time <= last.time + 0.1 else { return nil }
        var low = 0, high = samples.count
        while low < high {
            let mid = (low + high) / 2
            if samples[mid].time <= time { low = mid + 1 } else { high = mid }
        }
        let a = samples[max(0, low - 1)]
        guard a.visible else { return nil }
        guard low < samples.count else { return a }
        let b = samples[low], gap = b.time - a.time
        guard b.visible, gap > 0, gap < 0.15 else { return time - a.time < 0.035 ? a : nil }
        let t = min(1, max(0, (time - a.time) / gap))
        return CursorSample(time: time, x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }
}
