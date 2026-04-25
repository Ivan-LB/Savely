import SwiftUI
import SwiftData

struct ExpenseTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ExpenseTrackerViewModel()
    @State private var showCameraView = false
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case description, amount }

    // Group expenses by relative date
    private var groupedExpenses: [(String, [ExpenseModel])] {
        let calendar = Calendar.current
        let sorted = viewModel.expenses
        var groups: [(String, [ExpenseModel])] = []
        var used: Set<String> = []
        for expense in sorted {
            let label: String
            if calendar.isDateInToday(expense.date) { label = "Today" }
            else if calendar.isDateInYesterday(expense.date) { label = "Yesterday" }
            else {
                let f = DateFormatter(); f.dateFormat = "EEE, MMM d"
                label = f.string(from: expense.date)
            }
            if !used.contains(label) {
                used.insert(label)
                groups.append((label, sorted.filter { e in
                    if label == "Today" { return calendar.isDateInToday(e.date) }
                    if label == "Yesterday" { return calendar.isDateInYesterday(e.date) }
                    let f = DateFormatter(); f.dateFormat = "EEE, MMM d"
                    return f.string(from: e.date) == label
                }))
            }
        }
        return groups
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // — Header —
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Expenses")
                            .font(.system(size: 34, weight: .regular, design: .serif))
                            .foregroundStyle(Color.warmInk)
                        Text("April · \(formattedTotal)")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.warmInkMuted)
                    }
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.warmInk)
                            .frame(width: 40, height: 40)
                            .background(Color.warmSurface)
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.warmLine, lineWidth: 1))
                    }
                }
                .padding(.top, 8)

                // — Scan receipt banner —
                Button(action: { showCameraView = true }) {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 44, height: 44)
                            .overlay(Image(systemName: "camera.fill").font(.system(size: 18)).foregroundStyle(.white))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Scan a receipt")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("We'll read the total and category")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.white.opacity(0.65))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                    .padding(16)
                    .background(Color.warmInk)
                    .cornerRadius(20)
                }
                .sheet(isPresented: $showCameraView) {
                    let cameraViewModel = CameraViewModel(expenseViewModel: viewModel)
                    CameraView(viewModel: cameraViewModel)
                }

                // — Inline add —
                HStack(spacing: 10) {
                    TextField("What did you buy?", text: $viewModel.expenseDescription)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.warmInk)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color.warmBg)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.warmLineSoft, lineWidth: 1))
                        .focused($focusedField, equals: .description)

                    HStack(spacing: 0) {
                        Text("$").foregroundStyle(Color.warmInkMuted).padding(.leading, 8)
                        TextField("0.00", text: $viewModel.amount)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 14))
                            .monospacedDigit()
                            .padding(.vertical, 0)
                            .frame(width: 70)
                            .focused($focusedField, equals: .amount)
                    }
                    .frame(height: 40)
                    .background(Color.warmBg)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.warmLineSoft, lineWidth: 1))

                    Button(action: { viewModel.addExpense(); focusedField = nil }) {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.warmGreen)
                            .cornerRadius(10)
                    }
                }
                .padding(14)
                .background(Color.warmSurface)
                .cornerRadius(18)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.warmLine, lineWidth: 1))

                // — Grouped list —
                if viewModel.expenses.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "tray").font(.system(size: 40)).foregroundStyle(Color.warmInkMuted)
                        Text("No expenses yet").font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.warmInkSoft)
                        Text("Add your first expense above").font(.system(size: 13)).foregroundStyle(Color.warmInkMuted)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 44)
                } else {
                    VStack(spacing: 18) {
                        ForEach(groupedExpenses, id: \.0) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.0)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color.warmInkMuted)
                                    .tracking(1)
                                    .textCase(.uppercase)
                                    .padding(.leading, 4)

                                VStack(spacing: 0) {
                                    ForEach(Array(group.1.enumerated()), id: \.element.id) { idx, expense in
                                        ExpenseRowWarm(expense: expense, onDelete: { viewModel.deleteExpense(expense) })
                                        if idx < group.1.count - 1 {
                                            Divider().padding(.leading, 58).overlay(Color.warmLineSoft)
                                        }
                                    }
                                }
                                .background(Color.warmSurface)
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.warmLine, lineWidth: 1))
                            }
                        }
                    }
                }

                Spacer(minLength: 16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.warmBg)
        .navigationBarHidden(true)
        .onAppear { if viewModel.modelContext == nil { viewModel.setModelContext(modelContext) } }
        .alert(isPresented: $viewModel.showError) {
            Alert(title: Text(Strings.Errors.errorLabel), message: Text(viewModel.errorMessage), dismissButton: .default(Text(Strings.Buttons.okButton)))
        }
    }

    private var formattedTotal: String {
        let f = NumberFormatter()
        f.numberStyle = .currency; f.currencySymbol = "$"; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: viewModel.expenses.reduce(0) { $0 + $1.amount })) ?? "$0"
    }
}

// MARK: - Expense Row (warm style)

struct ExpenseRowWarm: View {
    let expense: ExpenseModel
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(iconBg)
                .frame(width: 36, height: 36)
                .overlay(Image(systemName: expenseIcon).font(.system(size: 15)).foregroundStyle(iconColor))

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.expenseDescription)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.warmInk)
                Text(categoryLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.warmInkMuted)
            }
            Spacer()
            Text("−\(formattedAmount(expense.amount))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.warmInk)
                .monospacedDigit()
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Color.warmInkMuted)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .contextMenu {
            Button(role: .destructive, action: { showDeleteConfirmation = true }) { Label("Delete", systemImage: "trash") }
        }
        .confirmationDialog("Delete Expense", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Are you sure you want to delete this expense?") }
    }

    private var expenseIcon: String {
        let d = expense.expenseDescription.lowercased()
        if d.contains("coffee") || d.contains("cafe") { return "cup.and.saucer.fill" }
        if d.contains("grocery") || d.contains("groceries") || d.contains("whole foods") { return "cart.fill" }
        if d.contains("uber") || d.contains("lyft") || d.contains("transit") || d.contains("muni") { return "car.fill" }
        if d.contains("movie") || d.contains("entertainment") { return "tv.fill" }
        if d.contains("restaurant") || d.contains("food") { return "fork.knife" }
        return "creditcard.fill"
    }
    private var iconBg: Color {
        let d = expense.expenseDescription.lowercased()
        if d.contains("coffee") || d.contains("cafe") { return Color.warmAmberSoft }
        if d.contains("grocery") || d.contains("whole foods") { return Color.warmGreenSoft }
        return Color.warmClaySoft
    }
    private var iconColor: Color {
        let d = expense.expenseDescription.lowercased()
        if d.contains("coffee") || d.contains("cafe") { return Color.warmAmber }
        if d.contains("grocery") || d.contains("whole foods") { return Color.warmGreen }
        return Color.warmClay
    }
    private var categoryLabel: String {
        let d = expense.expenseDescription.lowercased()
        if d.contains("coffee") || d.contains("cafe") { return "Coffee" }
        if d.contains("grocery") || d.contains("groceries") { return "Groceries" }
        if d.contains("uber") || d.contains("lyft") || d.contains("muni") { return "Transit" }
        return "Expense"
    }
    private func formattedAmount(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencySymbol = "$"; f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: v)) ?? "$0"
    }
}

#Preview { ExpenseTrackerView() }
