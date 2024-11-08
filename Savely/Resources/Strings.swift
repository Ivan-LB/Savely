//
//  Strings.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/10/24.
//

import Foundation

struct Strings {
    struct DashboardTab {
        static let welcomeHeader = NSLocalizedString(
            "welcome_header",
            value: "Welcome to Savely",
            comment: "Welcome to Savely Header")
        static let monthlyGoalLabel = NSLocalizedString(
            "monthly_goal_label",
            value: "Monthly Goal",
            comment: "Monthly Goal Label")
        static let savingsSummaryTitle = NSLocalizedString(
            "savings_summary_title",
            value: "Savings Summary",
            comment: "Savings Summary Title")
        static let weeklyExpensesTitle = NSLocalizedString(
            "weekly_expenses_title",
            value: "Weekly Expenses",
            comment: "Weekly Expenses Title")
        static let tipOfTheDayTitle = NSLocalizedString(
            "tip_of_the_day_title",
            value: "Tip of the Day",
            comment: "Tip of the Day Title")
        static let tipsAndSuggestionsTitle = NSLocalizedString(
            "tips_and_suggestion_title",
            value: "Tips and Suggestions",
            comment: "Tips and Suggestions Tittle")
    }
    
    struct ExpenseTrackerTab {
        static let descriptionPlaceholderLabel = NSLocalizedString(
            "description_placeholder_label",
            value: "Description",
            comment: "Description Placeholder Label")
        static let amountPlaceholderLabel = NSLocalizedString(
            "amount_placeholder_label",
            value: "Amount",
            comment: "Amount Placeholder Label")
        
        static let recentExpensesTitle = NSLocalizedString(
            "recent_expenses_title",
            value: "Recent Expenses",
            comment: "Recent Expenses Title")
    }
    
    struct IncomesTrackerView {
        static let recentIncomesTitle = NSLocalizedString(
            "recent_incomes_title",
            value: "Recent Incomes",
            comment: "Recent Incomes Title")
    }
    
    struct ReportsView {
        static let pickTimePeriodLabel = NSLocalizedString(
            "pick_time_period",
            value: "Pick Time Period",
            comment: "Pick Time Period Label")
        static let thisMonthLabel = NSLocalizedString(
            "this_month_label",
            value: "This Month",
            comment: "This Month Label")
        static let thisTrimesterLabel = NSLocalizedString(
            "this_trimester_period",
            value: "This Trimester",
            comment: "This Trimester Label")
        static let thisYearLabel = NSLocalizedString(
            "this_year_period",
            value: "This Year",
            comment: "This Year Label")
        static let pickDateLabel = NSLocalizedString(
            "pick_date_label",
            value: "Pick Date",
            comment: "Pick Date Label")
        static let expenseDistributionLabel = NSLocalizedString(
            "expense_distribution_label",
            value: "Expense Distribution",
            comment: "Expense Distribution Label")
        static let savingsTrendLabel = NSLocalizedString(
            "savings_trend_label",
            value: "Savings Trend",
            comment: "Savings Trend Label")
    }
    
    
    struct Profile {
        static let personalInformationTitle = NSLocalizedString(
            "personal_information_title",
            value: "Personal Information",
            comment: "Personal Information Title")
        static let namePlaceholderLabel = NSLocalizedString(
            "name_placeholder_label",
            value: "Name",
            comment: "Name Placeholder Label")
        static let emailPlaceholderLabel = NSLocalizedString(
            "email_placeholder_title",
            value: "Email",
            comment: "Email Placeholder Label")
        
        static let notificationTitle = NSLocalizedString(
            "notifications_title",
            value: "Notifications",
            comment: "Notifications Title")
        static let expenseRemindersLabel = NSLocalizedString(
            "expense_reminders_label",
            value: "Expense Reminders",
            comment: "Expense Reminders Label")
        static let goalAlertsLabel = NSLocalizedString(
            "goal_alerts_label", 
            value: "Goal Alerts",
            comment: "Goal Alerts Label")
        
        static let appPreferencesTitle = NSLocalizedString(
            "app_preferences_title",
            value: "App Preferences",
            comment: "App Preferences Title")
        
