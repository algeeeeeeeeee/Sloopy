import UIKit

@MainActor
enum QuickLaunchService {
    static func open(_ app: SloopyQuickApp) {
        guard let url = URL(string: app.deepLink) else { return }
        UIApplication.shared.open(url)
    }

    static func openWebShortcut(_ rawURL: String) {
        guard
            let url = URL(string: rawURL),
            let scheme = url.scheme?.lowercased(),
            scheme == "https" || scheme == "http"
        else { return }

        UIApplication.shared.open(url)
    }
}
