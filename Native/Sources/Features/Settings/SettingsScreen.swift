
import SwiftUI
import PhotosUI
import UIKit

struct SloopyQuickApp: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let deepLink: String
    let fallbackURL: String

    static let all: [SloopyQuickApp] = [
        .init(id: "whatsapp", name: "WhatsApp", symbol: "message.fill", deepLink: "whatsapp://", fallbackURL: "https://www.whatsapp.com/"),
        .init(id: "instagram", name: "Instagram", symbol: "camera.fill", deepLink: "instagram://app", fallbackURL: "https://www.instagram.com/"),
        .init(id: "youtube", name: "YouTube", symbol: "play.rectangle.fill", deepLink: "youtube://", fallbackURL: "https://www.youtube.com/"),
        .init(id: "spotify", name: "Spotify", symbol: "waveform", deepLink: "spotify://", fallbackURL: "https://open.spotify.com/")
    ]
}

struct SloopyAccentOption: Identifiable {
    let id: String
    let name: String
    let hex: String

    static let all: [SloopyAccentOption] = [
        .init(id: "blue", name: "Ocean blue", hex: "#7898AA"),
        .init(id: "sage", name: "Soft sage", hex: "#819B88"),
        .init(id: "lavender", name: "Lavender", hex: "#9689B3"),
        .init(id: "peach", name: "Warm peach", hex: "#C18D75")
    ]
}

enum SloopyPalette {
    static func color(for name: String, customHex: String = "#7898AA") -> Color {
        if name == "custom" {
            return Color(hex: customHex)
        }
        return Color(hex: SloopyAccentOption.all.first(where: { $0.id == name })?.hex ?? "#7898AA")
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: 1
        )
    }
}

struct SettingsScreen: View {
    @Environment(\.tint) private var tint

    private var accentColor: Color { tint ?? SloopyPalette.color(for: accent, customHex: accentHex) }

    @AppStorage("sloopy-profile-name") private var profileName = "My profile"
    @AppStorage("sloopy-avatar") private var avatar = "🌿"
    @AppStorage("sloopy-native-avatar-image") private var avatarImage = ""

    @AppStorage("sloopy-native-theme") private var theme = "system"
    @AppStorage("sloopy-native-accent") private var accent = "blue"
    @AppStorage("sloopy-native-accent-hex") private var accentHex = "#7898AA"

    @AppStorage("sloopy-native-favorites")
    private var favoritesRaw = "whatsapp,instagram,youtube,spotify"

    @AppStorage("sloopy-native-custom-quick-apps")
    private var customQuickAppsRaw = "[]"

    @AppStorage("sloopy-native-weather-location")
    private var weatherLocation = "Pontianak"

    @AppStorage("sloopy-native-custom-shortcut-name")
    private var customShortcutName = "MWLT"

    @AppStorage("sloopy-native-custom-shortcut-url")
    private var customShortcutURL = "https://mwlt.pages.dev/"

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedAppIconName = ""
    @State private var isChangingAppIcon = false
    @State private var appIconError: String?
    @State private var isQuickAppEditorPresented = false

    private let avatars = ["🌿", "🌙", "☁️", "✨", "🌼", "🌊"]

    private var favoriteIDs: Set<String> {
        Set(favoritesRaw.split(separator: ",").map(String.init))
    }

    private var customQuickApps: [SloopyCustomQuickApp] {
        guard let data = customQuickAppsRaw.data(using: .utf8),
              let apps = try? JSONDecoder().decode([SloopyCustomQuickApp].self, from: data) else {
            return []
        }
        return apps
    }

