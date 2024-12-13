//
//  Strings.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/10/24.
//

import Foundation

struct Strings {
    struct Authentication {
        static let createAccountTitle = NSLocalizedString(
            "create_account_title",
            value: "Create your account!",
            comment: "Create Account Title")
        static let signUpToGetStarted = NSLocalizedString(
            "sign_up_to_get_started",
            value: "Sign up to get started",
            comment: "Sign Up To Get Started")
        static let fullNamePlaceholder = NSLocalizedString(
            "full_name_placeholder",
            value: "Full Name",
            comment: "Full Name Placeholder")
        static let forgotPasswordLabel = NSLocalizedString(
            "forgot_password_label",
            value: "Forgot password?",
            comment: "Forgot Password Label")
        static let passwordString = NSLocalizedString(
            "password_string",
            value: "Password",
            comment: "Password String")
        static let confirmPasswordString = NSLocalizedString(
            "confirm_password_string",
            value: "Confirm Password",
            comment: "Confirm Password String")
        static let signInString = NSLocalizedString(
            "sign_in_string",
            value: "Sign In",
            comment: "Sign In String")
        static let logInString = NSLocalizedString(
            "log_in_string",
            value: "Log in to your existant account",
            comment: "Log In String")
        static let signUpLabel = NSLocalizedString(
            "sign_up_label",
            value: "Sign Up",
            comment: "Sign Up Label")
        static let welcomeBackString = NSLocalizedString(
            "welcome_back_string",
            value: "Welcome Back!", 
            comment: "Welcome Back String")
        static let enterEmailAndPasswordLabel = NSLocalizedString(
            "enter_email_and_password_label",
            value: "Enter your email and password to sign in.",
            comment: "Enter your email and password to sign in Label")
        static let otherWayToConnectLabel = NSLocalizedString(
            "other_way_to_connect_label",
            value: "Or connect using",
            comment: "Other Way to Connect")
        static let dontHaveAccount = NSLocalizedString(
            "already_have_and_account_label",
            value: "Don't have an account?",
            comment: "Already have an account Label")
        static let creatingAccountLabel = NSLocalizedString(
            "creating_account_label",
            value: "By creating an account, I accept Savely's",
            comment: "Creating Account Label")
        static let termsOfServiceLabel = NSLocalizedString(
            "terms_of_service_label",
            value: "Terms of Service",
            comment: "Terms of Service Label")
        static let passwordDontMatch = NSLocalizedString(
            "passwords_dont_match",
            value: "Passwords doesn't match",
            comment: "Passwords Doesnt Match")
    }
    
