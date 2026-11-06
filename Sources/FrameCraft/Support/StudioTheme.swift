import SwiftUI

/// Interface colors only; project backgrounds and exported media keep their own palette.
enum StudioTheme {
    static let accent = Color(.sRGB, red: 229 / 255, green: 1, blue: 66 / 255, opacity: 1)
    static let canvas = Color(.sRGB, red: 8 / 255, green: 9 / 255, blue: 11 / 255, opacity: 1)
    static let panel = Color(.sRGB, red: 16 / 255, green: 17 / 255, blue: 19 / 255, opacity: 1)
    static let raised = Color(.sRGB, red: 27 / 255, green: 29 / 255, blue: 32 / 255, opacity: 1)
    static let onAccent = Color(.sRGB, red: 8 / 255, green: 9 / 255, blue: 11 / 255, opacity: 1)
}

/// A stable lime fill with explicit disabled, pressed, hover and keyboard-focus states.
private struct StudioPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.medium)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .foregroundStyle(isEnabled ? StudioTheme.onAccent : Color.secondary)
            .background(isEnabled ? StudioTheme.accent : StudioTheme.raised, in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(isFocused ? Color.white : Color.clear, lineWidth: 2).padding(-3))
            .brightness(isEnabled && isHovered ? 0.04 : 0)
            .opacity(configuration.isPressed && isEnabled ? 0.78 : 1)
            .onHover { isHovered = $0 }
    }
}

extension View {
    func studioPrimaryAction() -> some View { buttonStyle(StudioPrimaryButtonStyle()) }
}
