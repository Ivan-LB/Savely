import SwiftUI
import SwiftData

// MARK: - Dashboard

struct DashboardView: View {
    /// Set by `MainNavigationView` so "See all" can switch to the Money tab.
    var onSeeAll: () -> Void = {}

    @Query(sort: \ExpenseModel.date, order: .reverse) private var expenses: [ExpenseModel]
    @Query(sort: \IncomeModel.date, order: .reverse)  private var incomes: [IncomeModel]
    @Query private var goals: [GoalModel]
    @Environment(\.modelContext) private var modelContext
    @StateObject private var tipsViewModel = TipsAndSuggestionViewModel()

    private var favoriteGoal: GoalModel? { goals.first(where: { $0.isFavorite }) }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Morning"
        case 12..<17: return "Afternoon"
        default:      return "Evening"
        }
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE · MMMM d"
        return f.string(from: Date())
    }

    // Monthly totals (current month)
    private var monthlyIncome: Double {
        let cal = Calendar.current; let now = Date()
        return incomes.filter { cal.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }
    private var monthlyExpenses: Double {
        let cal = Calendar.current; let now = Date()
        return expenses.filter { cal.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    // Merge recent transactions
    private var recentTransactions: [AnyTransaction] {
        let exp = expenses.prefix(8).map { AnyTransaction(id: $0.id.uuidString + "e", description: $0.expenseDescription, amount: $0.amount, date: $0.date, isExpense: true) }
        let inc = incomes.prefix(8).map  { AnyTransaction(id: $0.id.uuidString + "i", description: $0.incomeDescription, amount: $0.amount, date: $0.date, isExpense: false) }
        return (exp + inc).sorted { $0.date > $1.date }.prefix(5).map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // — Greeting — (no avatar: there is no account, so no
                // person to represent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedDate)
                        .warmFont(13)
                        .foregroundStyle(Color.warmInkMuted)
                    Text(greeting + ".")
                        .warmFont(30, weight: .regular, design: .serif)
                        .foregroundStyle(Color.warmInk)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                // One heading for VoiceOver: "Good afternoon. Tuesday, August 18"
                // instead of the bare "Afternoon." the audit flags as
                // not human-readable.
                .accessibilityElement(children: .ignore)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(Text("Good \(greeting.lowercased()). \(formattedDate)"))

                // — Hero Goal Card —
                if let goal = favoriteGoal {
                    HeroGoalCard(goal: goal, modelContext: modelContext)
                } else {
                    EmptyGoalCard()
                }

                // — Tip of the day (hidden for the App Store release, FeatureFlags.tipsEnabled) —
                if FeatureFlags.tipsEnabled {
                    TipOfTheDayCard(viewModel: tipsViewModel)
                }

                // — Monthly summary —
                HStack(spacing: 10) {
                    MonthlySummaryCell(label: "In · \(currentMonthAbbr)", value: monthlyIncome, change: nil, positive: true)
                    MonthlySummaryCell(label: "Out · \(currentMonthAbbr)", value: monthlyExpenses, change: nil, positive: false)
                }

                // — Recent transactions —
                VStack(spacing: 0) {
                    HStack {
                        Text("Recent")
                            .warmFont(20, weight: .regular, design: .serif)
                            .foregroundStyle(Color.warmInk)
                        Spacer()
                        Button(action: onSeeAll) {
                            Text("See all")
                                .warmFont(13, weight: .medium)
                                .foregroundStyle(Color.warmGreen)
                                .tappable44()
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 10)

                    if recentTransactions.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .warmFont(36)
                                .foregroundStyle(Color.warmInkMuted)
                            Text("No transactions yet")
                                .warmFont(14)
                                .foregroundStyle(Color.warmInkMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(recentTransactions.enumerated()), id: \.element.id) { idx, txn in
                                RecentTransactionRow(txn: txn)
                                if idx < recentTransactions.count - 1 {
                                    Divider()
                                        .padding(.leading, 58)
                                        .overlay(Color.warmLineSoft)
                                }
                            }
                        }
                        .background(Color.warmSurface)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.warmLine, lineWidth: 1))
                    }
                }

                Spacer(minLength: 16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.warmBg)
        .navigationBarHidden(true)
        .onAppear {
            // No tip generation at all while the flag is off — not just hidden UI.
            if FeatureFlags.tipsEnabled && tipsViewModel.modelContext == nil {
                tipsViewModel.setModelContext(modelContext)
            }
        }
    }

    private var currentMonthAbbr: String {
        DateFormatter().monthSymbols[Calendar.current.component(.month, from: Date()) - 1].prefix(3).uppercased()
    }
}

// MARK: - Merged transaction type

struct AnyTransaction {
    let id: String
    let description: String
    let amount: Double
    let date: Date
    let isExpense: Bool
}

// MARK: - Hero Goal Card

struct HeroGoalCard: View {
    let goal: GoalModel
    let modelContext: ModelContext
    @State private var showDepositSheet = false
    @State private var showEditSheet = false
    @Query private var goalDeposits: [DepositModel]