    struct Achievements {
        static let title = NSLocalizedString(
            "title",
            value: "Achievements",
            comment: "Title for achievements")
        static let firstGoalTitle = NSLocalizedString(
            "first_goal_title",
            value: "First Goal Achieved",
            comment: "Title for achieving the first goal")
        static let firstGoalDescription = NSLocalizedString(
            "first_goal_description",
            value: "You have reached your first savings goal.",
            comment: "Description for achieving the first goal")
        static let threeGoalsTitle = NSLocalizedString(
            "three_goals_title",
            value: "Three Goals Achieved",
            comment: "Title for achieving three goals")
        static let threeGoalsDescription = NSLocalizedString(
            "three_goals_description",
            value: "You have achieved three different savings goals.",
            comment: "Description for achieving three goals")
        static let consistentSavingsTitle = NSLocalizedString(
            "consistent_savings_title",
            value: "Consistent Monthly Savings",
            comment: "Title for consistent monthly savings")
        static let consistentSavingsDescription = NSLocalizedString(
            "consistent_savings_description",
            value: "You have maintained consistent monthly savings for three months.",
            comment: "Description for consistent monthly savings")
        static let noUnnecessarySpendingTitle = NSLocalizedString(
            "no_unnecessary_spending_title",
            value: "No Unnecessary Spending",
            comment: "Title for avoiding unnecessary spending")
        static let noUnnecessarySpendingDescription = NSLocalizedString(
            "no_unnecessary_spending_description",
            value: "You have avoided unnecessary spending for a whole month.",
            comment: "Description for avoiding unnecessary spending")
        static let weeklyBudgetTitle = NSLocalizedString(
            "weekly_budget_title",
            value: "Weekly Budget Goal",
            comment: "Title for achieving the weekly budget goal")
        static let weeklyBudgetDescription = NSLocalizedString(
            "weekly_budget_description",
            value: "You have successfully stayed within your budget for a whole week.",
            comment: "Description for achieving the weekly budget goal")
        static let emergencyFundTitle = NSLocalizedString(
            "emergency_fund_title",
            value: "Emergency Fund Established",
            comment: "Title for establishing an emergency fund")
        static let emergencyFundDescription = NSLocalizedString(
            "emergency_fund_description",
            value: "You have created an emergency fund worth three months of expenses.",
            comment: "Description for establishing an emergency fund")
        static let highSavingsRateTitle = NSLocalizedString(
            "high_savings_rate_title",
            value: "High Savings Rate",
            comment: "Title for achieving a high savings rate")
        static let highSavingsRateDescription = NSLocalizedString(
            "high_savings_rate_description",
            value: "You have saved more than 20% of your income this month.",
            comment: "Description for achieving a high savings rate")
        static let firstInvestmentTitle = NSLocalizedString(
            "first_investment_title",
            value: "First Investment Made",
            comment: "Title for making the first investment")
        static let firstInvestmentDescription = NSLocalizedString(
            "first_investment_description",
            value: "You have made your first investment towards your financial future.",
            comment: "Description for making the first investment")
        static let subscriptionCleanupTitle = NSLocalizedString(
            "subscription_cleanup_title",
            value: "Subscription Clean-up",
            comment: "Title for canceling unused subscriptions")
        static let subscriptionCleanupDescription = NSLocalizedString(
            "subscription_cleanup_description",
            value: "You have canceled unused subscriptions to reduce your monthly expenses.",
            comment: "Description for canceling unused subscriptions")
        static let debtPaidOffTitle = NSLocalizedString(
            "debt_paid_off_title",
            value: "Debt Paid Off",
            comment: "Title for paying off debt")
        static let debtPaidOffDescription = NSLocalizedString(
            "debt_paid_off_description",
            value: "You have paid off a major debt.",
            comment: "Description for paying off debt")
    }
    
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
        static let expenseReminderTimeLabel = NSLocalizedString(
            "expense_reminder_time_label",
            value: "Expense Reminder Time",
            comment: "Expense Reminder Time Label")
        static let goalAlertTimeLabel = NSLocalizedString(
            "goal_alert_time_label",
            value: "Goal Alert Time",
            comment: "Goal Alert Time Label")
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
        static let goalDetailsHeadline = NSLocalizedString(
            "goal_details_headline",
            value: "Goal details",
            comment: "Goal Details Headline")
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
        static let newGoalButton = NSLocalizedString(
            "add_new_goal_button",
            value: "Add New Goal",
            comment: "Add New Goal Button")
        
        static let downloadWeeklyReportButton = NSLocalizedString(
            "download_weekly_report_button",
            value: "Download Weekly Report",
            comment: "Download Weekly Report Button")
        
        static let updateInformationButton = NSLocalizedString(
            "update_information_button",
            value: "Update Information",
            comment: "Update Information Button")
        static let changePasswordButton = NSLocalizedString(
            "change_password_button",
            value: "Change Password",
            comment: "Change Password Button")
        static let signOutButton = NSLocalizedString(
            "sign_out_button",
            value: "Sign Out",
            comment: "Sign Out Button")
        
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
        static let goalNamePlaceholder = NSLocalizedString(
            "goal_name_placeholder",
            value: "Goal name",
            comment: "Goal Name Placeholder")
        static let goalAmountPlaceholder = NSLocalizedString(
            "goal_amount_placeholder",
            value: "Goal amount",
            comment: "Goal Amount Placeholder")
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
    }
}
