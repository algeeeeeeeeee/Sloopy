
import SwiftUI

private struct DiscoveryFact: Identifiable {
    let id: Int
    let category: String
    let title: String
    let teaser: String
    let unlocked: String
    let body: String
    let question: String
    let options: [String]
    let answer: String
    let source: String
    let sourceName: String
    let art: String
    let planet: String

    static let all: [DiscoveryFact] = [
        .init(id: 1, category: "SPACE & SCIENCE",
              title: "A day longer than a year?",
              teaser: "Venus has a surprisingly slow spin.",
              unlocked: "Venus has a longer day than year.",
              body: "One complete rotation of Venus takes about 243 Earth days, while one orbit around the Sun takes about 225 Earth days. Venus also rotates in the opposite direction to most planets.",
              question: "How long does one rotation of Venus take?",
              options: ["225 Earth days", "243 Earth days", "365 Earth days"],
              answer: "243 Earth days",
              source: "https://science.nasa.gov/venus/venus-facts/",
              sourceName: "NASA Science · Venus Facts",
              art: "🪐", planet: "VENUS"),

        .init(id: 2, category: "SPACE & SCIENCE",
              title: "The Sun has its own rotation.",
              teaser: "Even our star spins at different speeds.",
              unlocked: "The Sun rotates at different speeds.",
              body: "The Sun rotates about once every 25 Earth days at its equator and about every 36 Earth days near its poles.",
              question: "About how long does the Sun take to rotate at its equator?",
              options: ["12 days", "25 days", "60 days"],
              answer: "25 days",
              source: "https://science.nasa.gov/sun/facts/",
              sourceName: "NASA Science · Sun Facts",
              art: "☀️", planet: "THE SUN"),

        .init(id: 3, category: "SPACE & SCIENCE",
              title: "A very long galactic year.",
              teaser: "Our solar system is always travelling around the Milky Way.",
              unlocked: "The solar system orbits the Milky Way.",
              body: "Our solar system takes about 230 million Earth years to complete one orbit around the center of the Milky Way galaxy.",
              question: "About how long is one solar orbit around the Milky Way?",
              options: ["230 thousand years", "23 million years", "230 million years"],
              answer: "230 million years",
              source: "https://science.nasa.gov/solar-system/solar-system-facts/",
              sourceName: "NASA Science · Solar System Facts",
              art: "🌌", planet: "MILKY WAY"),

        .init(id: 4, category: "OCEAN & NATURE",
              title: "Some ocean animals make their own light.",
              teaser: "The deep ocean has its own natural glow.",
              unlocked: "Bioluminescence is living light.",
              body: "Bioluminescence is light produced by a living organism through a chemical reaction. In the ocean, it can help animals attract prey, communicate, or avoid predators.",
              question: "What creates bioluminescence?",
              options: ["A chemical reaction in an organism", "Reflected sunlight", "Tiny batteries"],
              answer: "A chemical reaction in an organism",
              source: "https://oceanservice.noaa.gov/facts/biolum.html",
              sourceName: "NOAA Ocean Service · Bioluminescence",
              art: "🪼", planet: "LIVING LIGHT"),

        .init(id: 5, category: "OCEAN & NATURE",
              title: "The deep ocean is chilly.",
              teaser: "Sunlight and warmth become scarce as you go down.",
              unlocked: "Deep ocean water is cold.",
              body: "Below about 200 meters, deep ocean water has an average temperature of around 4°C (39°F), although conditions vary by place and depth.",
              question: "What is the approximate average temperature below about 200 m?",
              options: ["4°C", "14°C", "24°C"],
              answer: "4°C",
              source: "https://oceanexplorer.noaa.gov/ocean-fact/deep-habitat/",
              sourceName: "NOAA Ocean Exploration · Deep Habitat",
              art: "🌊", planet: "DEEP OCEAN"),

        .init(id: 6, category: "OCEAN & NATURE",
              title: "The ocean has layers of light.",
              teaser: "Sunlight fades faster underwater than you might expect.",
              unlocked: "Significant sunlight rarely reaches far below 200 meters.",
              body: "Under ideal conditions, sunlight may be detected as far as 1,000 meters underwater, but there is rarely significant light beyond about 200 meters.",
              question: "At what depth does significant sunlight rarely remain?",
              options: ["20 meters", "200 meters", "2,000 meters"],
              answer: "200 meters",
              source: "https://oceanservice.noaa.gov/facts/light_travel.html",
              sourceName: "NOAA Ocean Service · Light in the Ocean",
              art: "💧", planet: "OCEAN LIGHT"),

        .init(id: 7, category: "OCEAN & NATURE",
              title: "A glowing world below the surface.",
              teaser: "Many animals in the open-ocean water column can produce light.",
              unlocked: "Bioluminescence is common in the open ocean.",
              body: "NOAA describes bioluminescence as very common in the pelagic zone. One NOAA resource estimates that about 80% of animals living between 200 and 1,000 meters are bioluminescent.",
              question: "Which zone is being described?",
              options: ["The pelagic water column", "A freshwater lake", "A forest canopy"],
              answer: "The pelagic water column",
              source: "https://oceanexplorer.noaa.gov/ocean-fact/bioluminescence/",
              sourceName: "NOAA Ocean Exploration · Bioluminescence",
              art: "✨", planet: "PELAGIC ZONE")
    ]
}