    init(goal: GoalModel, modelContext: ModelContext) {
        self.goal = goal
        self.modelContext = modelContext
        let goalID = goal.id
        _goalDeposits = Query(filter: #Predicate<DepositModel> { $0.goalID == goalID })
    }

    private var pace: GoalPace { GoalPace.compute(goal: goal, deposits: goalDeposits) }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .warmFont(12)
                            .foregroundStyle(Color.warmAmber)
                            .accessibilityHidden(true)
                        Text("FAVORITE GOAL")
                            .warmFont(11, weight: .semibold)
                            .foregroundStyle(Color.warmInkMuted)
                            .tracking(0.8)
                    }
                    Spacer()
                }

                Text(goal.name)
                    .warmFont(26, weight: .regular, design: .serif)
                    .foregroundStyle(Color.warmInk)

                // Ring + stats
                HStack(alignment: .center, spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.warmTrack, lineWidth: 12)
                        Circle()
                            .trim(from: 0, to: goal.progress)
                            .stroke(Color.warmGreen, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 0) {
                            HStack(alignment: .lastTextBaseline, spacing: 2) {
                                Text("\(Int(goal.progress * 100))")
                                    .warmFont(36, weight: .regular, design: .serif)
                                    .foregroundStyle(Color.warmInk)
                                Text("%")
                                    .warmFont(18)
                                    .foregroundStyle(Color.warmInkMuted)
                            }
                        }
                    }
                    .frame(width: 132, height: 132)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("Progress"))
                    .accessibilityValue(Text("\(Int(goal.progress * 100)) percent"))

                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SAVED")
                                .warmFont(11, weight: .semibold)
                                .foregroundStyle(Color.warmInkMuted)
                                .tracking(0.8)
                            Text(formattedAmount(goal.current))
                                .warmFont(24, weight: .regular, design: .serif)
                                .foregroundStyle(Color.warmInk)
                            Text("of \(formattedAmount(goal.target))")
                                .warmFont(12)
                                .foregroundStyle(Color.warmInkMuted)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("PACE")
                                .warmFont(11, weight: .semibold)
                                .foregroundStyle(Color.warmInkMuted)
                                .tracking(0.8)
                            Text(pace.label)
                                .warmFont(14, weight: .semibold)
                                .foregroundStyle(pace.status == .behind ? Color.warmClay : Color.warmGreen)
                        }
                    }
                }

                // Buttons
                HStack(spacing: 10) {
                    Button(action: { showDepositSheet = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .warmFont(14, weight: .semibold)
                            Text("Add deposit")
                                .warmFont(15, weight: .semibold)
                        }
                        .foregroundStyle(Color.warmOnGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.warmGreenFill)
                        .cornerRadius(14)
                    }

                    Button(action: { showEditSheet = true }) {
                        Image(systemName: "pencil")
                            .warmFont(16)
                            .foregroundStyle(Color.warmInk)
                            .frame(width: 48, height: 48)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.warmLine, lineWidth: 1))
                    }
                    .accessibilityLabel("Edit goal")
                }
            }
            .padding(24)
        }
        .background(Color.warmSurface)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.warmLine, lineWidth: 1))
        .shadow(color: Color.warmShadow, radius: 12, x: 0, y: 4)
        .sheet(isPresented: $showDepositSheet) {
            DepositSheet(goal: goal, modelContext: modelContext)
        }
        .sheet(isPresented: $showEditSheet) {
            GoalEditSheet(goal: goal)
        }
    }

    private func formattedAmount(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "$"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "$0"
    }
}

// MARK: - Deposit Sheet

struct DepositSheet: View {
    let goal: GoalModel
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""
    @State private var note = ""
    @State private var errorMessage: String?
    private let quickAmounts: [Double] = [25, 50, 100, 250]

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule().fill(Color.warmLine).frame(width: 40, height: 4).padding(.top, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Add a deposit")
                        .warmFont(22, weight: .regular, design: .serif)
                        .foregroundStyle(Color.warmInk)
                    Text("Move money toward \(goal.name.components(separatedBy: ",").first ?? goal.name).")
                        .warmFont(13)
                        .foregroundStyle(Color.warmInkMuted)

                    // Large amount
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("$")
                            .warmFont(48, weight: .regular, design: .serif)
                            .foregroundStyle(Color.warmInkMuted)
                        TextField("0", text: $amountText)
                            .warmFont(64, weight: .regular, design: .serif)
                            .foregroundStyle(Color.warmInk)
                            .keyboardType(.decimalPad)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 4)

