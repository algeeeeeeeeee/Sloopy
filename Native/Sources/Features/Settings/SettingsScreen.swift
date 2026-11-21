
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
        .init(id: "line", name: "LINE", symbol: "message.circle.fill", deepLink: "line://", fallbackURL: "https://line.me/"),
        .init(id: "x", name: "X", symbol: "at", deepLink: "twitter://", fallbackURL: "https://x.com/"),
        .init(id: "facebook", name: "Facebook", symbol: "person.2.fill", deepLink: "fb://", fallbackURL: "https://www.facebook.com/"),
        .init(id: "tiktok", name: "TikTok", symbol: "music.note", deepLink: "snssdk1233://", fallbackURL: "https://www.tiktok.com/"),
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
    private var accentColor: Color { SloopyPalette.color(for: accent, customHex: accentHex) }

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
    @AppStorage("sloopy-native-selected-app-icon") private var storedSelectedAppIconID = ""
    @State private var selectedAppIconID = SloopyBuildConfiguration.primaryAppIconID
    @State private var appIconOptions: [SloopyAppIconOption] = []
    @State private var isChangingAppIcon = false
    @State private var appIconError: String?
    @State private var appIconDiagnosticLog = ""
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
        .onAppear(perform: loadAppIcons)
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
                ForEach(appIconOptions) { option in
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

                            if selectedAppIconID == option.id {
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
                            selectedAppIconID == option.id
                                ? accentColor.opacity(0.09)
                                : Color(uiColor: .secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 17)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 17)
                                .stroke(
                                    selectedAppIconID == option.id
                                        ? accentColor
                                        : Color.primary.opacity(0.05),
                                    lineWidth: selectedAppIconID == option.id ? 1.5 : 1
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
            if !appIconDiagnosticLog.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ICON DIAGNOSTICS")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.secondary)

                    Text(appIconDiagnosticLog)
                        .font(.system(size: 10, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        UIPasteboard.general.string = appIconDiagnosticLog
                    } label: {
                        Label("Copy diagnostic log", systemImage: "doc.on.doc")
                            .font(.caption.weight(.semibold))
                    }
                }
                .padding(11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 12))
            }

            Text("Your selected icon is saved and remembered when you reopen Sloopy.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .settingsCard()
    }

    // Load alternate icon entries directly from the finished bundle, as EeveeSpotify does.
    // The filename passed to UIKit comes from CFBundleIconFiles[0], not from a hard-coded label.
    private func loadAppIcons() {
        let bundleIcons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any]
        let alternates = bundleIcons?["CFBundleAlternateIcons"] as? [String: Any] ?? [:]

        let definitions: [(key: String, id: String, title: String, preview: String)] = [
            ("CCTVIcon", "cctv", "CCTV", "SloopyIconPreview-CCTV"),
            ("CrystalIcon", "crystal", "Crystal", "SloopyIconPreview-Crystal"),
            ("EyeIcon", "eye", "Eye", "SloopyIconPreview-Eye"),
            ("CatIcon", "cat", "Cat", "SloopyIconPreview-Cat"),
            ("CubeIcon", "cube", "Cube", "SloopyIconPreview-Cube")
        ]

        let primaryInfo = bundleIcons?["CFBundlePrimaryIcon"] as? [String: Any]
        let primaryFiles = primaryInfo?["CFBundleIconFiles"] as? [String] ?? ["AppIcon60x60"]
        let primaryID = SloopyBuildConfiguration.primaryAppIconID

        appIconOptions = definitions.compactMap { definition in
            // EeveeSpotify models the app's primary icon separately and passes nil
            // to UIKit when that icon is selected. Do not treat the build-time
            // primary icon as one of its own alternates.
            if definition.id == primaryID {
                return SloopyAppIconOption(
                    id: definition.id,
                    title: definition.title,
                    previewAssetName: definition.preview,
                    plistKey: "__primary__",
                    iconFiles: primaryFiles,
                    alternateName: nil
                )
            }

            guard let iconInfo = alternates[definition.key] as? [String: Any] else { return nil }
            let files = iconInfo["CFBundleIconFiles"] as? [String] ?? [definition.key]
            return SloopyAppIconOption(
                id: definition.id,
                title: definition.title,
                previewAssetName: definition.preview,
                plistKey: definition.key,
                iconFiles: files,
                alternateName: files.first ?? definition.key
            )
        }

        guard !appIconOptions.isEmpty else {
            appIconError = "No alternate icons were found in CFBundleIcons."
            NSLog("[Sloopy][AppIcon] CFBundleAlternateIcons is missing or empty.")
            return
        }

        // Like EeveeSpotify, prefer the saved choice because alternateIconName
        // can return nil in resigned or TrollStore-installed builds.
        if appIconOptions.contains(where: { $0.id == storedSelectedAppIconID }) {
            selectedAppIconID = storedSelectedAppIconID
        } else if let activeName = UIApplication.shared.alternateIconName,
                  let activeOption = appIconOptions.first(where: {
                      $0.plistKey == activeName || $0.alternateName == activeName
                  }) {
            selectedAppIconID = activeOption.id
            storedSelectedAppIconID = activeOption.id
        } else {
            selectedAppIconID = SloopyBuildConfiguration.primaryAppIconID
            storedSelectedAppIconID = selectedAppIconID
        }

        NSLog("[Sloopy][AppIcon] Loaded %lu alternate icon(s); supportsAlternateIcons=%@",
              appIconOptions.count, UIApplication.shared.supportsAlternateIcons ? "YES" : "NO")
    }

    private func appIconDiagnosticSnapshot(for option: SloopyAppIconOption) -> String {
        let info = Bundle.main.infoDictionary ?? [:]
        let icons = info["CFBundleIcons"] as? [String: Any] ?? [:]
        let alternates = icons["CFBundleAlternateIcons"] as? [String: Any] ?? [:]
        let app = UIApplication.shared
        var lines = [
            "bundleID=\(Bundle.main.bundleIdentifier ?? "nil")",
            "requestedName=\(option.alternateName ?? "nil (primary)")",
            "selectedOptionID=\(option.id)",
            "plistKey=\(option.plistKey)",
            "optionIconFiles=\(option.iconFiles)",
            "supportsAlternateIcons=\(app.supportsAlternateIcons)",
            "alternateIconName=\(app.alternateIconName ?? "nil")",
            "applicationState=\(app.applicationState.rawValue)",
            "isMainThread=\(Thread.isMainThread)",
            "CFBundleIcons.alternateKeys=\(alternates.keys.sorted())"
        ]

        for (key, value) in alternates.sorted(by: { $0.key < $1.key }) {
            let metadata = value as? [String: Any] ?? [:]
            let files = metadata["CFBundleIconFiles"] as? [String] ?? []
            lines.append("\(key): files=\(files), prerendered=\(String(describing: metadata["UIPrerenderedIcon"]))")
            for stem in files {
                for suffix in ["@2x.png", "@3x.png", "@2x~ipad.png", "~ipad.png"] {
                    let filename = stem + suffix
                    let url = URL(fileURLWithPath: Bundle.main.bundlePath).appendingPathComponent(filename)
                    let exists = FileManager.default.fileExists(atPath: url.path)
                    lines.append("  \(filename): exists=\(exists)")
                }
            }
        }

        let ipadIcons = info["CFBundleIcons~ipad"] as? [String: Any] ?? [:]
        let ipadAlternates = ipadIcons["CFBundleAlternateIcons"] as? [String: Any] ?? [:]
        lines.append("CFBundleIcons~ipad.alternateKeys=\(ipadAlternates.keys.sorted())")
        return lines.joined(separator: "\n")
    }

    private func changeAppIcon(to option: SloopyAppIconOption) {
        guard UIApplication.shared.supportsAlternateIcons else {
            appIconError = "Alternate app icons are not available in this build."
            return
        }
        guard !isChangingAppIcon else { return }

        let previousIconID = selectedAppIconID
        let requestedName = option.alternateName
        isChangingAppIcon = true
        appIconError = nil

        selectedAppIconID = option.id
        storedSelectedAppIconID = option.id

        appIconDiagnosticLog = appIconDiagnosticSnapshot(for: option)
        NSLog("[Sloopy][AppIcon] Preflight diagnostics:\n%@", appIconDiagnosticLog)
        NSLog("[Sloopy][AppIcon] Calling setAlternateIconName(%@)",
              requestedName ?? "nil")

        UIApplication.shared.setAlternateIconName(requestedName) { error in
            let callbackWasMainThread = Thread.isMainThread
            DispatchQueue.main.async {
                isChangingAppIcon = false

                if let error {
                    let nsError = error as NSError
                    let details = """
                    CALLBACK=ERROR
                    callbackWasMainThread=\(callbackWasMainThread)
                    localizedDescription=\(nsError.localizedDescription)
                    domain=\(nsError.domain)
                    code=\(nsError.code)
                    userInfo=\(String(describing: nsError.userInfo))
                    """
                    appIconDiagnosticLog += "\n\n" + details
                    NSLog("[Sloopy][AppIcon] Full failure diagnostics:\n%@", details)

                    selectedAppIconID = previousIconID
                    storedSelectedAppIconID = previousIconID
                    appIconError = "\(nsError.localizedDescription) (\(nsError.domain), code \(nsError.code))"
                } else {
                    let details = """
                    CALLBACK=SUCCESS
                    callbackWasMainThread=\(callbackWasMainThread)
                    alternateIconNameAfterCall=\(UIApplication.shared.alternateIconName ?? "nil")
                    """
                    appIconDiagnosticLog += "\n\n" + details
                    NSLog("[Sloopy][AppIcon] \(details)")
                }
            }
        }
    }

    private var quickLaunchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("Quick Launch", subtitle: "Select supported apps or add a custom shortcut.")

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

            Text("Choose an app here to add it to your Home menu. iOS does not allow Sloopy to scan every installed app; if an app is unavailable, its website will open instead.")
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
    @AppStorage("sloopy-native-accent") private var accent = "blue"
    @AppStorage("sloopy-native-accent-hex") private var accentHex = "#7898AA"
    private var accentColor: Color { SloopyPalette.color(for: accent, customHex: accentHex) }

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
    let plistKey: String
    let iconFiles: [String]
    let alternateName: String?
}
