//
//  NotificationManager.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 08/12/24.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    func scheduleNotification(title: String, body: String, identifier: String, date: Date) -> String? {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }

        return identifier
    }

    func cancelNotification(with identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Notification with identifier \(identifier) cancelled.")
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notifications permission: \(error)")
            }
        }
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Reminders (expense / goal)

    /// Applies the planner's decision for one reminder. Scheduling under an
    /// existing identifier replaces the pending request, so a time change
    /// is just another `.schedule`.
    func apply(_ action: ReminderAction, to kind: ReminderKind) {
        switch action {
        case .schedule(let time):
            _ = scheduleNotification(
                title: kind.notificationTitle,
                body: kind.notificationBody,
                identifier: kind.rawValue,
                date: time
            )
        case .cancel:
            cancelNotification(with: kind.rawValue)
        }
    }

    func apply(_ prefs: ReminderPreferences) {
        for (kind, action) in ReminderPlanner.actions(for: prefs) {
            apply(action, to: kind)
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// The hour/minute a reminder is currently pending at, if any. Used
    /// once to seed the persisted preferences for installs that onboarded
    /// before preferences were stored (they only had the pending request).
    func pendingReminderTime(for kind: ReminderKind, calendar: Calendar = .current) async -> Date? {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        guard let request = requests.first(where: { $0.identifier == kind.rawValue }),
              let trigger = request.trigger as? UNCalendarNotificationTrigger else { return nil }
        return calendar.date(from: trigger.dateComponents)
    }
}

private extension ReminderKind {
    var notificationTitle: String {
        switch self {
        case .expense: return Strings.Notifications.expenseReminderTitle
        case .goal: return Strings.Notifications.goalAlertTitle
        }
    }

    var notificationBody: String {
        switch self {
        case .expense: return Strings.Notifications.expenseReminderBody
        case .goal: return Strings.Notifications.goalAlertBody
        }
    }
}
