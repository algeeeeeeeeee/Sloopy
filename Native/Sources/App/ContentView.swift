import SwiftUI

enum SloopyTab: String, CaseIterable, Identifiable {
    case home, discover, notes, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .discover: "Discover"
        case .notes: "Notes"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house.fill"
        case .discover: "safari"
        case .notes: "note.text"
        case .settings: "slider.horizontal.3"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: SloopyTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home: SloopyHomeScreen()
                case .discover: DiscoverScreen()
                case .notes: NotesScreen()
                case .settings: SettingsScreen()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 5) {
                ForEach(SloopyTab.allCases) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: tab.symbol)
                                .font(.system(size: 18, weight: .semibold))
                            Text(tab.title)
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(selectedTab == tab ? Color.accentColor : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.accentColor.opacity(0.12))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(7)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
            .shadow(color: .black.opacity(0.08), radius: 18, y: 7)
            .padding(.horizontal, 22)
            .padding(.bottom, 10)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .preferredColorScheme(nil)
    }
}

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SLOOPY!")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(.secondary)
                        Text("Your daily space.")
                            .font(.system(size: 27, weight: .bold, design: .rounded))
                    }
                    Spacer()
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("A little space for yourself.")
                        .font(.title2.bold())
                    Text("Take today at your own pace.")
                        .foregroundStyle(.secondary)
                    Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))

                HomeCard(title: "Weather", subtitle: "Your local forecast", symbol: "cloud.sun.fill")
                HomeCard(title: "Get Ready", subtitle: "A gentle moment for yourself", symbol: "sparkles")
                HomeCard(title: "Camera", subtitle: "Your selected live camera", symbol: "video.fill")
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 110)
        }
    }
}

struct HomeCard: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .foregroundStyle(Color.accentColor)
                .frame(width: 48, height: 48)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 15))

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 21))
    }
}

struct PlaceholderPage: View {
    let title: String
    let symbol: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 38))
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.largeTitle.bold())
            Text("Your space is being prepared.")
                .foregroundStyle(.secondary)
        }
    }
}
