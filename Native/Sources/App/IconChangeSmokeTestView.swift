#if DEBUG
import SwiftUI
import UIKit

struct IconChangeSmokeTestView: View {
    @State private var result = "NOT RUN"

    private var supportStatus: String {
        "supportsAlternateIcons=\(UIApplication.shared.supportsAlternateIcons)"
    }

    var body: some View {
        VStack(spacing: 18) {
            Text("Sloopy Icon Smoke Test")
                .font(.title2.bold())

            Text(supportStatus)
                .font(.system(.body, design: .monospaced))
                .accessibilityIdentifier("icon-test-support")

            Button("Change to Crystal icon") {
                setIcon("CrystalIcon")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("icon-test-change")

            Button("Restore primary icon") {
                setIcon(nil)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("icon-test-reset")

            Text(result)
                .font(.system(.footnote, design: .monospaced))
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("icon-test-result")
        }
        .padding(24)
    }

    private func setIcon(_ name: String?) {
        guard UIApplication.shared.supportsAlternateIcons else {
            result = "ERROR: supportsAlternateIcons=false"
            return
        }

        result = "REQUESTING: \(name ?? "Primary")"
        SloopyAlternateIconBridge.setAlternateIconName(name) { route, error in
            DispatchQueue.main.async {
                if let error {
                    let nsError = error as NSError
                    let debug = nsError.userInfo[NSDebugDescriptionErrorKey] as? String ?? ""
                    result = "ERROR: \(error.localizedDescription) | \(nsError.domain) (\(nsError.code)) | Route: \(route) | \(debug)"
                } else {
                    result = "SUCCESS: \(name ?? "Primary") via \(route)"
                }
            }
        }
    }
}
#endif
