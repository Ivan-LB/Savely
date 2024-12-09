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
    @Published var displayName: String = ""
    @Published var email: String = ""
    @AppStorage("darkModeEnabled") var darkMode: Bool = false
    @Published var expenseReminders: Bool = true {
        didSet {
            handleExpenseReminderToggle()
        }
    }
    @Published var goalAlerts: Bool = true {
        didSet {
            handleGoalAlertToggle()
        }
    }

    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var showExpenseReminderPicker: Bool = false
    @Published var showGoalAlertPicker: Bool = false
    @Published var selectedExpenseReminderTime: Date = Date()
    @Published var selectedGoalAlertTime: Date = Date()
    @Published var weeklyIncomes: [IncomeModel] = []
    @Published var weeklyExpenses: [ExpenseModel] = []
    @Published var isLoading: Bool = false

    private var modelContext: ModelContext?

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        print("ProfileViewModel initialized.")
        Task {
            await fetchUserData()
        }
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

    func fetchUserData() async {
        guard let uid = AuthenticationManager.shared.currentUser?.uid else {
            alertMessage = "User not authenticated."
            showAlert = true
            return
        }

        do {
            let user = try await UserManager.shared.getUser(userId: uid)
            DispatchQueue.main.async {
                self.displayName = user.displayName ?? "Unknown"
                self.email = user.email ?? "Unknown"
            }
        } catch {
            DispatchQueue.main.async {
                self.alertMessage = "Failed to fetch user data: \(error.localizedDescription)"
                self.showAlert = true
            }
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
        let adjustedEndDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: endDate)!)

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
        let adjustedEndDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: endDate)!)

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


    func updatePersonalInformation() async {
        guard let uid = AuthenticationManager.shared.currentUser?.uid else {
            alertMessage = "User not authenticated."
            showAlert = true
            return
        }
        do {
            try await UserManager.shared.updateUser(userId: uid, displayName: displayName, email: email)
            try await AuthenticationManager.shared.updateEmail(email: email)
            alertMessage = "Your personal information has been updated successfully."
            showAlert = true
        } catch {
            alertMessage = "Failed to update your information: \(error.localizedDescription)"
            showAlert = true
        }
    }

    func handleExpenseReminderToggle() {
        if expenseReminders {
            showExpenseReminderPicker = true
        } else {
            NotificationManager.shared.cancelNotification(with: "expenseReminder")
        }
    }

    func handleGoalAlertToggle() {
        if goalAlerts {
            showGoalAlertPicker = true
        } else {
            NotificationManager.shared.cancelNotification(with: "goalAlert")
        }
    }

    func saveExpenseReminderTime() {
        _ = NotificationManager.shared.scheduleNotification(
            title: Strings.Notifications.expenseReminderTitle,
            body: Strings.Notifications.expenseReminderBody,
            identifier: "expenseReminder",
            date: selectedExpenseReminderTime
        )
    }

    func saveGoalAlertTime() {
        _ = NotificationManager.shared.scheduleNotification(
            title: Strings.Notifications.goalAlertTitle,
            body: Strings.Notifications.goalAlertBody,
            identifier: "goalAlert",
            date: selectedGoalAlertTime
        )
    }

    func signOut() {
        do {
            try AuthenticationManager.shared.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}
