import SwiftUI
import SwiftData

// MARK: - Dashboard

struct DashboardView: View {
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
                // — Greeting —
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formattedDate)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.warmInkMuted)
                        Text(greeting + ".")
                            .font(.system(size: 30, weight: .regular, design: .serif))
                            .foregroundStyle(Color.warmInk)
                    }
                    Spacer()
                    Circle()
                        .fill(Color.warmAmberSoft)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.warmAmber)
                        )
                }
                .padding(.top, 8)

                // — Hero Goal Card —
                if let goal = favoriteGoal {
                    HeroGoalCard(goal: goal, modelContext: modelContext)
                } else {
                    EmptyGoalCard()
                }

                // — Tip of the day —
                TipOfTheDayCard(viewModel: tipsViewModel)

                // — Monthly summary —
                HStack(spacing: 10) {
                    MonthlySummaryCell(label: "In · \(currentMonthAbbr)", value: monthlyIncome, change: nil, positive: true)
                    MonthlySummaryCell(label: "Out · \(currentMonthAbbr)", value: monthlyExpenses, change: nil, positive: false)
                }

                // — Recent transactions —
                VStack(spacing: 0) {
                    HStack {
                        Text("Recent")
                            .font(.system(size: 20, weight: .regular, design: .serif))
                            .foregroundStyle(Color.warmInk)
                        Spacer()
                        Text("See all")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.warmGreen)
                    }
                    .padding(.bottom, 10)

                    if recentTransactions.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.system(size: 36))
                                .foregroundStyle(Color.warmInkMuted)
                            Text("No transactions yet")
                                .font(.system(size: 14))
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
            if tipsViewModel.modelContext == nil {
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

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.warmAmber)
                        Text("FAVORITE GOAL")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.warmInkMuted)
                            .tracking(0.8)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.warmInkMuted)
                        .frame(width: 32, height: 32)
                        .background(Color.warmBg)
                        .cornerRadius(10)
                }

                Text(goal.name)
                    .font(.system(size: 26, weight: .regular, design: .serif))
                    .foregroundStyle(Color.warmInk)

                // Ring + stats
                HStack(alignment: .center, spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color(red: 0.93, green: 0.90, blue: 0.83), lineWidth: 12)
                        Circle()
                            .trim(from: 0, to: goal.progress)
                            .stroke(Color.warmGreen, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 0) {
                            HStack(alignment: .lastTextBaseline, spacing: 2) {
                                Text("\(Int(goal.progress * 100))")
                                    .font(.system(size: 36, weight: .regular, design: .serif))
                                    .foregroundStyle(Color.warmInk)
                                Text("%")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.warmInkMuted)
                            }
                        }
                    }
                    .frame(width: 132, height: 132)

                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SAVED")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.warmInkMuted)
                                .tracking(0.8)
                            Text(formattedAmount(goal.current))
                                .font(.system(size: 24, weight: .regular, design: .serif))
                                .foregroundStyle(Color.warmInk)
                            Text("of \(formattedAmount(goal.target))")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.warmInkMuted)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("PACE")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.warmInkMuted)
                                .tracking(0.8)
                            Text(paceText)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.warmGreen)
                        }
                    }
                }

                // Buttons
                HStack(spacing: 10) {
                    Button(action: { showDepositSheet = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Add deposit")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.warmGreen)
                        .cornerRadius(14)
                    }

                    Button(action: {}) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.warmInk)
                            .frame(width: 48, height: 48)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.warmLine, lineWidth: 1))
                    }
                }
            }
            .padding(24)
        }
        .background(Color.warmSurface)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.warmLine, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
        .sheet(isPresented: $showDepositSheet) {
            DepositSheet(goal: goal, modelContext: modelContext)
        }
    }

    private var paceText: String {
        goal.progress >= 1.0 ? "Complete!" : "On track"
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
    private let quickAmounts: [Double] = [25, 50, 100, 250]

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule().fill(Color.warmLine).frame(width: 40, height: 4).padding(.top, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Add a deposit")
                        .font(.system(size: 22, weight: .regular, design: .serif))
                        .foregroundStyle(Color.warmInk)
                    Text("Move money toward \(goal.name.components(separatedBy: ",").first ?? goal.name).")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.warmInkMuted)

                    // Large amount
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("$")
                            .font(.system(size: 48, weight: .regular, design: .serif))
                            .foregroundStyle(Color.warmInkMuted)
                        TextField("0", text: $amountText)
                            .font(.system(size: 64, weight: .regular, design: .serif))
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
                                    .font(.system(size: 13, weight: .semibold))
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
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.warmInkMuted)
                            .tracking(0.8)
                        TextField("Optional note", text: $note)
                            .font(.system(size: 14))
                            .padding(14)
                            .frame(height: 44)
                            .background(Color.warmBg)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.warmLine, lineWidth: 1))
                    }

                    Button(action: saveDeposit) {
                        Text("Add \(amountText.isEmpty ? "" : "$\(amountText)") to \(goal.name.components(separatedBy: ",").first ?? goal.name)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.warmGreen)
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
    }

    private var depositAmount: Double? { Double(amountText) }

    private func saveDeposit() {
        guard let amt = depositAmount, amt > 0 else { return }
        goal.current = min(goal.current + amt, goal.target)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Empty Goal Card

struct EmptyGoalCard: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "target")
                .font(.system(size: 40))
                .foregroundStyle(Color.warmInkMuted)
            Text("No active goal")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.warmInkSoft)
            Text("Star a goal to see it here")
                .font(.system(size: 14))
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
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.warmGreen)
                Text("TIP OF THE DAY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.warmGreen)
                    .tracking(1)
            }

            if let tip = viewModel.currentTip {
                Text(tip.content)
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundStyle(Color.warmInk)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No tip for today yet — check back soon.")
                    .font(.system(size: 17, weight: .regular, design: .serif))
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
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.warmInkMuted)
                .tracking(0.8)
            Text(formattedAmount(value))
                .font(.system(size: 20, weight: .regular, design: .serif))
                .foregroundStyle(Color.warmInk)
            if let change = change {
                HStack(spacing: 4) {
                    Image(systemName: positive ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .semibold))
                    Text(change)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(positive ? Color.warmGreen : Color.warmClay)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.warmSurface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.warmLine, lineWidth: 1))
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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(txn.description)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.warmInk)
                Text(shortDate(txn.date))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.warmInkMuted)
            }

            Spacer()

            Text(formattedAmount)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(txn.isExpense ? Color.warmInk : Color.warmGreen)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
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
