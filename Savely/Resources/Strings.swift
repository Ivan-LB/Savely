//
//  Strings.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/10/24.
//

import Foundation

struct Strings {
    struct Onboarding {
        static let setGoalsTitle = NSLocalizedString(
            "set_goals_title",
            value: "Set Goals",
            comment: "Set Goals Title")
        static let setGoalsLabel = NSLocalizedString(
            "set_goals_label",
            value: "Define your financial objectives and work towards achieving them.",
            comment: "Set Goals Label")
        static let trackExpensesTitle = NSLocalizedString(
            "track_expenses_title",
            value: "Track Your Expenses",
            comment: "Track Expenses Title")
        static let trackExpensesLabel = NSLocalizedString(
            "track_expenses_label",
            value: "Record and categorize your expenses to understand your spending habits.",
            comment: "Track Expenses Label")
        static let trackIncomesTitle = NSLocalizedString(
            "track_incomes_title",
            value: "Track Your Income",
            comment: "Track Incomes Title")
        static let trackIncomesLabel = NSLocalizedString(
            "track_incomes_label",
            value: "Record your income to better plan your budget and reach your savings goals.",
            comment: "Track Incomes Label")
        static let receiveTipsTitle = NSLocalizedString(
            "receive_tips_title",
            value: "Receive Tips",
            comment: "Receive Tips Title")
        static let receiveTipsLabel = NSLocalizedString(
            "receive_tips_label",
            value: "Get personalized tips to improve your financial health.",
            comment: "Receive Tips Label")
        static let notificationSettingsTitle = NSLocalizedString(
            "notification_settings_title",
            value: "Notification Settings",
            comment: "Notification Settings Title")
        static let notificationSettingsDescription = NSLocalizedString(
            "notification_settings_description",
            value: "Choose the times to receive alerts for expenses and goals.",
            comment: "Notification Settings Description")
        static let welcomeTitle = NSLocalizedString(
            "onboarding_welcome_title",
            value: "Yours, and only yours",
            comment: "Onboarding welcome step title (privacy)")
        static let welcomeLabel = NSLocalizedString(
            "onboarding_welcome_label",
            value: "No accounts, no cloud. Your money data lives on your iPhone and never leaves it.",
            comment: "Onboarding welcome step description (privacy)")
        static let trackMoneyTitle = NSLocalizedString(
            "track_money_title",
            value: "Track Your Money",
            comment: "Onboarding merged income/expense tracking step title")
        static let trackMoneyLabel = NSLocalizedString(
            "track_money_label",
            value: "Log income and expenses in seconds and understand where your money goes.",
            comment: "Onboarding merged income/expense tracking step description")
        static let scanReceiptsTitle = NSLocalizedString(
            "scan_receipts_title",
            value: "Scan Receipts",
            comment: "Onboarding receipt scanning step title")
        static let scanReceiptsLabel = NSLocalizedString(
            "scan_receipts_label",
            value: "Point the camera at a receipt and Savely reads the total for you.",
            comment: "Onboarding receipt scanning step description")
    }

