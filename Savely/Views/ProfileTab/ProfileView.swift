import SwiftUI
import SwiftData

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query(sort: \IncomeModel.date, order: .reverse) private var incomes: [IncomeModel]
    @Query private var expenses: [ExpenseModel]
    @Query private var goals: [GoalModel]
    @State private var showingAchievements = false
    @State private var showingReports = false
    @State private var showingTipHistory = false
    @State private var showingDeleteDialog = false
    @State private var showingDeleteFinalConfirm = false

    private var lifetimeIncome: Double { incomes.reduce(0) { $0 + $1.amount } }

    // "Saving since <month>" — the first movement ever logged. Nothing
    // logged yet is a deliberate state, not an empty label.
    private var savingSinceSubtitle: String {
        let firstDate = (incomes.map(\.date) + expenses.map(\.date)).min()
        guard let firstDate else { return Strings.Profile.justStartedLabel }
        let month = firstDate.formatted(.dateTime.month(.wide).year())
        return String(format: Strings.Profile.savingSinceLabel, month)
    }

    private var totalSaved: Double { goals.reduce(0) { $0 + $1.current } }
    private var movementCount: Int { incomes.count + expenses.count }
    private var activeGoalCount: Int { goals.filter { $0.progress < 1 }.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                lifetimeIncomeCard
                    .padding(.top, 8)

                statsStrip

                achievementsCard

                settingsSection

                dataPrivacySection

                if FeatureFlags.tipsEnabled {
                    ProfileSection(header: "About") {
                        SettingsNavRow(icon: "sparkles", title: "Tip history", detail: "128 tips", onTap: { showingTipHistory = true })
                    }
                }

                Spacer(minLength: 16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.warmBg)
        .navigationBarHidden(true)
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text(Strings.Errors.noticeLabel), message: Text(viewModel.alertMessage), dismissButton: .default(Text(Strings.Buttons.okButton)))
        }
        .confirmationDialog(
            Strings.Profile.deleteAllDataConfirmTitle,
            isPresented: $showingDeleteDialog,
            titleVisibility: .visible
        ) {
            Button(Strings.Profile.deleteAllDataConfirmButton, role: .destructive) { showingDeleteFinalConfirm = true }
            Button(Strings.Buttons.cancelButton, role: .cancel) {}
        } message: {
            Text(Strings.Profile.deleteAllDataConfirmMessage)
        }
        // Second, explicit confirm — deleting is the one irreversible thing here.
        .alert(Strings.Profile.deleteAllDataConfirmTitle, isPresented: $showingDeleteFinalConfirm) {
            Button(Strings.Profile.deleteAllDataConfirmButton, role: .destructive) { viewModel.deleteAllData() }
            Button(Strings.Buttons.cancelButton, role: .cancel) {}
        } message: {
            Text(Strings.Profile.deleteAllDataConfirmMessage)
        }
        .navigationDestination(isPresented: $showingAchievements) { AchievementsView() }
        .navigationDestination(isPresented: $showingReports) { ReportsView() }
        .navigationDestination(isPresented: $showingTipHistory) { TipHistoryView() }
        .onAppear { viewModel.setModelContext(modelContext) }
        .task { await viewModel.refreshReminderState() }
    }

    // MARK: - Lifetime income

    private var lifetimeIncomeCard: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(Color.warmOnGreen.opacity(0.08))
                .frame(width: 140, height: 140)
                .offset(x: 30, y: -20)

            VStack(alignment: .leading, spacing: 4) {
                Text("LIFETIME INCOME")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.warmOnGreen.opacity(0.7))
                    .tracking(0.8)
                Text(formattedAmount(lifetimeIncome))
                    .font(.system(size: 40, weight: .regular, design: .serif))
                    .foregroundStyle(Color.warmOnGreen)
                Text(savingSinceSubtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.warmOnGreen.opacity(0.75))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .background(Color.warmGreenFill)
        .cornerRadius(22)
        .clipped()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Stats

    private var statsStrip: some View {
        HStack(spacing: 10) {
            ProfileStatCell(label: Strings.Profile.statSavedLabel, value: formattedAmount(totalSaved))
            ProfileStatCell(label: Strings.Profile.statMovementsLabel, value: "\(movementCount)")
            ProfileStatCell(label: Strings.Profile.statActiveGoalsLabel, value: "\(activeGoalCount)")
        }
    }

    // MARK: - Achievements

    private var achievementStates: [AchievementState] {
        AchievementEngine.evaluate(AchievementInput(
            incomeTotal: lifetimeIncome,
            incomeCount: incomes.count,
            expenseCount: expenses.count,
            loggedDates: incomes.map(\.date) + expenses.map(\.date),
            goalCount: goals.count,
            bestGoalProgress: goals.map(\.progress).max() ?? 0,
            completedGoalCount: goals.filter { $0.progress >= 1 }.count
        ))
    }

    private var unlockedAchievements: [AchievementState] { achievementStates.filter(\.unlocked) }

    /// The locked achievement the user is closest to — one row with a real
    /// bar beats a grid of padlocks on a fresh install.
    private var nextAchievement: AchievementState? {
        achievementStates.filter { !$0.unlocked }.max { $0.progress < $1.progress }
    }

    private var achievementsCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Achievements")
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundStyle(Color.warmInk)
                Spacer()
                Button(action: { showingAchievements = true }) {
                    Text("See all ›")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.warmGreen)
                }
            }

            if !unlockedAchievements.isEmpty {
                HStack(spacing: 10) {
                    ForEach(unlockedAchievements.prefix(6)) { state in
                        BadgeTile(icon: state.icon, bg: state.tileBackground, color: state.tileColor, unlocked: true)
                            .accessibilityLabel(state.title)
                    }
                    if unlockedAchievements.count < 6 {
                        Spacer(minLength: 0)
                    }
                }
            }

            if let next = nextAchievement {
                NextAchievementRow(state: next)
            } else {
                Text(Strings.Profile.allAchievementsUnlockedLabel)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.warmInkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(Color.warmSurface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.warmLine, lineWidth: 1))
    }

    // MARK: - Settings

    private var settingsSection: some View {
        ProfileSection(header: "Settings") {
            if viewModel.notificationsDenied {
                NotificationsDeniedRow(onOpenSettings: {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                })
            } else {
                SettingsToggleRow(
                    icon: "bell.fill",
                    title: Strings.Profile.expenseRemindersLabel,
                    isOn: reminderEnabledBinding(.expense)
                )
                if viewModel.reminders.expenseEnabled {
                    ReminderTimeRow(time: reminderTimeBinding(.expense))
                }
                WarmDivider()
                SettingsToggleRow(
                    icon: "target",
                    title: Strings.Profile.goalAlertsLabel,
                    isOn: reminderEnabledBinding(.goal)
                )
                if viewModel.reminders.goalEnabled {
                    ReminderTimeRow(time: reminderTimeBinding(.goal))
                }
            }
            if FeatureFlags.darkModeEnabled {
                WarmDivider()
                SettingsToggleRow(icon: "moon.fill", title: Strings.Profile.darkModeLabel, isOn: $viewModel.darkMode)
            }
        }
    }

    private func reminderEnabledBinding(_ kind: ReminderKind) -> Binding<Bool> {
        Binding(
            get: { viewModel.reminders.isEnabled(kind) },
            set: { viewModel.setReminder(kind, enabled: $0) }
        )
    }

    private func reminderTimeBinding(_ kind: ReminderKind) -> Binding<Date> {
        Binding(
            get: { viewModel.reminders.time(for: kind) },
            set: { viewModel.setReminder(kind, time: $0) }
        )
    }

    // MARK: - Data & privacy

    private var dataPrivacySection: some View {
        ProfileSection(header: Strings.Profile.dataPrivacyTitle) {
            HStack(spacing: 16) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.warmGreen)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                Text(Strings.Profile.dataStaysLocalLabel)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.warmInkSoft)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            WarmDivider()
            SettingsNavRow(icon: "doc.text.fill", title: "Weekly PDF report", onTap: { viewModel.generateWeeklyReportPDF() })
            WarmDivider()
            SettingsNavRow(icon: "chart.bar", title: "Reports", onTap: { showingReports = true })
            WarmDivider()
            SettingsNavRow(icon: "trash", title: Strings.Profile.deleteAllDataLabel, color: Color.warmClay, onTap: { showingDeleteDialog = true })
        }
    }

    private func formattedAmount(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency; f.currencySymbol = "$"; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "$0"
    }
}

