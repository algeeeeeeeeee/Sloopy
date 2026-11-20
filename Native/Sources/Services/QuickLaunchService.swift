import UIKit

@MainActor
enum QuickLaunchService {
    static func open(_ app: SloopyQuickApp) {
        guard let url = URL(string: app.deepLink),
              let fallback = URL(string: app.fallbackURL) else { return }

        UIApplication.shared.open(url) { success in
            if !success {
                UIApplication.shared.open(fallback)
            }
        }
    }
}
