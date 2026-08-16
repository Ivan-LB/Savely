import SwiftUI
import SwiftData

/// Achievements, driven by real data via `AchievementEngine` (2026-08 —
/// replaces the hardcoded mock). Newly unlocked badges pop once (tracked by
/// `AchievementStore`); locked badges show honest progress bars.
struct AchievementsView: View {
    @Query private var incomes: [IncomeModel]
    @Query private var expenses: [ExpenseModel]
    @Query private var goals: [GoalModel]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared = false
    @State private var celebrating: Set<String> = []

    private var states: [AchievementState] {
        AchievementEngine.evaluate(AchievementInput(
            incomeTotal: incomes.reduce(0) { $0 + $1.amount },
            incomeCount: incomes.count,
            expenseCount: expenses.count,
            loggedDates: incomes.map(\.date) + expenses.map(\.date),
            goalCount: goals.count,
            bestGoalProgress: goals.map(\.progress).max() ?? 0,
            completedGoalCount: goals.filter { $0.progress >= 1 }.count
        ))
    }

    private var earned: Int { states.filter(\.unlocked).count }

    var body: some View {
        let states = self.states
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Heading
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(earned) earned,\n\(states.count - earned) to go.")
                        .warmFont(32, weight: .regular, design: .serif)
                        .foregroundStyle(Color.warmInk)
                        .lineSpacing(2)
                    Text("Badges unlock as you save — no pressure.")
                        .warmFont(14)
                        .foregroundStyle(Color.warmInkMuted)
                }
                .padding(.top, 8)

                // Badge list — staggered entrance, capped at ~400ms total.
                VStack(spacing: 10) {
                    ForEach(Array(states.enumerated()), id: \.element.id) { index, badge in
                        AchievementRow(
                            badge: badge,
                            celebrate: celebrating.contains(badge.id),
                            animateProgress: appeared
                        )
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(
                            reduceMotion
                                ? .easeOut(duration: 0.01)
                                : .spring(response: 0.45, dampingFraction: 0.9)
                                    .delay(Double(index) * 0.04),
                            value: appeared
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color.warmBg)
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let current = states
            appeared = true
            let fresh = AchievementStore.newlyUnlocked(in: current)
            if !fresh.isEmpty {
                if reduceMotion {
                    AchievementStore.markCelebrated(current)
                } else {
                    // Let the list settle, then pop the new unlocks once.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        celebrating = fresh
                        AchievementStore.markCelebrated(current)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                            celebrating = []
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Achievement Row

struct AchievementRow: View {
    let badge: AchievementState
    let celebrate: Bool
    let animateProgress: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Icon tile — pops with a soft amber glow when newly unlocked.
            RoundedRectangle(cornerRadius: 14)
                .fill(badge.unlocked ? badge.tileBackground : Color.warmBg)
                .frame(width: 48, height: 48)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(badge.unlocked ? Color.clear : Color.warmLine, lineWidth: 1))
                .overlay(
                    Image(systemName: badge.icon)
                        .warmFont(20, weight: badge.unlocked ? .semibold : .regular)
                        .foregroundStyle(badge.unlocked ? badge.tileColor : Color.warmInkMuted)
                )
                .scaleEffect(celebrate ? 1.12 : 1)
                .shadow(
                    color: Color.warmAmber.opacity(celebrate ? 0.45 : 0),
                    radius: celebrate ? 14 : 0
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: celebrate)

            VStack(alignment: .leading, spacing: 3) {
                Text(badge.title)
                    .warmFont(14, weight: .semibold)
                    .foregroundStyle(badge.unlocked ? Color.warmInk : Color.warmInkSoft)
                Text(badge.subtitle)
                    .warmFont(12)
                    .foregroundStyle(Color.warmInkMuted)

                // Progress bar for locked badges — fills to its real value on appear.
                if !badge.unlocked {
                    HStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.warmLine)
                                    .frame(height: 4)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.warmGreen)
                                    .frame(width: geo.size.width * (animateProgress ? badge.progress : 0), height: 4)
                                    .animation(.easeOut(duration: 0.6).delay(0.15), value: animateProgress)
                            }
                        }
                        .frame(height: 4)
                        Text("\(Int(badge.progress * 100))%")
                            .warmFont(11)
                            .foregroundStyle(Color.warmInkMuted)
                            .monospacedDigit()
                    }
                    .padding(.top, 4)
                }
            }
            Spacer()
            if badge.unlocked {
                Image(systemName: "checkmark")
                    .warmFont(16, weight: .medium)
                    .foregroundStyle(Color.warmGreen)
            }
        }
        .padding(14)
        .background(Color.warmSurface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.warmLine, lineWidth: 1))
        .opacity(badge.unlocked ? 1 : 0.88)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(badge.title), \(badge.subtitle)"))
        .accessibilityValue(badge.unlocked ? Text("Unlocked") : Text("\(Int(badge.progress * 100)) percent"))
    }
}

#Preview { AchievementsView() }
