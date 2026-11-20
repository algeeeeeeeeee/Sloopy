import SwiftUI
import PhotosUI
import UIKit

struct SloopyHomeScreen: View {
    private var accentColor: Color { Color.accentColor }

    @AppStorage("sloopy-profile-name")
    private var profileName = "My profile"

    @AppStorage("sloopy-avatar")
    private var avatar = "🌿"

    @AppStorage("sloopy-native-avatar-image")
    private var avatarImage = ""

    @AppStorage("sloopy-native-favorites")
    private var favoritesRaw = "whatsapp,instagram,youtube,spotify"

    @AppStorage("sloopy-native-custom-quick-apps")
    private var customQuickAppsRaw = "[]"

    @AppStorage("sloopy-native-custom-shortcut-name")
    private var customShortcutName = "MWLT"

    @AppStorage("sloopy-native-custom-shortcut-url")
    private var customShortcutURL = "https://mwlt.pages.dev/"

    @AppStorage("sloopy-native-routine-start")
    private var routineStartedAt = 0.0

    @AppStorage("sloopy-native-routine-last-minutes")
    private var lastRoutineMinutes = 0

    @AppStorage("sloopy-focus-active-mode")
    private var activeFocusMode = ""

    @AppStorage("sloopy-native-selected-camera")
    private var selectedCamera = "phSVFy5vl1g"

    @State private var cameraExpanded = false
    @State private var isProfileEditorPresented = false
    @State private var focusModeSheet: SloopyFocusMode?

    private let cameras: [(name: String, id: String)] = [
        ("CCTV 01", "phSVFy5vl1g"),
        ("CCTV 02", "cNnBLil3Tak"),
        ("CCTV 03", "Nzajq1hQNQs"),
        ("CCTV 04", "VErhIjCOJ2Q"),
        ("CCTV 05", "EwxjPFnUDJI")
    ]

    private var favoriteApps: [SloopyQuickApp] {
        let ids = Set(favoritesRaw.split(separator: ",").map(String.init))
        return SloopyQuickApp.all.filter { ids.contains($0.id) }
    }

    private var customQuickApps: [SloopyCustomQuickApp] {
        guard let data = customQuickAppsRaw.data(using: .utf8),
              let apps = try? JSONDecoder().decode([SloopyCustomQuickApp].self, from: data) else {
            return []
        }
        return apps
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                header
                hero
                weatherCard
                routineCard
                workModeCard
                cameraCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 110)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .sheet(isPresented: $isProfileEditorPresented) {
            ProfileEditorSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $focusModeSheet) { mode in
            FocusModeSheet(mode: mode)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack {
            Button {
                isProfileEditorPresented = true
            } label: {
                HStack(spacing: 11) {
                    profileAvatar
                        .frame(width: 45, height: 45)
                        .background(accentColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 15))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(profileName.isEmpty ? "My profile" : profileName)
                            .font(.headline)
                            .lineLimit(1)
                        Text("PERSONAL SPACE")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(.secondary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit profile")

            Spacer()

            Menu {
                ForEach(favoriteApps) { app in
                    Button {
                        QuickLaunchService.open(app)
                    } label: {
                        Label(app.name, systemImage: app.symbol)
                    }
                }
                if !customQuickApps.isEmpty {
                    Divider()
                    ForEach(customQuickApps) { app in
                        Button {
                            QuickLaunchService.open(app)
                        } label: {
                            Label(app.name, systemImage: app.symbol)
                        }
                    }
                }
                if !customShortcutURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Divider()
                    Button {
                        QuickLaunchService.openWebShortcut(customShortcutURL)
                    } label: {
                        Label(
                            customShortcutName.isEmpty ? "Custom shortcut" : customShortcutName,
                            systemImage: "globe"
                        )
                    }
                }
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 43, height: 43)
                    .background(.background, in: Circle())
            }
        }
    }

    @ViewBuilder
    private var profileAvatar: some View {
        if let data = Data(base64Encoded: avatarImage),
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 45, height: 45)
                .clipped()
        } else {
            Text(avatar)
                .font(.system(size: 26))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("YOUR DAY")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(activeFocusMode.isEmpty ? "PERSONAL SPACE" : "FOCUS ACTIVE")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.07), in: Capsule())
            }

            Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            TimelineView(.periodic(from: .now, by: 30)) { context in
                Text(context.date, format: .dateTime.hour().minute())
                    .font(.system(size: 43, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }

            Text("A calm little corner for the day ahead.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(19)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    accentColor.opacity(0.14),
                    Color(uiColor: .secondarySystemGroupedBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 23)
        )
    }

    private var weatherCard: some View {
        NativeWeatherCard()
    }

    private var routineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("A SMALL MORNING RITUAL")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("20 MIN TARGET")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(accentColor)
            }

            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.system(size: 24))
                    .foregroundStyle(accentColor)
                    .frame(width: 45, height: 45)
                    .background(accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Get Ready")
                        .font(.headline)
                    Text(activeFocusMode == SloopyFocusMode.getReady.rawValue
                         ? "Your focus session is in progress."
                         : "A calmer start, with time set aside for yourself.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Button {
                focusModeSheet = .getReady
            } label: {
                Label(
                    activeFocusMode == SloopyFocusMode.getReady.rawValue
                        ? "Manage session"
                        : "Start Get Ready",
                    systemImage: activeFocusMode == SloopyFocusMode.getReady.rawValue
                        ? "slider.horizontal.3" : "play.fill"
                )
                .font(.subheadline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
            }
            .buttonStyle(.plain)

            if routineStartedAt > 0 {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let elapsed = max(0, Int(context.date.timeIntervalSince1970 - routineStartedAt))
                    Text("In progress · \(elapsed / 60) min \(elapsed % 60) sec")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            } else {
                Text(lastRoutineMinutes > 0
                     ? "Last session · \(lastRoutineMinutes) minutes"
                     : "A gentle nudge, not a strict timer.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22))
    }

    private var workModeCard: some View {
        Button {
            focusModeSheet = .work
        } label: {
            HStack(spacing: 13) {
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(accentColor)
                    .frame(width: 45, height: 45)
                    .background(accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Text("Work Mode")
                            .font(.headline)
                        if activeFocusMode == SloopyFocusMode.work.rawValue {
                            Circle()
                                .fill(.green)
                                .frame(width: 7, height: 7)
                        }
                    }

                    Text(activeFocusMode == SloopyFocusMode.work.rawValue
                         ? "Focus is on · open to manage your task"
                         : "Keep one important task in focus.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22))
            .contentShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }

    private var cameraCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("ROAD CAMERAS")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(.secondary)

            Text("Live camera preview")
                .font(.headline)

            Picker("Select camera", selection: $selectedCamera) {
                ForEach(cameras.indices, id: \.self) { index in
                    Text(cameras[index].name).tag(cameras[index].id)
                }
            }
            .pickerStyle(.menu)
            .tint(accentColor)

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    cameraExpanded.toggle()
                }
            } label: {
                Label(
                    cameraExpanded ? "Hide live preview" : "Load live stream",
                    systemImage: cameraExpanded ? "eye.slash" : "play.fill"
                )
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
            }
            .buttonStyle(.plain)

            if cameraExpanded {
                SloopyCCTVPlayer(cameraID: selectedCamera)

                Text("Playback depends on the stream owner's YouTube embed permissions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let camera = cameras.first(where: { $0.id == selectedCamera }),
                   let url = URL(string: "https://www.youtube.com/watch?v=\(camera.id)") {
                    Link("Open in YouTube", destination: url)
                        .font(.caption.bold())
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22))
    }
}
