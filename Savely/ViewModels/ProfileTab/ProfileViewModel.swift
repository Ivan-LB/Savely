//
//  ProfileViewModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 18/11/24.
//

import Foundation
import SwiftUI
import Combine
import PDFKit
import UserNotifications
import SwiftData

@MainActor
class ProfileViewModel: ObservableObject {
    @AppStorage("darkModeEnabled") var darkMode: Bool = false

    /// The persisted reminder choices. Mutate through the `setReminder…`
    /// methods so the change is saved and the pending request follows.
    @Published private(set) var reminders: ReminderPreferences
    /// True when iOS notification permission is denied — the settings rows
    /// then explain instead of pretending a switch does something.
    @Published private(set) var notificationsDenied: Bool = false

    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var weeklyIncomes: [IncomeModel] = []
    @Published var weeklyExpenses: [ExpenseModel] = []
    @Published var isLoading: Bool = false

    private var modelContext: ModelContext?
    private let reminderStore: ReminderStore
    private let notifications: NotificationManager

    init(modelContext: ModelContext? = nil,
         reminderStore: ReminderStore = ReminderStore(),
         notifications: NotificationManager = .shared) {
        self.modelContext = modelContext
        self.reminderStore = reminderStore
        self.notifications = notifications
        self.reminders = reminderStore.load()
        if modelContext != nil {
            fetchWeeklyReportData(
                startDate: Calendar.current.startOfWeek(for: Date()),
                endDate: Date()
            )
        }
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        print("setModelContext: ModelContext set in ProfileViewModel: \(context)")
        fetchWeeklyReportData(
            startDate: Calendar.current.startOfWeek(for: Date()),
            endDate: Date()
        )
    }

    // MARK: - Reminders

    /// Call on appear: refreshes the permission state and, for installs
    /// that onboarded before preferences were persisted, seeds the times
    /// from whatever request is still pending.
    func refreshReminderState() async {
        notificationsDenied = await notifications.authorizationStatus() == .denied
        guard !reminderStore.hasSavedPreferences else { return }
        var seeded = reminders
        for kind in ReminderKind.allCases {
            if let pending = await notifications.pendingReminderTime(for: kind) {
                seeded.setTime(pending, for: kind)
                seeded.setEnabled(true, for: kind)
            } else {
                // No pending request for a pre-preferences install means the
                // user turned it off (the old toggle only ever cancelled).
                seeded.setEnabled(false, for: kind)
            }
        }
        reminders = seeded
        reminderStore.save(seeded)
    }

    func setReminder(_ kind: ReminderKind, enabled: Bool) {
        var next = reminders
        next.setEnabled(enabled, for: kind)
        commit(next, kind: kind)
    }

    func setReminder(_ kind: ReminderKind, time: Date) {
        var next = reminders
        next.setTime(time, for: kind)
        commit(next, kind: kind)
    }

    private func commit(_ next: ReminderPreferences, kind: ReminderKind) {
        guard next != reminders else { return }
        reminders = next
        reminderStore.save(next)
        notifications.apply(
            ReminderPlanner.action(enabled: next.isEnabled(kind), time: next.time(for: kind)),
            to: kind
        )
    }

    // MARK: - Data

    /// Deletes every movement, goal and stored tip. Display name and
    /// reminder settings are kept — they are preferences, not data.
    func deleteAllData() {
        guard let modelContext = modelContext else { return }
        do {
            try modelContext.delete(model: IncomeModel.self)
            try modelContext.delete(model: ExpenseModel.self)
            try modelContext.delete(model: GoalModel.self)
            try modelContext.delete(model: TipModel.self)
            try modelContext.save()
            UserDefaults.standard.removeObject(forKey: "celebratedAchievementIds")
            weeklyIncomes = []
            weeklyExpenses = []
        } catch {
            print("deleteAllData: \(error)")
            alertMessage = Strings.Profile.deleteDataFailedMessage
            showAlert = true
        }
    }

