import SwiftUI
import FamilyControls

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
        case .work: "Keep distractions paused until your task is done."
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

    @State private var selection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    @State private var isWorking = false
    @State private var errorMessage: String?
    @State private var diagnosticsMessage: String?
    @State private var shieldTestMessage: String?
    @State private var authorizationLogsMessage: String?
    @State private var isCapturingAuthorizationLogs = false

    private let focusService = SloopyFocusService.shared

    private var isModeActive: Bool {
        activeMode == mode.rawValue
    }

    private var anotherModeIsActive: Bool {
        !activeMode.isEmpty && activeMode != mode.rawValue
    }

    private var selectionCount: Int {
        selection.applicationTokens.count
            + selection.webDomainTokens.count
            + selection.categoryTokens.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    introCard

                    if mode == .work {
                        workGoalCard
                    }

                    selectionCard

                    VStack(alignment: .leading, spacing: 10) {
                        Text("DIAGNOSTICS")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(.secondary)

                        Button {
                            isPickerPresented = true
                        } label: {
                            Label("Try picker anyway", systemImage: "square.grid.2x2")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            runUncheckedShieldTest()
                        } label: {
                            Label("Try shield test", systemImage: "hand.raised.slash")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            focusService.clearShields()
                            shieldTestMessage = "clearShields(): called"
                        } label: {
                            Label("Clear shields", systemImage: "shield.slash")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            diagnosticsMessage = SloopyDiagnostics.runtimeEntitlementsReport()
                        } label: {
                            Label("Diagnostics", systemImage: "stethoscope")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            Task { await captureAuthorizationLogs() }
                        } label: {
                            Label("Capture logs around authorization", systemImage: "doc.text.magnifyingglass")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isCapturingAuthorizationLogs)


                        if let shieldTestMessage {
                            Text(shieldTestMessage)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.background, in: RoundedRectangle(cornerRadius: 13))
                        }

                        if let diagnosticsMessage {
                            Text(diagnosticsMessage)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.background, in: RoundedRectangle(cornerRadius: 13))
                        }

                        if let authorizationLogsMessage {
                            Text(authorizationLogsMessage)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.background, in: RoundedRectangle(cornerRadius: 13))
                        }
                    }
                    .padding(15)
                    .background(.background, in: RoundedRectangle(cornerRadius: 20))

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption.monospaced())
                            .foregroundStyle(.orange)
                            .textSelection(.enabled)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                    }

                    if isModeActive {
                        activeControls
                    } else if anotherModeIsActive {
                        Label("Another focus session is already active. Finish it before starting this one.",
                              systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        startButton
                    }

                    Text("Sloopy pauses only the apps and websites you select. Your phone remains usable for everything else.")
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
            .sheet(isPresented: $isPickerPresented) {
                NavigationStack {
                    FamilyActivityPicker(selection: $selection)
                        .navigationTitle("Choose distractions")
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { isPickerPresented = false }
                            }
                        }
                }
            }
            .onAppear {
                selection = focusService.loadSelection()
                if isModeActive {
                    try? focusService.applySelection(selection)
                }
            }
            .onChange(of: selection) { _, newSelection in
                focusService.saveSelection(newSelection)
                if isModeActive {
                    try? focusService.applySelection(newSelection)
                }
            }
        }
    }

    private var introCard: some View {
        HStack(spacing: 13) {
            Image(systemName: mode.symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 48, height: 48)
                .background(Color.accentColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 15))

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
                    .tint(.accentColor)
            } else {
                Text("You’ll mark this task complete before ending Work Mode.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(15)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private var selectionCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DISTRACTION LIST")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.secondary)
                    Text(selectionCount == 0
                         ? "No apps or websites selected"
                         : "\(selectionCount) selections saved")
                        .font(.subheadline.weight(.semibold))
                }

                Spacer()

                Image(systemName: "hand.raised.slash.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
            }

            Button {
                requestAccessAndChoose()
            } label: {
                Label("Choose apps & websites", systemImage: "square.grid.2x2")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(isWorking)

            Text("Use the Apple picker to select the social apps, categories, or sites you want Sloopy to pause.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(15)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private var startButton: some View {
        Button {
            Task { await startSession() }
        } label: {
            HStack {
                if isWorking {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "play.fill")
                }
                Text(mode == .work ? "Start Work Mode" : "Start Get Ready")
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(
            isWorking
            || selectionCount == 0
            || (mode == .work && workGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        )
        .opacity(
            (selectionCount == 0
             || (mode == .work && workGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                ? 0.55 : 1
        )
    }

    @ViewBuilder
    private var activeControls: some View {
        if mode == .work {
            VStack(alignment: .leading, spacing: 10) {
                Label("Work Mode is active. Selected distractions are paused.", systemImage: "checkmark.shield.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)

                Button {
                    finishSession()
                } label: {
                    Label("Finish task & end Work Mode", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(13)
                        .background(Color.accentColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 13))
                }
                .buttonStyle(.plain)
                .disabled(!workGoalComplete)
                .opacity(workGoalComplete ? 1 : 0.5)

                if !workGoalComplete {
                    Text("Tick “I have completed this task” above to restore the selected apps.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Label("Get Ready focus is active.", systemImage: "checkmark.shield.fill")
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

                Button {
                    finishSession()
                } label: {
                    Label("Finish Get Ready", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(13)
                        .background(Color.accentColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 13))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @MainActor
    private func runUncheckedShieldTest() {
        let savedSelection = focusService.loadSelection()

        do {
            try focusService.applySelectionUnchecked(savedSelection)
            shieldTestMessage = "applySelectionUnchecked: success"
        } catch {
            shieldTestMessage = String(reflecting: error)
        }
    }

    @MainActor
    private func captureAuthorizationLogs() async {
        isCapturingAuthorizationLogs = true
        defer { isCapturingAuthorizationLogs = false }

        let requestStartedAt = Date()
        let authorizationResult: String

        do {
            try await focusService.requestAuthorization()
            authorizationResult = "requestAuthorization: success"
        } catch {
            authorizationResult = """
            requestAuthorization error:
            \(SloopyDiagnostics.authorizationFailureReport(for: error))
            """
        }

        try? await Task.sleep(nanoseconds: 1_000_000_000)

        let capturedLogs = await SloopyDiagnostics.captureCurrentProcessLogs(
            around: requestStartedAt
        )
        authorizationLogsMessage = """
        \(authorizationResult)

        Entries in requested time window: \(capturedLogs.entryCount)
        (Up to 200 lines and 12,000 characters are displayed.)

        \(capturedLogs.text)
        """
    }

    private func requestAccessAndChoose() {
        Task {
            isWorking = true
            errorMessage = nil
            defer { isWorking = false }

            do {
                try await focusService.requestAuthorization()
                isPickerPresented = true
            } catch {
                errorMessage = """
                Family Controls permission is needed. This app’s Family Controls capability must be approved by Apple; a child account may also need a parent or guardian to approve the system request.

                \(SloopyDiagnostics.authorizationFailureReport(for: error))
                """
            }
        }
    }

    @MainActor
    private func startSession() async {
        guard selectionCount > 0 else { return }
        guard !anotherModeIsActive else { return }

        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            try await focusService.requestAuthorization()
            try focusService.applySelection(selection)

            activeMode = mode.rawValue
            if mode == .getReady {
                routineStartedAt = Date().timeIntervalSince1970
            } else {
                workStartedAt = Date().timeIntervalSince1970
                workGoalComplete = false
            }

            dismiss()
        } catch {
            errorMessage = """
            Sloopy couldn’t activate app limits. Check that Family Controls is enabled for this app and approved for your Apple developer team.

            \(SloopyDiagnostics.authorizationFailureReport(for: error))
            """
        }
    }

    private func finishSession() {
        focusService.clearShields()

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