struct DiscoverScreen: View {
    @Environment(\.tint) private var tint

    private var accentColor: Color { tint ?? .blue }

    @AppStorage("sloopy-native-discovery-date")
    private var savedDate = ""

    @AppStorage("sloopy-native-discovery-revealed")
    private var revealed = false

    @AppStorage("sloopy-native-discovery-answered")
    private var answered = false

    @AppStorage("sloopy-native-discovery-answer")
    private var selectedAnswer = ""

    @AppStorage("sloopy-native-discovery-claimed")
    private var claimed = false

    @AppStorage("sloopy-native-stamps")
    private var stamps = 0

    private var todayKey: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: .now)
    }

    private var factIndex: Int {
        let day = Calendar.current.ordinality(
            of: .day,
            in: .year,
            for: .now
        ) ?? 1

        return (day - 1) % DiscoveryFact.all.count
    }

    private var fact: DiscoveryFact {
        DiscoveryFact.all[factIndex]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                header
                hero
                factCard

                if revealed {
                    revealCard
                    quizCard
                }

                stampCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 110)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear {
            prepareToday()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("DAILY COLLECTION · DAY \(factIndex + 1)")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.3)
                .foregroundStyle(.secondary)

            Text("Daily Discovery.")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text("A new little surprise, every day.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var hero: some View {
        VStack(spacing: 9) {
            Text(fact.art)
                .font(.system(size: 55))

            Text(fact.planet)
                .font(.system(size: 15, weight: .bold))
                .tracking(2)

            Text("TODAY'S DISCOVERY")
                .font(.system(size: 9, weight: .bold))
                .tracking(1.5)
                .opacity(0.65)
        }
        .foregroundStyle(accentColor)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 25)
        .background(
            LinearGradient(
                colors: [
                    accentColor.opacity(0.17),
                    Color(uiColor: .secondarySystemGroupedBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 23)
        )
    }

    private var factCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(fact.category)
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundStyle(accentColor)

            Text(fact.title)
                .font(.title3.bold())

            Text(fact.teaser)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !revealed {
                Button(action: { revealed = true }) {
                    Label("Reveal today's discovery", systemImage: "sparkles")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(13)
                        .background(accentColor, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
        }
        .padding(17)
        .background(.background, in: RoundedRectangle(cornerRadius: 21))
    }

    private var revealCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            Label("DISCOVERY UNLOCKED", systemImage: "lock.open.fill")
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundStyle(accentColor)

            Text(fact.unlocked)
                .font(.headline)

            Text(fact.body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)

            Link(destination: URL(string: fact.source)!) {
                Label("Read \(fact.sourceName)", systemImage: "arrow.up.right")
                    .font(.caption.bold())
            }
            .padding(.top, 4)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 21))
    }

    private var quizCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("QUICK QUIZ", systemImage: "questionmark.circle.fill")
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundStyle(accentColor)

            Text(fact.question)
                .font(.headline)

            ForEach(fact.options, id: \.self) { option in
                Button {
                    guard !answered else { return }
                    selectedAnswer = option
                } label: {
                    HStack {
                        Text(option)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        if selectedAnswer == option {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .foregroundStyle(selectedAnswer == option ? accentColor : Color.primary)
                    .padding(13)
                    .background(
                        selectedAnswer == option
                            ? accentColor.opacity(0.12)
                            : Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 13)
                    )
                }
                .buttonStyle(.plain)
                .disabled(answered)
            }

            if answered {
                Label(
                    claimed ? "Correct! Your daily stamp is saved." : "Answer saved. Come back tomorrow!",
                    systemImage: claimed ? "checkmark.seal.fill" : "checkmark.circle"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(claimed ? Color.green : Color.secondary)
                .padding(.top, 5)
            } else {
                Button(action: checkAnswer) {
                    Text("Check answer")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(13)
                        .background(accentColor, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(selectedAnswer.isEmpty)
                .opacity(selectedAnswer.isEmpty ? 0.5 : 1)
            }
        }
        .padding(17)
        .background(.background, in: RoundedRectangle(cornerRadius: 21))
    }

    private var stampCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("STAMP COLLECTION")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)

                Spacer()

                Text("\(stamps) stamps")
                    .font(.caption.bold())
                    .foregroundStyle(accentColor)
            }

            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    Image(systemName: index < stamps ? "sparkle" : "circle")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(
                            index < stamps ? accentColor : Color.secondary.opacity(0.3)
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            accentColor.opacity(index < stamps ? 0.12 : 0.04),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private func prepareToday() {
        guard savedDate != todayKey else { return }

        savedDate = todayKey
        revealed = false
        answered = false
        selectedAnswer = ""
        claimed = false
    }

    private func checkAnswer() {
        guard revealed, !answered, fact.options.contains(selectedAnswer) else {
            return
        }

        answered = true
        claimed = selectedAnswer == fact.answer

        if claimed {
            stamps += 1
        }
    }
}
