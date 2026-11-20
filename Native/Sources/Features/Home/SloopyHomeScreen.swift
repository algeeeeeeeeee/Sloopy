
import SwiftUI

struct SloopyHomeScreen: View {
    @AppStorage("sloopy-profile-name")
    private var profileName = "My profile"

    @AppStorage("sloopy-avatar")
    private var avatar = "🌿"

    @AppStorage("sloopy-native-favorites")
    private var favoritesRaw = "whatsapp,instagram,youtube,spotify"

    private var favoriteApps: [SloopyQuickApp] {
        let ids = Set(favoritesRaw.split(separator: ",").map(String.init))
        return SloopyQuickApp.all.filter { ids.contains($0.id) }
    }

    @AppStorage("sloopy-native-routine-start")
    private var routineStartedAt = 0.0

    @AppStorage("sloopy-native-routine-last-minutes")
    private var lastRoutineMinutes = 0

    @AppStorage("sloopy-native-selected-camera")
    private var selectedCamera = "phSVFy5vl1g"

    @State private var cameraExpanded = false

    private let cameras: [(name: String, id: String)] = [
        ("CCTV 01", "phSVFy5vl1g"),
        ("CCTV 02", "cNnBLil3Tak"),
        ("CCTV 03", "Nzajq1hQNQs"),
        ("CCTV 04", "VErhIjCOJ2Q"),
        ("CCTV 05", "EwxjPFnUDJI")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                header
                hero
                weatherCard
                routineCard
                cameraCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 110)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var header: some View {
        HStack {
            HStack(spacing: 11) {
                Text(avatar)
                    .font(.system(size: 26))
                    .frame(width: 45, height: 45)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 15))

                VStack(alignment: .leading, spacing: 3) {
                    Text(profileName)
                        .font(.headline)
                    Text("PERSONAL SPACE")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Menu {
                ForEach(favoriteApps) { app in
                    Button {
                        QuickLaunchService.open(app)
                    } label: {
                        Label(app.name, systemImage: app.symbol)
                    }
                }
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 43, height: 43)
                    .background(.background, in: Circle())
            }
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

                Text("PERSONAL SPACE")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.5), in: Capsule())
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
                    Color.accentColor.opacity(0.14),
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
                    .foregroundStyle(Color.accentColor)
            }

            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 45, height: 45)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Get Ready")
                        .font(.headline)
                    Text("Leave the scroll behind.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Button {
                if routineStartedAt == 0 {
                    routineStartedAt = Date().timeIntervalSince1970
                } else {
                    lastRoutineMinutes = max(
                        1,
                        Int((Date().timeIntervalSince1970 - routineStartedAt) / 60)
                    )
                    routineStartedAt = 0
                }
            } label: {
                Label(
                    routineStartedAt == nil ? "Start routine" : "Finish routine",
                    systemImage: routineStartedAt == nil ? "play.fill" : "checkmark"
                )
                .font(.subheadline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
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
            .tint(.accentColor)

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
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
            }
            .buttonStyle(.plain)

            if cameraExpanded {
                SloopyCCTVPlayer(cameraID: selectedCamera)

                Text("Playback depends on the stream owner's YouTube embed permissions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let camera = cameras.first(where: { $0.id == selectedCamera }),
                   let url = URL(string: "https://www.youtube.com/watch?v=\\(camera.id)") {
                    Link("Open in YouTube", destination: url)
                        .font(.caption.bold())
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22))
    }
}

private struct HomeSectionCard: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: symbol)
                .font(.system(size: 23))
                .foregroundStyle(Color.accentColor)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(.secondary)
                Text(subtitle)
                    .font(.caption)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(15)
        .background(.background, in: RoundedRectangle(cornerRadius: 21))
    }
}
