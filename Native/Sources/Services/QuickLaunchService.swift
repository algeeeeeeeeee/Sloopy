import UIKit

struct SloopyCustomQuickApp: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var url: String
    var symbol: String

    init(id: UUID = UUID(), name: String, url: String, symbol: String = "app.fill") {
        self.id = id
        self.name = name
        self.url = url
        self.symbol = symbol
    }
}

@MainActor
enum QuickLaunchService {
    static func open(_ app: SloopyQuickApp) {
        guard let url = URL(string: app.deepLink) else { return }
        UIApplication.shared.open(url)
    }

    static func open(_ app: SloopyCustomQuickApp) {
        let rawURL = app.url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: rawURL),
              let scheme = url.scheme?.lowercased(),
              !scheme.isEmpty,
              scheme != "javascript",
              scheme != "data" else { return }
        UIApplication.shared.open(url)
    }

    static func openWebShortcut(_ rawURL: String) {
        guard let url = URL(string: rawURL),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http" else { return }
        UIApplication.shared.open(url)
    }
}
