import Foundation
import SwiftUI
func timeLabel(_ value: Double) -> String {
    let seconds = value.isFinite ? max(0, value) : 0
    return String(format: "%02d:%02d.%01d", Int(seconds) / 60, Int(seconds) % 60, Int(seconds * 10) % 10)
}
extension Backdrop {
    var colors: [Color] {
        let (a, b) = rgb
        return [Color(red: a.0, green: a.1, blue: a.2), Color(red: b.0, green: b.1, blue: b.2)]
    }
}