                    // Quick amount pills
                    HStack(spacing: 8) {
                        ForEach(quickAmounts, id: \.self) { amt in
                            let isSelected = amountText == String(Int(amt))
                            Button(action: { amountText = String(Int(amt)) }) {
                                Text("$\(Int(amt))")
                                    .warmFont(13, weight: .semibold)
                                    .foregroundStyle(isSelected ? Color.warmGreenDeep : Color.warmInkMuted)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? Color.warmGreenSoft : Color.clear)
                                    .cornerRadius(999)
                                    .overlay(Capsule().stroke(isSelected ? Color.warmGreenSoft : Color.warmLine, lineWidth: 1))
                            }
                        }
                    }

                    // Note
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NOTE")
                            .warmFont(11, weight: .semibold)
                            .foregroundStyle(Color.warmInkMuted)
                            .tracking(0.8)
                        TextField("Optional note", text: $note)
                            .warmFont(14)
                            .padding(14)
                            .frame(height: 44)
                            .background(Color.warmBg)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.warmLine, lineWidth: 1))
                    }

                    Button(action: saveDeposit) {
                        Text("Add \(amountText.isEmpty ? "" : "$\(amountText)") to \(goal.name.components(separatedBy: ",").first ?? goal.name)")
                            .warmFont(15, weight: .semibold)
                            .foregroundStyle(Color.warmOnGreen)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.warmGreenFill)
                            .cornerRadius(14)
                    }
                    .disabled(depositAmount == nil)
                    .opacity(depositAmount == nil ? 0.5 : 1)
                }
                .padding(24)
            }
        }
        .background(Color.warmSurface)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .honorsReduceMotion()
        .alert("Couldn't save the deposit", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var depositAmount: Double? { Double(amountText) }

    private func saveDeposit() {
        guard let amt = depositAmount, amt > 0 else { return }
        do {
            try GoalDeposits.record(goal: goal, amount: amt, note: note, source: .manual, context: modelContext)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Empty Goal Card

struct EmptyGoalCard: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "target")
                .warmFont(40)
                .foregroundStyle(Color.warmInkMuted)
            Text("No active goal")
                .warmFont(17, weight: .semibold)
                .foregroundStyle(Color.warmInkSoft)
            Text("Star a goal to see it here")
                .warmFont(14)
                .foregroundStyle(Color.warmInkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.warmSurface)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.warmLine, lineWidth: 1))
    }
}

// MARK: - Tip of the Day Card

struct TipOfTheDayCard: View {
    @ObservedObject var viewModel: TipsAndSuggestionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .warmFont(12, weight: .semibold)
                    .foregroundStyle(Color.warmGreen)
                Text("TIP OF THE DAY")
                    .warmFont(11, weight: .bold)
                    .foregroundStyle(Color.warmGreen)
                    .tracking(1)
            }

            if let tip = viewModel.currentTip {
                Text(tip.content)
                    .warmFont(17, weight: .regular, design: .serif)
                    .foregroundStyle(Color.warmInk)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No tip for today yet — check back soon.")
                    .warmFont(17, weight: .regular, design: .serif)
                    .foregroundStyle(Color.warmInkSoft)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.warmGreenTint)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.warmGreenSoft, lineWidth: 1))
    }
}

// MARK: - Monthly Summary Cell

struct MonthlySummaryCell: View {
    let label: String
    let value: Double
    let change: String?
    let positive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .warmFont(11, weight: .semibold)
                .foregroundStyle(Color.warmInkMuted)
                .tracking(0.8)
            Text(formattedAmount(value))
                .warmFont(20, weight: .regular, design: .serif)
                .foregroundStyle(Color.warmInk)
            if let change = change {
                HStack(spacing: 4) {
                    Image(systemName: positive ? "arrow.up" : "arrow.down")
                        .warmFont(9, weight: .semibold)
                    Text(change)
                        .warmFont(11, weight: .semibold)
                }
                .foregroundStyle(positive ? Color.warmGreen : Color.warmClay)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.warmSurface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.warmLine, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private func formattedAmount(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "$"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "$0"
    }
}

// MARK: - Recent Transaction Row

struct RecentTransactionRow: View {
    let txn: AnyTransaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconBg)
                    .frame(width: 34, height: 34)
                Image(systemName: txn.isExpense ? "arrow.down" : "arrow.up")
                    .warmFont(14, weight: .medium)
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(txn.description)
                    .warmFont(14, weight: .semibold)
                    .foregroundStyle(Color.warmInk)
                Text(shortDate(txn.date))
                    .warmFont(12)
                    .foregroundStyle(Color.warmInkMuted)
            }

            Spacer()

            Text(formattedAmount)
                .warmFont(14, weight: .semibold)
                .foregroundStyle(txn.isExpense ? Color.warmInk : Color.warmGreen)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(txn.isExpense ? String(localized: "Expense") : String(localized: "Income")), \(txn.description), \(shortDate(txn.date))"))
        .accessibilityValue(Text(formattedAmount))
    }

    private var iconBg: Color  { txn.isExpense ? Color.warmAmberSoft : Color.warmGreenSoft }
    private var iconColor: Color { txn.isExpense ? Color.warmAmber : Color.warmGreen }

    private var formattedAmount: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "$"
        f.maximumFractionDigits = 2
        let val = f.string(from: NSNumber(value: txn.amount)) ?? "$0"
        return txn.isExpense ? "−\(val)" : "+\(val)"
    }

    private func shortDate(_ d: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(d) { return "Today" }
        if cal.isDateInYesterday(d) { return "Yesterday" }
        let f = DateFormatter(); f.dateFormat = "EEE"
        return f.string(from: d)
    }
}

#Preview { DashboardView() }
