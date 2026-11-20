import Foundation
import FamilyControls
import ManagedSettings

enum SloopyFocusError: LocalizedError {
    case authorizationRequired
    case noSelection

    var errorDescription: String? {
        switch self {
        case .authorizationRequired:
            "Family Controls permission is not active."
        case .noSelection:
            "Choose at least one app, category, or website to pause."
        }
    }
}

@MainActor
final class SloopyFocusService {
    static let shared = SloopyFocusService()

    private let store = ManagedSettingsStore()
    private let selectionKey = "sloopy-focus-family-activity-selection"

    private init() {}

    var isAuthorized: Bool {
        AuthorizationCenter.shared.authorizationStatus == .approved
    }

    func requestAuthorization() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        guard isAuthorized else {
            throw SloopyFocusError.authorizationRequired
        }
    }

    func loadSelection() -> FamilyActivitySelection {
        guard let data = UserDefaults.standard.data(forKey: selectionKey),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return FamilyActivitySelection()
        }
        return selection
    }

    func saveSelection(_ selection: FamilyActivitySelection) {
        guard let data = try? JSONEncoder().encode(selection) else { return }
        UserDefaults.standard.set(data, forKey: selectionKey)
    }

    func applySelection(_ selection: FamilyActivitySelection) throws {
        guard isAuthorized else {
            throw SloopyFocusError.authorizationRequired
        }

        let hasSelection = !selection.applicationTokens.isEmpty
            || !selection.webDomainTokens.isEmpty
            || !selection.categoryTokens.isEmpty

        guard hasSelection else {
            throw SloopyFocusError.noSelection
        }

        store.shield.applications = selection.applicationTokens.isEmpty
            ? nil : selection.applicationTokens
        store.shield.webDomains = selection.webDomainTokens.isEmpty
            ? nil : selection.webDomainTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil : .specific(selection.categoryTokens)
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty
            ? nil : .specific(selection.categoryTokens)
    }

    func clearShields() {
        store.shield.applications = nil
        store.shield.webDomains = nil
        store.shield.applicationCategories = nil
        store.shield.webDomainCategories = nil
    }
}
