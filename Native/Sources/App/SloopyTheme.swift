import SwiftUI

struct SloopyAccentColorEnvironmentKey: EnvironmentKey {
    static let defaultValue = Color(red: 0x78 / 255, green: 0x98 / 255, blue: 0xAA / 255)
}

extension EnvironmentValues {
    var sloopyAccentColor: Color {
        get { self[SloopyAccentColorEnvironmentKey.self] }
        set { self[SloopyAccentColorEnvironmentKey.self] = newValue }
    }
}
