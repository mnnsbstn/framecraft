import Foundation

/// Native down events carry their original coordinates. A counter change can be
/// observed much later, after the pointer has moved or crossed to another display.
struct CaptureClicks {
    private var nativeEventsReceived = false
    private var native: [ClickSample] = []
    private var fallback: [ClickSample] = []

    mutating func observeNative(_ sample: CursorSample) {
        if !nativeEventsReceived {
            nativeEventsReceived = true
            fallback.removeAll()
        }
        guard sample.visible else { return }
        native.append(ClickSample(time: sample.time, x: sample.x, y: sample.y))
    }

    mutating func observeCounter(_ sample: CursorSample) {
        guard !nativeEventsReceived, sample.visible else { return }
        fallback.append(ClickSample(time: sample.time, x: sample.x, y: sample.y))
    }

    var resolved: [ClickSample] { nativeEventsReceived ? native : fallback }
}
