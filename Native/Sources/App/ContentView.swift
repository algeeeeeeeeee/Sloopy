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
    @Environment(\.tint) private var tint

    private var accentColor: Color { tint ?? .blue }

    @State private var selectedTab: SloopyTab = .home
    @AppStorage("sloopy-native-navigation-collapsed-v2")
    private var isNavigationCollapsed = true

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

            navigationDock
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var navigationDock: some View {
        HStack(spacing: isNavigationCollapsed ? 10 : 4) {
            if isNavigationCollapsed {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        isNavigationCollapsed = false
                    }
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: selectedTab.symbol)
                            .font(.system(size: 17, weight: .semibold))
                        Text(selectedTab.title)
                            .font(.system(size: 11, weight: .semibold))
                        Image(systemName: "chevron.up")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(accentColor)
                    .frame(height: 40)
                    .padding(.horizontal, 12)
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Expand navigation")
            } else {
                ForEach(SloopyTab.allCases) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                            selectedTab = tab
                            isNavigationCollapsed = true
                        }
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: tab.symbol)
                                .font(.system(size: 17, weight: .semibold))
                            Text(tab.title)
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(selectedTab == tab ? accentColor : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(accentColor.opacity(0.13))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.title)
                }

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        isNavigationCollapsed = true
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 29, height: 48)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Collapse navigation")
            }
        }
        .padding(7)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1))
        .shadow(color: Color.primary.opacity(0.08), radius: 18, y: 7)
        .padding(.horizontal, 22)
        .padding(.bottom, 10)
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: isNavigationCollapsed)
    }
}

struct HomeView: View {
    @Environment(\.tint) private var tint

    private var accentColor: Color { tint ?? .blue }

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
                        .foregroundStyle(accentColor)
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
    @Environment(\.tint) private var tint

    private var accentColor: Color { tint ?? .blue }

    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .foregroundStyle(accentColor)
                .frame(width: 48, height: 48)
                .background(accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 15))

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
    @Environment(\.tint) private var tint

    private var accentColor: Color { tint ?? .blue }

    let title: String
    let symbol: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 38))
                .foregroundStyle(accentColor)
            Text(title)
                .font(.largeTitle.bold())
            Text("Your space is being prepared.")
                .foregroundStyle(.secondary)
        }
    }
}