// MARK: - Stat cell

struct ProfileStatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.warmInkMuted)
                .tracking(0.8)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.system(size: 20, weight: .regular, design: .serif))
                .foregroundStyle(Color.warmInk)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.warmSurface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.warmLine, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Next achievement row

struct NextAchievementRow: View {
    let state: AchievementState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Profile.nextAchievementLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.warmInkMuted)
                .tracking(0.8)
                .textCase(.uppercase)

            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(state.tileBackground)
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: state.icon).font(.system(size: 15)).foregroundStyle(state.tileColor))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(state.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.warmInk)
                    Text(state.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.warmInkSoft)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.warmGreenSoft).frame(height: 4)
                            Capsule().fill(Color.warmGreen)
                                .frame(width: geo.size.width * state.progress, height: 4)
                        }
                    }
                    .frame(height: 4)
                    .padding(.top, 2)
                }
                Spacer()
                Text("\(Int(state.progress * 100))%")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.warmInkSoft)
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue("\(Int(state.progress * 100)) percent")
    }
}

// MARK: - Notifications denied row

struct NotificationsDeniedRow: View {
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 18))
                .foregroundStyle(Color.warmInkSoft)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(Strings.Profile.notificationsDeniedHint)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.warmInkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: onOpenSettings) {
                    Text(Strings.Profile.openSettingsButton)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.warmGreen)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

