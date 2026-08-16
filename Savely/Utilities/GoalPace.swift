//
//  GoalPace.swift
//  Savely
//
//  The pace policy, in one place: how fast a goal *needs* to grow to land
//  on its date, how fast it *is* growing from its deposits, whether that is
//  on track, and an ETA that is never faked. GoalDetailView, the Dashboard
//  hero card, the Goals list and AutoMoveSuggestion all read from here.
//

import Foundation

struct GoalPace: Equatable {
    enum Status: Equatable {
        case complete
        case onTrack
        case behind
    }

    /// Dollars per week needed to reach the target by the deadline.
    /// nil when there is no deadline (or it has passed) or the goal is done.
    let requiredWeekly: Double?
    /// Dollars per week the goal is actually receiving (see `compute`).
    let actualWeekly: Double
    /// Weeks from `now` until the goal is funded at the actual pace.
    /// nil when the pace is zero (no honest date exists) or the goal is done.
    let etaWeeks: Double?
    let status: Status

    /// Deposits over this window feed `actualWeekly`.
    static let actualWindowWeeks: Double = 4
    /// Weeks per month, for turning a monthly auto-move into a weekly pace.
    static let weeksPerMonth: Double = 4.33
    /// ETAs past this are shown as "1+ year" rather than a fake date.
    static let etaCapWeeks: Double = 52

    // MARK: - Building blocks (also used by AutoMoveSuggestion)

    /// Whole weeks from `now` to `deadline`, never below 1 so a deadline
    /// this week still yields a finite pace.
    static func weeksUntil(_ deadline: Date, from now: Date, calendar: Calendar = .current) -> Int {
        max(1, calendar.dateComponents([.weekOfYear], from: now, to: deadline).weekOfYear ?? 1)
    }

    /// `remaining ÷ weeks to deadline`, or nil when there is no future deadline.
    static func requiredWeeklyPace(remaining: Double, deadline: Date?, now: Date, calendar: Calendar = .current) -> Double? {
        guard let deadline, deadline > now, remaining > 0 else { return nil }
        return remaining / Double(weeksUntil(deadline, from: now, calendar: calendar))
    }

    // MARK: - Policy

    /// - `actualWeekly`: average of the goal's deposits over the last four
    ///   weeks. A goal with no deposits *ever* falls back to its configured
    ///   auto-move amount as a weekly figure (`autoMoveAmount ÷ 4.33`) — the
    ///   pace the user promised, until real deposits replace it.
    /// - On track ⇔ complete, or no deadline, or `actualWeekly ≥ requiredWeekly`.
    static func compute(
        goal: GoalModel,
        deposits: [DepositModel],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> GoalPace {
        let remaining = max(0, goal.target - goal.current)
        if remaining <= 0 {
            return GoalPace(requiredWeekly: nil, actualWeekly: 0, etaWeeks: nil, status: .complete)
        }

        let required = requiredWeeklyPace(remaining: remaining, deadline: goal.deadline, now: now, calendar: calendar)

        let goalDeposits = deposits.filter { $0.goalID == goal.id }
        let actual: Double
        if goalDeposits.isEmpty {
            actual = goal.autoMoveEnabled ? goal.autoMoveAmount / weeksPerMonth : 0
        } else {
            let windowStart = calendar.date(byAdding: .day, value: -Int(actualWindowWeeks * 7), to: now) ?? now
            let recent = goalDeposits.filter { $0.date > windowStart && $0.date <= now }
            actual = recent.reduce(0) { $0 + $1.amount } / actualWindowWeeks
        }

        let eta: Double? = actual > 0 ? remaining / actual : nil
        let status: Status
        if let required, actual < required {
            status = .behind
        } else {
            status = .onTrack
        }
        return GoalPace(requiredWeekly: required, actualWeekly: actual, etaWeeks: eta, status: status)
    }

    // MARK: - Display

    var label: String {
        switch status {
        case .complete: return "Complete!"
        case .onTrack: return "On track"
        case .behind: return "Behind"
        }
    }

    /// "Jun 12", "1+ year", or "—". Never a made-up date.
    func etaText(from now: Date = Date(), calendar: Calendar = .current) -> String {
        guard status != .complete else { return "Done!" }
        guard let etaWeeks else { return "—" }
        if etaWeeks > Self.etaCapWeeks { return "1+ year" }
        let date = calendar.date(byAdding: .day, value: Int((etaWeeks * 7).rounded()), to: now) ?? now
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

/// Remembers which completed goals were already celebrated (UserDefaults),
/// so the completion pop runs exactly once per goal. Mirrors AchievementStore.
enum GoalCelebrationStore {
    private static let key = "celebratedGoalIds"

    static func newlyCompleted(_ completed: [GoalModel]) -> Set<UUID> {
        let celebrated = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
        return Set(completed.map(\.id).filter { !celebrated.contains($0.uuidString) })
    }

    static func markCelebrated(_ completed: [GoalModel]) {
        let celebrated = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
        let ids = Set(completed.map(\.id.uuidString))
        UserDefaults.standard.set(Array(celebrated.union(ids)).sorted(), forKey: key)
    }
}
