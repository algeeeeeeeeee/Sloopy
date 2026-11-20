import SwiftUI

enum SloopyFocusMode: String, Identifiable {
    case getReady = "get-ready"
    case work = "work"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .getReady: "Get Ready"
        case .work: "Work Mode"
        }
    }

    var subtitle: String {
        switch self {
        case .getReady: "Give yourself a quieter start."
        case .work: "Set one clear goal and protect time for it."
        }
    }

    var symbol: String {
        switch self {
        case .getReady: "sunrise.fill"
        case .work: "briefcase.fill"
        }
    }
}

struct FocusModeSheet: View {
    @AppStorage("sloopy-native-accent") private var accent = "blue"
    @AppStorage("sloopy-native-accent-hex") private var accentHex = "#7898AA"
    private var accentColor: Color { SloopyPalette.color(for: accent, customHex: accentHex) }

    @Environment(\.dismiss) private var dismiss

    let mode: SloopyFocusMode

    @AppStorage("sloopy-focus-active-mode")
    private var activeMode = ""

    @AppStorage("sloopy-native-routine-start")
    private var routineStartedAt = 0.0

    @AppStorage("sloopy-native-routine-last-minutes")
    private var lastRoutineMinutes = 0

    @AppStorage("sloopy-work-mode-goal")
    private var workGoal = ""

    @AppStorage("sloopy-work-mode-goal-complete")
    private var workGoalComplete = false

    @AppStorage("sloopy-work-mode-started-at")
    private var workStartedAt = 0.0

    private var isModeActive: Bool {
        activeMode == mode.rawValue
    }

    private var anotherModeIsActive: Bool {
        !activeMode.isEmpty && activeMode != mode.rawValue
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    introCard

                    if mode == .work {
                        workGoalCard
                    }

                    downtimeGuideCard

                    if isModeActive {
                        activeControls
                    } else if anotherModeIsActive {
                        Label("Another focus session is already active. Finish it before starting this one.",
                              systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(13)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.background, in: RoundedRectangle(cornerRadius: 14))
                    } else {
                        startButton
                    }

                    Text("Your session, timer, and task are saved locally by Sloopy. Downtime is controlled separately in iPhone Settings.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var introCard: some View {
        HStack(spacing: 13) {
            Image(systemName: mode.symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(accentColor)
                .frame(width: 48, height: 48)
                .background(accentColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 15))

            VStack(alignment: .leading, spacing: 4) {
                Text(mode.title)
                    .font(.headline)
                Text(mode.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if isModeActive {
                Circle()
                    .fill(.green)
                    .frame(width: 9, height: 9)
            }
        }
        .padding(15)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private var workGoalCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("YOUR MAIN TASK")
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundStyle(.secondary)

            TextField("What must be finished today?", text: $workGoal, axis: .vertical)
                .lineLimit(2...4)
                .padding(12)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                .disabled(isModeActive)

            if isModeActive {
                Toggle("I have completed this task", isOn: $workGoalComplete)
                    .font(.subheadline.weight(.medium))
                    .tint(accentColor)
            } else {
                Text("You’ll mark this task complete before ending Work Mode.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(15)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private var downtimeGuideCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            Label("iPhone Screen Time · Downtime", systemImage: "hourglass")
                .font(.headline)
                .foregroundStyle(accentColor)

            Text("Sloopy can’t change Apple’s Downtime settings. Set this once in iPhone Settings and iOS will enforce your schedule.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Label("Open Settings → Screen Time", systemImage: "1.circle.fill")
                .font(.subheadline.weight(.medium))

            Label("Tap Downtime → Scheduled, then choose your days and hours", systemImage: "2.circle.fill")
                .font(.subheadline.weight(.medium))

            Label("Turn on Block at Downtime", systemImage: "3.circle.fill")
                .font(.subheadline.weight(.medium))

            Label("Set essential apps under Always Allowed", systemImage: "4.circle.fill")
                .font(.subheadline.weight(.medium))
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private var startButton: some View {
        Button(action: startSession) {
            Label(
                mode == .work ? "Start Work Mode" : "Start Get Ready",
                systemImage: "play.fill"
            )
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(accentColor, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(mode == .work && workGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(mode == .work && workGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
    }

    @ViewBuilder
    private var activeControls: some View {
        if mode == .work {
            VStack(alignment: .leading, spacing: 10) {
                Label("Work Mode is active. Stay with your main task.", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)

                if workStartedAt > 0 {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let elapsed = max(0, Int(context.date.timeIntervalSince1970 - workStartedAt))
                        Text("In progress · \(elapsed / 60) min \(elapsed % 60) sec")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                Button(action: finishSession) {
                    Label("Finish task & end Work Mode", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(13)
                        .background(accentColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 13))
                }
                .buttonStyle(.plain)
                .disabled(!workGoalComplete)
                .opacity(workGoalComplete ? 1 : 0.5)

                if !workGoalComplete {
                    Text("Tick “I have completed this task” above when your task is done.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(15)
            .background(.background, in: RoundedRectangle(cornerRadius: 20))
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Label("Get Ready session is active.", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)

                if routineStartedAt > 0 {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let elapsed = max(0, Int(context.date.timeIntervalSince1970 - routineStartedAt))
                        Text("Elapsed · \(elapsed / 60) min \(elapsed % 60) sec")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                Button(action: finishSession) {
                    Label("Finish Get Ready", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(13)
                        .background(accentColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 13))
                }
                .buttonStyle(.plain)
            }
            .padding(15)
            .background(.background, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private func startSession() {
        guard !anotherModeIsActive else { return }

        if mode == .work {
            guard !workGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            workStartedAt = Date().timeIntervalSince1970
            workGoalComplete = false
        } else {
            routineStartedAt = Date().timeIntervalSince1970
        }

        activeMode = mode.rawValue
    }

    private func finishSession() {
        if mode == .getReady, routineStartedAt > 0 {
            lastRoutineMinutes = max(
                1,
                Int((Date().timeIntervalSince1970 - routineStartedAt) / 60)
            )
            routineStartedAt = 0
        } else if mode == .work {
            workStartedAt = 0
            workGoalComplete = false
        }

        activeMode = ""
        dismiss()
    }
}