// MARK: - Reminder time row

struct ReminderTimeRow: View {
    @Binding var time: Date

    var body: some View {
        HStack(spacing: 16) {
            Color.clear.frame(width: 28)
            Text(Strings.Profile.reminderTimeLabel)
                .font(.system(size: 14))
                .foregroundStyle(Color.warmInkSoft)
            Spacer()
            DatePicker(Strings.Profile.reminderTimeLabel, selection: $time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(Color.warmGreen)
        }
        .padding(.horizontal, 16).padding(.bottom, 12)
    }
}

// MARK: - Badge Tile

struct BadgeTile: View {
    let icon: String; let bg: Color; let color: Color; let unlocked: Bool
    var body: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(bg)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(unlocked ? Color.clear : Color.warmLine, lineWidth: 1))
            .overlay(Image(systemName: icon).font(.system(size: 18, weight: unlocked ? .semibold : .regular)).foregroundStyle(color))
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Profile Section wrapper

struct ProfileSection<Content: View>: View {
    let header: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.warmInkMuted)
                .tracking(0.8)
                .padding(.leading, 4)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) { content() }
                .background(Color.warmSurface)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.warmLine, lineWidth: 1))
        }
    }
}

struct WarmDivider: View {
    var body: some View {
        Rectangle().fill(Color.warmLineSoft).frame(height: 1).padding(.leading, 60)
    }
}

// MARK: - Settings rows (redesigned)

/// The `Toggle` owns the title so VoiceOver reads
/// "<title>, switch, on" — never `Toggle("")`.
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.warmInkSoft)
                .frame(width: 28)
                .accessibilityHidden(true)
            Toggle(isOn: $isOn) {
                Text(title).font(.system(size: 14, weight: .medium)).foregroundStyle(Color.warmInk)
            }
            .tint(Color.warmGreen)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

struct SettingsNavRow: View {
    let icon: String
    let title: String
    var detail: String? = nil
    var color: Color = Color.warmInkSoft
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                    .frame(width: 28)
                Text(title).font(.system(size: 14, weight: .medium)).foregroundStyle(color == Color.warmInkSoft ? Color.warmInk : color)
                Spacer()
                if let d = detail {
                    Text(d).font(.system(size: 13)).foregroundStyle(Color.warmInkMuted)
                }
                if color != Color.warmClay {
                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Color.warmInkMuted)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { ProfileView() }
        .environmentObject(AppViewModel())
}