    private func saveCustomQuickApps(_ apps: [SloopyCustomQuickApp]) {
        guard let data = try? JSONEncoder().encode(apps),
              let encoded = String(data: data, encoding: .utf8) else { return }
        customQuickAppsRaw = encoded
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                heading
                profileSection
                appearanceSection
                appIconSection
                quickLaunchSection
                weatherSection
                customShortcutSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 110)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task { await loadPhoto(item) }
        }
        .onAppear {
            selectedAppIconName = UIApplication.shared.alternateIconName ?? ""
        }
        .sheet(isPresented: $isQuickAppEditorPresented) {
            QuickLaunchEditorSheet { app in
                saveCustomQuickApps(customQuickApps + [app])
            }
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("YOUR SPACE")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.3)
                .foregroundStyle(.secondary)

            Text("Make it yours.")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text("Personalize your Sloopy space.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeading("Your profile", subtitle: "Choose an avatar or a photo from your library.")

            HStack(spacing: 14) {
                profileImage
                    .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 7) {
                    TextField("Display name", text: $profileName)
                        .font(.body)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .padding(11)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

                    Text("Up to 24 characters")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text("AVATAR TEMPLATES")
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundStyle(.secondary)

            HStack(spacing: 11) {
                ForEach(avatars, id: \.self) { choice in
                    Button {
                        avatar = choice
                        avatarImage = ""
                    } label: {
                        Text(choice)
                            .font(.system(size: 23))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                avatar == choice && avatarImage.isEmpty
                                    ? accentColor.opacity(0.16)
                                    : Color(uiColor: .secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 13)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Choose photo", systemImage: "photo")
                        .font(.subheadline.weight(.semibold))
                }

                Spacer()

                if !avatarImage.isEmpty {
                    Button("Use template") {
                        avatarImage = ""
                    }
                    .font(.subheadline)
                }
            }
        }
        .settingsCard()
    }

    @ViewBuilder
    private var profileImage: some View {
        if let data = Data(base64Encoded: avatarImage),
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: 19))
        } else {
            Text(avatar)
                .font(.system(size: 33))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(accentColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 19))
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeading("Appearance", subtitle: "Choose how Sloopy looks.")

            Picker("Appearance", selection: $theme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)

            Text("ACCENT COLOR")
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundStyle(.secondary)

            HStack(spacing: 17) {
                ForEach(SloopyAccentOption.all) { option in
                    Button {
                        accent = option.id
                    } label: {
                        Circle()
                            .fill(Color(hex: option.hex))
                            .frame(width: 37, height: 37)
                            .overlay {
                                if accent == option.id {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(3)
                            .overlay(Circle().stroke(accent == option.id ? Color.primary : .clear, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.name)
                }
            }

            Text("Custom accent HEX")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack {
                TextField("#7898AA", text: $accentHex)
                    .font(.body.monospaced())
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(11)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

                Button("Apply") {
                    let normalized = accentHex.uppercased()
                    if normalized.range(of: "^#[0-9A-F]{6}$", options: .regularExpression) != nil {
                        accentHex = normalized
                        accent = "custom"
                    }
                }
                .font(.subheadline.bold())
            }
        }
        .settingsCard()
    }

    private var appIconSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionHeading("App icon", subtitle: "Choose the icon shown on your iPhone Home Screen.")

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                spacing: 12
            ) {
                ForEach(SloopyAppIconOption.all) { option in
                    Button {
                        changeAppIcon(to: option)
                    } label: {
                        VStack(spacing: 8) {
                            Image(option.previewAssetName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 66, height: 66)
                                .clipShape(RoundedRectangle(cornerRadius: 16))

                            Text(option.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.primary)

                            if selectedAppIconName == (option.alternateName ?? "") {
                                Label("Selected", systemImage: "checkmark.circle.fill")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(accentColor)
                            } else {
                                Text(" ")
                                    .font(.system(size: 9))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedAppIconName == (option.alternateName ?? "")
                                ? accentColor.opacity(0.09)
                                : Color(uiColor: .secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 17)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 17)
                                .stroke(
                                    selectedAppIconName == (option.alternateName ?? "")
                                        ? accentColor
                                        : Color.primary.opacity(0.05),
                                    lineWidth: selectedAppIconName == (option.alternateName ?? "") ? 1.5 : 1
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isChangingAppIcon)
                }
            }

            if let appIconError {
                Text(appIconError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Text("iOS may show a system confirmation when the icon changes. More icon styles can be added in future app updates.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .settingsCard()
    }

    private func changeAppIcon(to option: SloopyAppIconOption) {
        guard UIApplication.shared.supportsAlternateIcons else {
            appIconError = "Alternate app icons are not available in this build."
            return
        }

        let targetName = option.alternateName ?? ""
        guard targetName != selectedAppIconName else { return }

        isChangingAppIcon = true
        appIconError = nil
        UIApplication.shared.setAlternateIconName(option.alternateName) { error in
            DispatchQueue.main.async {
                isChangingAppIcon = false
                if let error {
                    appIconError = error.localizedDescription
                } else {
                    selectedAppIconName = targetName
                }
            }
        }
    }

    private var quickLaunchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("Quick Launch", subtitle: "Choose built-in apps or add your own shortcuts.")

            ForEach(SloopyQuickApp.all) { app in
                Toggle(isOn: Binding(
                    get: { favoriteIDs.contains(app.id) },
                    set: { enabled in
                        var updated = favoriteIDs
                        if enabled {
                            updated.insert(app.id)
                        } else {
                            updated.remove(app.id)
                        }
                        favoritesRaw = updated.sorted().joined(separator: ",")
                    }
                )) {
                    Label(app.name, systemImage: app.symbol)
                        .font(.subheadline.weight(.medium))
                }
                .tint(accentColor)
            }

            if !customQuickApps.isEmpty {
                Divider()
                    .padding(.vertical, 3)

                Text("ADDED BY YOU")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(.secondary)

                ForEach(customQuickApps) { app in
                    HStack(spacing: 11) {
                        Label(app.name, systemImage: app.symbol)
                            .font(.subheadline.weight(.medium))

                        Spacer()

                        Button(role: .destructive) {
                            saveCustomQuickApps(customQuickApps.filter { $0.id != app.id })
                        } label: {
                            Image(systemName: "trash")
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 34, height: 34)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Remove \(app.name) from Quick Launch")
                    }
                }
            }

            Button {
                isQuickAppEditorPresented = true
            } label: {
                Label("Add an app", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 3)
            }
            .buttonStyle(.plain)

            Text("You can add an app using its URL scheme, or add a website with an https:// address. iOS does not let apps list every installed app automatically.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .settingsCard()
    }

    private var weatherSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            sectionHeading("Weather location", subtitle: "Choose the city used for your local forecast.")

            TextField("City", text: $weatherLocation)
                .font(.body)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(12)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
        .settingsCard()
    }

    private var customShortcutSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            sectionHeading("Custom shortcut", subtitle: "Keep your other web app available from Quick Launch.")

            TextField("App name", text: $customShortcutName)
                .font(.body)
                .padding(12)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            TextField("https://example.com/", text: $customShortcutURL)
                .font(.body)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
        .settingsCard()
    }

    private func sectionHeading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }

        let maxDimension: CGFloat = 512
        let scale = min(1, maxDimension / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }

        if let jpeg = resized.jpegData(compressionQuality: 0.78) {
            await MainActor.run {
                avatarImage = jpeg.base64EncodedString()
            }
        }
    }
}