    func fetchWeeklyReportData(startDate: Date, endDate: Date) {
        guard let modelContext = modelContext else {
            print("fetchWeeklyReportData: ModelContext is nil. Cannot fetch report data.")
            return
        }

        isLoading = true
        print("fetchWeeklyReportData: Fetching data... Start Date: \(startDate), End Date: \(endDate)")

        Task {
            do {
                let incomes = try await fetchWeeklyIncome(from: startDate, to: endDate, in: modelContext)
                print("fetchWeeklyReportData: Fetched incomes count: \(incomes.count)")

                let expenses = try await fetchWeeklyExpenses(from: startDate, to: endDate, in: modelContext)
                print("fetchWeeklyReportData: Fetched expenses count: \(expenses.count)")

                DispatchQueue.main.async {
                    self.weeklyIncomes = incomes
                    self.weeklyExpenses = expenses
                    self.isLoading = false
                    print("fetchWeeklyReportData: Data set successfully. Incomes: \(self.weeklyIncomes.count), Expenses: \(self.weeklyExpenses.count)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                print("fetchWeeklyReportData: Error fetching report data: \(error)")
            }
        }
    }

    private func fetchWeeklyIncome(from startDate: Date, to endDate: Date, in context: ModelContext) async throws -> [IncomeModel] {
        print("fetchWeeklyIncome: Fetching incomes...")
        let adjustedStartDate = Calendar.current.startOfDay(for: startDate)
        guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: endDate) else { return [] }
        let adjustedEndDate = Calendar.current.startOfDay(for: nextDay)

        let fetchDescriptor = FetchDescriptor<IncomeModel>(
            predicate: #Predicate {
                $0.date >= adjustedStartDate && $0.date < adjustedEndDate
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let incomes = try context.fetch(fetchDescriptor)
        print("fetchWeeklyIncome: Adjusted Start Date: \(adjustedStartDate), Adjusted End Date: \(adjustedEndDate)")
        print("fetchWeeklyIncome: Incomes fetched: \(incomes.count)")
        return incomes
    }

    private func fetchWeeklyExpenses(from startDate: Date, to endDate: Date, in context: ModelContext) async throws -> [ExpenseModel] {
        print("fetchWeeklyExpenses: Fetching expenses...")
        let adjustedStartDate = Calendar.current.startOfDay(for: startDate)
        guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: endDate) else { return [] }
        let adjustedEndDate = Calendar.current.startOfDay(for: nextDay)

        let fetchDescriptor = FetchDescriptor<ExpenseModel>(
            predicate: #Predicate {
                $0.date >= adjustedStartDate && $0.date < adjustedEndDate
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let expenses = try context.fetch(fetchDescriptor)
        print("fetchWeeklyExpenses: Adjusted Start Date: \(adjustedStartDate), Adjusted End Date: \(adjustedEndDate)")
        print("fetchWeeklyExpenses: Expenses fetched: \(expenses.count)")
        return expenses
    }

    func generateWeeklyReportPDF() {
        print("generateWeeklyReportPDF: Checking data availability.")
        guard !weeklyIncomes.isEmpty || !weeklyExpenses.isEmpty else {
            alertMessage = "No data available to generate the report."
            showAlert = true
            print("generateWeeklyReportPDF: No data available to generate the report.")
            return
        }

        guard let pdfData = ReportsPDFGenerator.generateWeeklyReport(incomes: weeklyIncomes, expenses: weeklyExpenses) else {
            print("generateWeeklyReportPDF: Failed to generate PDF")
            alertMessage = "Failed to generate the PDF report."
            showAlert = true
            return
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("WeeklyReport.pdf")
        do {
            try pdfData.write(to: tempURL)
            print("generateWeeklyReportPDF: PDF saved to \(tempURL)")

            // Ensure file exists
            guard FileManager.default.fileExists(atPath: tempURL.path) else {
                print("generateWeeklyReportPDF: File does not exist at \(tempURL)")
                alertMessage = "Failed to locate the PDF file."
                showAlert = true
                return
            }

            // Share or save the PDF
            DispatchQueue.main.async {
                let activityViewController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    rootViewController.present(activityViewController, animated: true, completion: nil)
                } else {
                    print("generateWeeklyReportPDF: Unable to find rootViewController")
                    self.alertMessage = "Unable to open sharing options."
                    self.showAlert = true
                }
            }
        } catch {
            print("generateWeeklyReportPDF: Error saving PDF: \(error)")
            alertMessage = "Error saving the PDF file."
            showAlert = true
        }
    }

}
