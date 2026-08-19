//
//  ReminderSettings.swift
//  Savely
//
//  The two local reminders (expense, goal): what the user chose, where it
//  is stored, and the pure decision of what to do about it. Scheduling
//  itself lives in NotificationManager; this file never touches
//  UNUserNotificationCenter so it can be unit-tested.
//

import Foundation

/// The two repeating reminders Savely can schedule. The raw value is the
/// `UNNotificationRequest` identifier that has been in use since the first
/// release — do not rename it or existing users' pending requests become
/// unreachable.
enum ReminderKind: String, CaseIterable {
    case expense = "expenseReminder"
    case goal = "goalAlert"
}

/// What the user chose, per reminder. Times are only meaningful as
/// hour + minute (the trigger repeats daily).
struct ReminderPreferences: Equatable {
    var expenseEnabled: Bool
    var goalEnabled: Bool
    var expenseTime: Date
    var goalTime: Date

    func isEnabled(_ kind: ReminderKind) -> Bool {
        switch kind {
        case .expense: return expenseEnabled
        case .goal: return goalEnabled
        }
    }

    func time(for kind: ReminderKind) -> Date {
        switch kind {
        case .expense: return expenseTime
        case .goal: return goalTime
        }
    }

    mutating func setEnabled(_ enabled: Bool, for kind: ReminderKind) {
        switch kind {
        case .expense: expenseEnabled = enabled
        case .goal: goalEnabled = enabled
        }
    }

    mutating func setTime(_ time: Date, for kind: ReminderKind) {
        switch kind {
        case .expense: expenseTime = time
        case .goal: goalTime = time
        }
    }

    /// First-run defaults: both on, evening for expenses, morning for goals.
    static func defaults(calendar: Calendar = .current, now: Date = Date()) -> ReminderPreferences {
        ReminderPreferences(
            expenseEnabled: true,
            goalEnabled: true,
            expenseTime: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now) ?? now,
            goalTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
        )
    }
}

/// The one decision the settings screen and onboarding both make.
enum ReminderAction: Equatable {
    case schedule(at: Date)
    case cancel
}

enum ReminderPlanner {
    /// A reminder that is on is scheduled at its time; one that is off is
    /// cancelled. Re-scheduling under the same identifier replaces the
    /// pending request, so "time changed" is just `schedule` again.
    static func action(enabled: Bool, time: Date) -> ReminderAction {
        enabled ? .schedule(at: time) : .cancel
    }

    static func actions(for prefs: ReminderPreferences) -> [ReminderKind: ReminderAction] {
        var result: [ReminderKind: ReminderAction] = [:]
        for kind in ReminderKind.allCases {
            result[kind] = action(enabled: prefs.isEnabled(kind), time: prefs.time(for: kind))
        }
        return result
    }
}

/// UserDefaults-backed persistence. Kept tiny and explicit (no
/// `@AppStorage`) so an `ObservableObject` can publish changes itself.
struct ReminderStore {
    private let defaults: UserDefaults

    private enum Key {
        static let expenseEnabled = "reminder.expense.enabled"
        static let goalEnabled = "reminder.goal.enabled"
        static let expenseTime = "reminder.expense.time"
        static let goalTime = "reminder.goal.time"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// True once onboarding (or the settings screen) has saved a choice.
    /// Before that, callers may seed times from the pending requests of an
    /// already-onboarded install (see `ProfileViewModel`).
    var hasSavedPreferences: Bool {
        defaults.object(forKey: Key.expenseEnabled) != nil
    }

    func load() -> ReminderPreferences {
        let base = ReminderPreferences.defaults()
        return ReminderPreferences(
            expenseEnabled: defaults.object(forKey: Key.expenseEnabled) as? Bool ?? base.expenseEnabled,
            goalEnabled: defaults.object(forKey: Key.goalEnabled) as? Bool ?? base.goalEnabled,
            expenseTime: defaults.object(forKey: Key.expenseTime) as? Date ?? base.expenseTime,
            goalTime: defaults.object(forKey: Key.goalTime) as? Date ?? base.goalTime
        )
    }

    func save(_ prefs: ReminderPreferences) {
        defaults.set(prefs.expenseEnabled, forKey: Key.expenseEnabled)
        defaults.set(prefs.goalEnabled, forKey: Key.goalEnabled)
        defaults.set(prefs.expenseTime, forKey: Key.expenseTime)
        defaults.set(prefs.goalTime, forKey: Key.goalTime)
    }
}