private struct SettingsCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 21))
    }
}

private extension View {
    func settingsCard() -> some View {
        modifier(SettingsCardModifier())
    }
}


private struct QuickLaunchEditorSheet: View {
    @Environment(\.tint) private var tint

    private var accentColor: Color { tint ?? .blue }

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var url = ""
    @State private var symbol = "app.fill"

    let onSave: (SloopyCustomQuickApp) -> Void

    private let symbols = [
        "app.fill", "globe", "link", "message.fill", "camera.fill",
        "play.rectangle.fill", "music.note", "bag.fill", "gamecontroller.fill",
        "briefcase.fill", "envelope.fill", "map.fill"
    ]

    private var canAdd: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              let components = URLComponents(string: trimmedURL),
              let scheme = components.scheme?.lowercased(),
              !scheme.isEmpty else {
            return false
        }
        if scheme == "http" || scheme == "https" {
            return components.host != nil
        }
        return scheme != "javascript" && scheme != "data"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("App details") {
                    TextField("App name", text: $name)
                        .textInputAutocapitalization(.words)

                    TextField("URL scheme or website", text: $url)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Choose an icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(symbols, id: \.self) { option in
                            Button {
                                symbol = option
                            } label: {
                                Image(systemName: option)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(symbol == option ? accentColor : Color.secondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 42)
                                    .background(
                                        symbol == option
                                            ? accentColor.opacity(0.13)
                                            : Color(uiColor: .secondarySystemGroupedBackground),
                                        in: RoundedRectangle(cornerRadius: 11)
                                    )
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 11)
                                            .stroke(symbol == option ? accentColor : Color.clear, lineWidth: 1.3)
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(option)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Text("For an installed iPhone app, enter its URL scheme (for example, appname://). For a website, enter a full https:// address.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add to Quick Launch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let app = SloopyCustomQuickApp(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            url: url.trimmingCharacters(in: .whitespacesAndNewlines),
                            symbol: symbol
                        )
                        onSave(app)
                        dismiss()
                    }
                    .disabled(!canAdd)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}


private struct SloopyAppIconOption: Identifiable {
    let id: String
    let title: String
    let previewAssetName: String
    let alternateName: String?

    static let all = [
        SloopyAppIconOption(
            id: "cctv",
            title: "CCTV",
            previewAssetName: "SloopyIconPreview-CCTV",
            alternateName: nil
        ),
        SloopyAppIconOption(
            id: "crystal",
            title: "Crystal",
            previewAssetName: "SloopyIconPreview-Crystal",
            alternateName: "AppIconCrystal"
        ),
        SloopyAppIconOption(
            id: "eye",
            title: "Eye",
            previewAssetName: "SloopyIconPreview-Eye",
            alternateName: "AppIconEye"
        ),
        SloopyAppIconOption(
            id: "cat",
            title: "Cat",
            previewAssetName: "SloopyIconPreview-Cat",
            alternateName: "AppIconCat"
        ),
        SloopyAppIconOption(
            id: "cube",
            title: "Cube",
            previewAssetName: "SloopyIconPreview-Cube",
            alternateName: "AppIconCube"
        )
    ]
}