    struct Notifications {
        static let expenseReminderTitle = NSLocalizedString(
            "expense_reminder_title",
            value: "Expense Reminder",
            comment: "Expense Reminder Title")
        static let expenseReminderBody = NSLocalizedString(
            "expense_reminder_body",
            value: "Don't forget to log your expenses today!",
            comment: "Expense Reminder Body")
        static let goalAlertTitle = NSLocalizedString(
            "goal_alert_title",
            value: "Goal Reminder",
            comment: "Goal Alert Title")
        static let goalAlertBody = NSLocalizedString(
            "goal_alert_body",
            value: "Check your goals and track your progress!",
            comment: "Goal Alert Body")
    }
    
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
        static let noGoalsRecentlyLabel = NSLocalizedString(
            "no_goal_recently",
            value: "No goals recently",
            comment: "No Goal Recently Label")
        static let weeklyExpensesTitle = NSLocalizedString(
            "weekly_expenses_title",
            value: "Weekly Expenses",
            comment: "Weekly Expenses Title")
        static let tipOfTheDayTitle = NSLocalizedString(
            "tip_of_the_day_title",
            value: "Tip of the Day",
            comment: "Tip of the Day Title")
        static let loadingTipLabel = NSLocalizedString(
            "loading_tip_label", 
            value: "Loading tip...",
            comment: "Loading Tip Label")
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
        static let addIncomeLabel = NSLocalizedString(
            "add_income_label",
            value: "Add Income",
            comment: "Add Income Label")
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
        static let startDateLabel = NSLocalizedString(
            "start_date_label",
            value: "Start Date",
            comment: "Start Date Label")
        static let endDateLabel = NSLocalizedString(
            "end_date_label",
            value: "End Date",
            comment: "End Date Label")
        static let incomeDistributionLabel = NSLocalizedString(
            "income_distribution_label",
            value: "Income Distribution",
            comment: "Income Distribution Label")
        static let noDataLabel = NSLocalizedString(
            "no_data_label",
            value: "No data available for the selected dates.",
            comment: "No Data Label")
    }
    
    
    struct Profile {
        static let expenseReminderPickerTitle = NSLocalizedString(
            "expense_reminder_picker_title",
            value: "Select Expense Reminder Time",
            comment: "Select Expense Reminder Time Title")
        static let goalAlertPickerTitle = NSLocalizedString(
            "goal_alert_picker_title",
            value: "Select Goal Alert Time",
            comment: "Select Goal Alert Time Title")
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
        
        static let weeklyReportTitle = NSLocalizedString(
            "weekly_report_title",
            value: "Weekly Report",
            comment: "Weekly Report Title")
        
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

        // Reminders (settings + onboarding)
        static let reminderTimeLabel = NSLocalizedString(
            "reminder_time_label",
            value: "Time",
            comment: "Label next to the reminder time picker")
        static let notificationsDeniedHint = NSLocalizedString(
            "notifications_denied_hint",
            value: "Notifications are off for Savely in iOS Settings.",
            comment: "Shown instead of the reminder switches when permission is denied")
        static let openSettingsButton = NSLocalizedString(
            "open_settings_button",
            value: "Open Settings",
            comment: "Button that opens the iOS Settings app")

        // Identity + stats
        static let savingSinceLabel = NSLocalizedString(
            "saving_since_label",
            value: "Saving since %@",
            comment: "Subtitle under the display name; %@ is a month and year")
        static let justStartedLabel = NSLocalizedString(
            "just_started_label",
            value: "Just getting started",
            comment: "Subtitle under the display name when nothing is logged yet")
        static let statSavedLabel = NSLocalizedString(
            "stat_saved_label",
            value: "Saved",
            comment: "Stat cell: total saved across goals")
        static let statMovementsLabel = NSLocalizedString(
            "stat_movements_label",
            value: "Movements",
            comment: "Stat cell: number of incomes + expenses logged")
        static let statActiveGoalsLabel = NSLocalizedString(
            "stat_active_goals_label",
            value: "Active goals",
            comment: "Stat cell: goals not yet complete")

        // Achievements
        static let nextAchievementLabel = NSLocalizedString(
            "next_achievement_label",
            value: "Next up",
            comment: "Kicker above the closest locked achievement")
        static let allAchievementsUnlockedLabel = NSLocalizedString(
            "all_achievements_unlocked_label",
            value: "Every achievement unlocked",
            comment: "Shown when nothing is left to unlock")

        // Data & privacy
        static let dataPrivacyTitle = NSLocalizedString(
            "data_privacy_title",
            value: "Data & privacy",
            comment: "Section header")
        static let dataStaysLocalLabel = NSLocalizedString(
            "data_stays_local_label",
            value: "Your data never leaves this iPhone.",
            comment: "One-line intro of the Data & privacy section")
        static let deleteAllDataLabel = NSLocalizedString(
            "delete_all_data_label",
            value: "Delete all data",
            comment: "Destructive row")
        static let deleteAllDataConfirmTitle = NSLocalizedString(
            "delete_all_data_confirm_title",
            value: "Delete all data?",
            comment: "Confirmation dialog title")
        static let deleteAllDataConfirmMessage = NSLocalizedString(
            "delete_all_data_confirm_message",
            value: "Every income, expense and goal will be removed from this iPhone. Your name and reminder settings stay. This cannot be undone.",
            comment: "Confirmation dialog message")
        static let deleteAllDataConfirmButton = NSLocalizedString(
            "delete_all_data_confirm_button",
            value: "Delete everything",
            comment: "Destructive confirm button")
        static let deleteDataFailedMessage = NSLocalizedString(
            "delete_data_failed_message",
            value: "Couldn't delete your data. Please try again.",
            comment: "Alert when deletion fails")

        static let securityTitle = NSLocalizedString(
            "security_title",
            value: "Security",
            comment: "Security Title")
        
        static let previousTipsTitle = NSLocalizedString(
            "previous_tips_title",
            value: "Previous Tips",
            comment: "Previous Tips")
        
        static let seePreviousTipsLabel = NSLocalizedString(
            "see_previous_tips_label",
            value: "See previous tips",
            comment: "See Previous Tips Label")
        
        static let tipsHistoryTitle = NSLocalizedString(
            "tips_history_title",
            value: "Tips History",
            comment: "Tips History Title")
    }
    
    struct Errors{
        static let noticeLabel = NSLocalizedString(
            "notice_label",
            value: "Notice",
            comment: "Notice Label")
        static let errorLabel = NSLocalizedString(
            "error_label",
            value: "Error",
            comment: "Error Label")
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
        static let selectTimePLaceholder = NSLocalizedString(
            "select_time_placeholder",
            value: "Select Time",
            comment: "Select Time Placeholder")
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
    
    struct NetworkError {
        static let limitedConnectionHeader = NSLocalizedString(
            "limited_connection_header",
            value: "Limited Connectivity",
            comment: "Limited Connection Header")
        static let deviceNotConnectedToInternetBody = NSLocalizedString(
            "device_not_connected_to_internet_body",
            value: "Your device is offline. Features like Tips may not work, but the app is fully functional offline.",
            comment: "Device not connected to internet Body")
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
        static let downloadWeeklyReportButton = NSLocalizedString(
            "download_weekly_report_button",
            value: "Download Weekly Report",
            comment: "Download Weekly Report Button")
        
        static let updateInformationButton = NSLocalizedString(
            "update_information_button",
            value: "Update Information",
            comment: "Update Information Button")
        
        static let scanReceiptButton = NSLocalizedString(
            "scan_receipt_button",
            value: "Scan Receipt",
            comment: "Scan Receipt Button")
        
        static let nextButton = NSLocalizedString(
            "next_button",
            value: "Next",
            comment: "Next Button")
        static let startButton = NSLocalizedString(
            "start_button",
            value: "Start",
            comment: "Start Button")
        static let createAccountButton = NSLocalizedString(
            "create_account_button",
            value: "Create Account",
            comment: "Create Account Button")
        
        static let yesButton = NSLocalizedString(
            "yes_button",
            value: "Yes",
            comment: "Yes Button")
        static let noButton = NSLocalizedString(
            "no_button",
            value: "No",
            comment: "No Button")
        
        static let saveButton = NSLocalizedString(
            "save_button",
            value: "Save",
            comment: "Save Button")
        
        static let continueButton = NSLocalizedString(
            "continue_button",
            value: "Continue",
            comment: "Continue Button")
        
        static let fetchReportButton = NSLocalizedString(
            "fetch_report_button",
            value: "Fetch Report",
            comment: "Fetch Report Button")
        
        static let okButton = NSLocalizedString(
            "ok_button",
            value: "OK",
            comment: "OK Button")
        static let cancelButton = NSLocalizedString(
            "cancel_button",
            value: "Cancel",
            comment: "Cancel Button")
    }
    
    struct Camera {
        static let takeAnotherPhotoLabel = NSLocalizedString(
            "take_another_photo_label",
            value: "Take another photo",
            comment: "Take Another Photo Label")
        static let confirmationValueLabel = NSLocalizedString(
            "is_it_rigth_label",
            value: "Is it right?",
            comment: "Is It Ritght Label")
        static let pleaseConfirmValueTitle = NSLocalizedString(
            "please_confirm_value_title",
            value: "Please Confirm Value",
            comment: "Please Confirm Value Title")
    }
    
    struct SplashScreen {
        static let savelyAppTitle = NSLocalizedString(
            "savely_app_title",
            value: "Savely",
            comment: "Savely App Title")
    }
    
    struct GoalsView {
        static let greenColor = NSLocalizedString(
            "green_color",
            value: "Green",
            comment: "Green Color")
        static let blueColor = NSLocalizedString(
            "blue_color",
            value: "Blue",
            comment: "Blue Color")
        static let yellowColor = NSLocalizedString(
            "yellow_Color",
            value: "Yellow",
            comment: "Yellow Color")
        static let redColor = NSLocalizedString(
            "red_color",
            value: "Red",
            comment: "Red Color")
        static let colorLabel = NSLocalizedString(
            "color_label",
            value: "Color",
            comment: "Color Label")
    }
}
