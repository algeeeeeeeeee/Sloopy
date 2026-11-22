import SwiftUI

/// Applies the user's chosen accent color to a whole view tree.
/// `.tint` colors controls, but `Color.accentColor` (used all over the app)
/// only follows the accentColor environment, so both must be set.
struct SloopyAccentModifier: ViewModifier {
    @AppStorage("sloopy-native-accent") private var accent = "blue"
    @AppStorage("sloopy-native-accent-hex") private var accentHex = "#7898AA"

    func body(content: Content) -> some View {
        let color = SloopyPalette.color(for: accent, customHex: accentHex)
        content
            .tint(color)
            .accentColor(color)
    }
}

extension View {
    func sloopyAccent() -> some View {
        modifier(SloopyAccentModifier())
    }
}