        static let darkModeLabel = NSLocalizedString(
            "dark_mode_label",
            value: "Dark Mode",
            comment: "Dark Mode Label")
        
        static let securityTitle = NSLocalizedString(
            "security_title",
            value: "Security",
            comment: "Security Title")
        
        static let achievementsTitle = NSLocalizedString(
            "achievements_title",
            value: "Achievements and Medals",
            comment: "Achievements Title")
        
        static let viewAchievements = NSLocalizedString(
            "view_achievements",
            value: "View Achievements",
            comment: "View Achievements Label")
    }
    
    struct Placeholders {
        static let personalizedPlaceholder = NSLocalizedString(
            "personalized_placeholder",
            value: "Personalized",
            comment: "Personalized Placeholder")
        static let generalPlaceholder = NSLocalizedString(
            "general_placeholder",
            value: "General",
            comment: "General Placeholder")
        static let favoritesPlaceholder = NSLocalizedString(
            "favorites_placeholder",
            value: "Favorites",
            comment: "Favorites Placeholder")
        static let monthsLabel = NSLocalizedString(
            "months_placeholder",
            value: "Months",
            comment: "Months Placeholder")
        static let savingsLabel = NSLocalizedString(
            "savings_placeholder",
            value: "Savings",
            comment: "Savings Placeholcer")
        static let monthlySummaryPlaceholder = NSLocalizedString(
            "monthly_summary_placeholder",
            value: "Monthly Summary",
            comment: "Monthly Summary Placeholder")
        static let categoryPlaceholder = NSLocalizedString(
            "category_placeholder",
            value: "Category",
            comment: "Category Placeholder")
        static let savingsPlaceholder = NSLocalizedString(
            "savings_placeholder",
            value: "Savings",
            comment: "Savings Placeholder")
        static let selectTabPlaceholder = NSLocalizedString(
            "select_tab_placeholder",
            value: "Select Tab",
            comment: "Select Tab Placeholder")
    }
    
    struct Tabs {
        static let dashboardTab = NSLocalizedString(
            "dashboard_tab_string",
            value: "Dashboard",
            comment: "Dashboard Tab String")

        static let goalsTab = NSLocalizedString(
            "goals_tab_string",
            value: "Goals",
            comment: "Goals Tab String")

        static let expensesTab = NSLocalizedString(
            "expenses_tab_string",
            value: "Expenses",
            comment: "Expenses Tab String")

        static let reportsTab = NSLocalizedString(
            "reports_tab_string",
            value: "Reports",
            comment: "Reports Tab String")
        
        static let incomesTab = NSLocalizedString(
            "incomes_tab_string",
            value: "Incomes",
            comment: "Incomes Tab String")

        static let profileTab = NSLocalizedString(
            "profile_tab_string",
            value: "Profile",
            comment: "Profile Tab String")
    }
    
    struct Buttons {
        static let addIncomeButton = NSLocalizedString(
            "add_income_button",
            value: "Add Income",
            comment: "Add Income Button")
        static let addExpenseButton = NSLocalizedString(
            "add_expense_button",
            value: "Add Expense",
            comment: "Add Expense Button")
        static let filterButton = NSLocalizedString(
            "filter_button",
            value: "Filter",
            comment: "Filter Button")
        static let exportReport = NSLocalizedString(
            "export_report_button",
            value: "Export Report",
            comment: "Export Report Button")
        static let newGoalButton = NSLocalizedString(
            "add_new_goal_button",
            value: "Add New Goal",
            comment: "Add New Goal Button")
        
        static let updateInformationButton = NSLocalizedString(
            "update_information_button",
            value: "Update Information",
            comment: "Update Information Button")
        static let changePasswordButton = NSLocalizedString(
            "change_password_button",
            value: "Change Password",
            comment: "Change Password Button")
        
        static let scanReceiptButton = NSLocalizedString(
            "scan_receipt_button",
            value: "Scan Receipt",
            comment: "Scan Receipt Button")
    }
    
    struct SplashScreen {
        static let savelyAppTitle = NSLocalizedString(
            "savely_app_title",
            value: "Savely",
            comment: "Savely App Title")
    }
}
