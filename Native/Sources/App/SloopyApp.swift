import SwiftUI
import SwiftData

@main
struct SloopyApp: App {
    @AppStorage("sloopy-native-theme") private var theme = "system"
    @AppStorage("sloopy-native-accent") private var accent = "blue"
    @AppStorage("sloopy-native-accent-hex") private var accentHex = "#7898AA"

    private var preferredScheme: ColorScheme? {
        switch theme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(preferredScheme)
                .tint(SloopyPalette.color(for: accent, customHex: accentHex))
                .modelContainer(for: SloopyNote.self)
        }
    }
}
