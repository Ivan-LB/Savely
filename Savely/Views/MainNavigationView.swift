import SwiftUI
import SwiftData

// MARK: - Quick-add screen routing

enum QuickAddScreen: Equatable {
    case actionSheet, expense, income, deposit
}

// MARK: - Main navigation

struct MainNavigationView: View {
    @State private var selectedTab = 0
    @State private var showActionSheet = false
    @State private var quickScreen: QuickAddScreen = .actionSheet
    @State private var showAddGoalFlow = false
    @Environment(\.modelContext) private var modelContext
    /// The receipt scanner presented from the "+" sheet. It writes through
    /// its own expense view model, exactly like the Money tab's banner does;
    /// the Money tab hears about the new row through the posted notification.
    @StateObject private var scanExpenseVM = ExpenseTrackerViewModel()
    @State private var scanner: ReceiptScanModel?

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationStack { DashboardView(onSeeAll: { selectedTab = 2 }) }.tag(0)
                NavigationStack { GoalsView(showAddGoalFlow: $showAddGoalFlow) }.tag(1)
                NavigationStack { MoneyView() }.tag(2)
                NavigationStack { ProfileView() }.tag(3)
            }
            .toolbar(.hidden, for: .tabBar)
            .tint(Color.warmGreen)

            WarmTabBar(
                selectedTab: $selectedTab,
                isExpanded: showActionSheet,
                onAddTapped: {
                    quickScreen = .actionSheet
                    showActionSheet = true
                }
            )
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showActionSheet) {
            WarmQuickAddContainer(
                screen: $quickScreen,
                onDismiss: { showActionSheet = false },
                onNewGoal: {
                    showActionSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showAddGoalFlow = true
                    }
                },
                onScan: {
                    showActionSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        scanExpenseVM.setModelContext(modelContext)
                        scanner = ReceiptScanModel(expenseStore: scanExpenseVM)
                    }
                }
            )
            .honorsReduceMotion()
            .presentationBackground(Color.warmBg)
            .presentationCornerRadius(28)
            .presentationDetents(quickScreen == .actionSheet ? [.height(540)] : [.large])
            .presentationDragIndicator(.hidden)
        }
        .fullScreenCover(isPresented: $showAddGoalFlow) {
            AddGoalFlowView(isPresented: $showAddGoalFlow)
                .honorsReduceMotion()
        }
        .fullScreenCover(item: $scanner) { model in
            ReceiptScanFlowView(model: model)
        }
    }
}

// MARK: - Warm tab bar

struct WarmTabBar: View {
    @Binding var selectedTab: Int
    var isExpanded: Bool = false
    let onAddTapped: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            WarmTabBarItem(icon: "house.fill",       label: "Home",  tag: 0, selectedTab: $selectedTab)
            WarmTabBarItem(icon: "target",            label: "Goals", tag: 1, selectedTab: $selectedTab)

            Button(action: onAddTapped) {
                Image(systemName: "plus")
                    .warmFont(22, weight: .semibold)
                    .foregroundStyle(isExpanded ? Color.warmOnGreen : Color.warmOnInk)
                    .frame(width: 52, height: 52)
                    .background(isExpanded ? Color.warmGreenFill : Color.warmInk)
                    .cornerRadius(18)
                    .shadow(
                        color: isExpanded ? Color.warmGreenFill.opacity(0.38) : Color.warmShellShadow,
                        radius: 10, x: 0, y: 4
                    )
                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
            }
            .accessibilityLabel(isExpanded ? "Close" : "Add")
            .accessibilityHint("Log an expense, income, deposit, or new goal")
            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: isExpanded)
            .frame(maxWidth: .infinity)
            .offset(y: -14)

            WarmTabBarItem(icon: "wallet.pass.fill", label: "Money", tag: 2, selectedTab: $selectedTab)
            WarmTabBarItem(icon: "person.fill",       label: "Me",    tag: 3, selectedTab: $selectedTab)
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 28)
        .background(Color.warmSurface)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.warmLine).frame(height: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isTabBar)
        // Like UITabBar: labels stop growing at the largest non-accessibility
        // size — five items in 4 columns cannot carry AX text; VoiceOver
        // labels and the 44pt targets carry accessibility here.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

struct WarmTabBarItem: View {
    let icon: String; let label: String; let tag: Int
    @Binding var selectedTab: Int
    private var isActive: Bool { selectedTab == tag }

    var body: some View {
        Button(action: { selectedTab = tag }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .warmFont(22, weight: isActive ? .semibold : .regular)
                Text(label)
                    .warmFont(10, weight: isActive ? .semibold : .medium)
            }
            .foregroundStyle(isActive ? Color.warmGreen : Color.warmInkMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}

// MARK: - Quick-add container

struct WarmQuickAddContainer: View {
    @Binding var screen: QuickAddScreen
    let onDismiss: () -> Void
    let onNewGoal: () -> Void
    let onScan: () -> Void

    var body: some View {
        Group {
            switch screen {
            case .actionSheet:
                WarmActionSheet(
                    onSelect: { s in withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) { screen = s } },
                    onDismiss: onDismiss,
                    onNewGoal: onNewGoal,
                    onScan: onScan
                )
            case .expense:
                WarmQuickExpenseView(
                    onBack: { withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) { screen = .actionSheet } },
                    onSave: onDismiss
                )
            case .income:
                WarmQuickIncomeView(
                    onBack: { withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) { screen = .actionSheet } },
                    onSave: onDismiss
                )
            case .deposit:
                WarmQuickDepositView(
                    onBack: { withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) { screen = .actionSheet } },
                    onSave: onDismiss
                )
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: screen)
    }
}

// MARK: - Action sheet

private struct QuickAction {
    enum Kind { case screen(QuickAddScreen), newGoal, scan }
    let icon: String; let label: String; let sub: String
    let bg: Color; let fg: Color; let kind: Kind
}

private let quickActions: [QuickAction] = [
    QuickAction(icon: "wallet.pass",  label: "Log expense",       sub: "Coffee, groceries, anything",  bg: .warmAmberSoft, fg: .warmAmber, kind: .screen(.expense)),
    QuickAction(icon: "arrow.up",     label: "Log income",        sub: "Paycheck, gift, side work",    bg: .warmGreenSoft, fg: .warmGreen, kind: .screen(.income)),
    QuickAction(icon: "target",       label: "Deposit to a goal", sub: "Move money toward a goal",     bg: .warmSkySoft,   fg: .warmSky,   kind: .screen(.deposit)),
    QuickAction(icon: "camera",       label: "Scan a receipt",    sub: "We'll read the total, merchant and date", bg: .warmClaySoft, fg: .warmClay, kind: .scan),
    QuickAction(icon: "plus",         label: "New goal",          sub: "Start something new",
                bg: .warmLilacSoft, fg: .warmLilac, kind: .newGoal),
]

struct WarmActionSheet: View {
    let onSelect: (QuickAddScreen) -> Void
    let onDismiss: () -> Void
    let onNewGoal: () -> Void
    let onScan: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.warmLine).frame(width: 40, height: 4)
                .padding(.top, 14).padding(.bottom, 12)

            HStack(alignment: .center) {
                Text("What's the move?")
                    .warmFont(24, weight: .regular, design: .serif)
                    .foregroundStyle(Color.warmInk)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .warmFont(11, weight: .medium)
                        .foregroundStyle(Color.warmInkSoft)
                        .frame(width: 32, height: 32)
                        .background(Color.warmSurface)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.warmLine, lineWidth: 1))
                        .tappable44()
                }
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, 20)

            Text("Pick what to log right now.")
                .warmFont(13).foregroundStyle(Color.warmInkMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20).padding(.top, 2).padding(.bottom, 18)

            VStack(spacing: 0) {
                ForEach(Array(quickActions.enumerated()), id: \.offset) { i, action in
                    Button(action: {
                        switch action.kind {
                        case .screen(let target): onSelect(target)
                        case .newGoal: onNewGoal()
                        case .scan: onScan()
                        }
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: action.icon)
                                .warmFont(16)
                                .foregroundStyle(action.fg)
                                .frame(width: 40, height: 40)
                                .background(action.bg)
                                .cornerRadius(12)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(action.label)
                                    .warmFont(15, weight: .semibold)
                                    .foregroundStyle(Color.warmInk)
                                Text(action.sub)
                                    .warmFont(12)
                                    .foregroundStyle(Color.warmInkMuted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .warmFont(11, weight: .medium)
                                .foregroundStyle(Color.warmInkMuted)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if i < quickActions.count - 1 {
                        Divider().padding(.horizontal, 16)
                    }
                }
            }
            .background(Color.warmSurface)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.warmLine, lineWidth: 1))
            .padding(.horizontal, 20)

            Spacer(minLength: 28)
        }
        .background(Color.warmBg)
    }
}

// MARK: - Shared numeric keypad

struct WarmKeypad: View {
    @Binding var amountStr: String
    private let keys = ["1","2","3","4","5","6","7","8","9",".","0","⌫"]

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.warmLine).frame(height: 1)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 3), spacing: 0) {
                ForEach(keys, id: \.self) { key in
                    Button(action: { tap(key) }) {
                        Group {
                            if key == "⌫" {
                                Image(systemName: "delete.left")
                                    .warmFont(20, weight: .light)
                            } else {
                                Text(key)
                                    .warmFont(24, weight: .regular, design: .serif)
                            }
                        }
                        .foregroundStyle(Color.warmInk)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(key == "⌫" ? "Delete" : key == "." ? "Decimal point" : key)
                }
            }
            .background(Color.warmSurface)
        }
        // A numeric keypad, like the system one, keeps its key size; the
        // amount above it scales instead.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private func tap(_ key: String) {
        switch key {
        case "⌫":
            if amountStr.count > 1 { amountStr.removeLast() } else { amountStr = "0" }
        case ".":
            if !amountStr.contains(".") { amountStr += "." }
        default:
            if amountStr == "0" { amountStr = key }
            else {
                if let di = amountStr.firstIndex(of: ".") {
                    let places = amountStr.distance(from: amountStr.index(after: di), to: amountStr.endIndex)
                    if places < 2 { amountStr += key }
                } else { amountStr += key }
            }
        }
    }
}

func formatKeypadAmount(_ raw: String) -> String {
    let parts = raw.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
    let intStr = String(parts[0])
    let decStr = parts.count > 1 ? ".\(parts[1])" : ""
    if let n = Double(intStr) {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = 0
        return (f.string(from: NSNumber(value: n)) ?? intStr) + decStr
    }
    return raw
}

// MARK: - Quick expense

/// The expense chips, straight from the canonical categories (what gets stored).
private let expenseCats: [(label: String, bg: Color, fg: Color)] = ExpenseCategory.allCases.map {
    ($0.label, $0.tileBackground, $0 == .other ? Color.warmInkSoft : $0.tileColor)
}

struct WarmQuickExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    let onBack: () -> Void; let onSave: () -> Void

    @State private var amountStr = "0"
    @State private var description = ""
    @State private var selectedCat = ExpenseCategory.coffee.label
    @StateObject private var vm = ExpenseTrackerViewModel()

    private var canSave: Bool { amountStr != "0" }

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.warmLine).frame(width: 40, height: 4)
                .padding(.top, 14).padding(.bottom, 8)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .warmFont(14, weight: .medium).foregroundStyle(Color.warmInkSoft)
                        .frame(width: 32, height: 32)
                        .tappable44()
                }
                .accessibilityLabel("Back")
                Spacer()
                Text("Log expense")
                    .warmFont(18, weight: .regular, design: .serif).foregroundStyle(Color.warmInk)
                Spacer()
                Button("Save", action: saveAndDismiss)
                    .warmFont(13, weight: .semibold).foregroundStyle(Color.warmGreen)
                    .opacity(canSave ? 1 : 0.4).disabled(!canSave)
            }
            .padding(.horizontal, 20).padding(.bottom, 4)

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("−$")
                    .warmFont(32, weight: .regular, design: .serif).foregroundStyle(Color.warmInkMuted)
                Text(formatKeypadAmount(amountStr))
                    .warmFont(72, weight: .regular, design: .serif).foregroundStyle(Color.warmInk)
                    .monospacedDigit().minimumScaleFactor(0.4).lineLimit(1)
            }
            .padding(.top, 8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Expense amount"))
            .accessibilityValue(Text("\(amountStr) dollars"))

            TextField("Merchant · Today", text: $description)
                .warmFont(12).foregroundStyle(Color.warmInkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16).padding(.vertical, 7)
                .background(Color.warmSurface).clipShape(Capsule())
                .overlay(Capsule().stroke(Color.warmLine, lineWidth: 1))
                .padding(.horizontal, 60).padding(.top, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(expenseCats, id: \.label) { cat in
                        let isOn = selectedCat == cat.label
                        Button(action: { selectedCat = cat.label }) {
                            Text(cat.label)
                                .warmFont(13, weight: .semibold)
                                .foregroundStyle(isOn ? cat.fg : Color.warmInkSoft)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(isOn ? cat.bg : Color.clear)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(isOn ? cat.bg : Color.warmLine, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.15), value: selectedCat)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 20)

            Spacer(minLength: 0)
            WarmKeypad(amountStr: $amountStr)
        }
        .onAppear { vm.setModelContext(modelContext) }
        .alert(isPresented: $vm.showError) {
            Alert(title: Text(Strings.Errors.errorLabel), message: Text(vm.errorMessage), dismissButton: .default(Text(Strings.Buttons.okButton)))
        }
    }

    private func saveAndDismiss() {
        guard canSave, let amt = Double(amountStr), amt > 0 else { return }
        // Description and category are independent: the chip is stored as
        // the category always, and only stands in for an empty description.
        vm.expenseDescription = description.isEmpty ? selectedCat : description
        vm.amount = amountStr; vm.addExpense(category: selectedCat); onSave()
    }
}

// MARK: - Quick income

struct WarmQuickIncomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [GoalModel]
    @Query private var allIncomes: [IncomeModel]
    @Query private var allExpenses: [ExpenseModel]
    @Query private var allDeposits: [DepositModel]
    let onBack: () -> Void; let onSave: () -> Void

    @State private var amountStr = "0"
    @State private var description = ""
    @State private var selectedSource = IncomeSource.paycheck.label
    @State private var autoMoveArmed = false
    @StateObject private var vm = IncomesTrackerViewModel()

    private let sources = IncomeSource.allCases.map(\.label)
    private var canSave: Bool { amountStr != "0" }
    private var enteredAmount: Double { Double(amountStr) ?? 0 }

    /// This month's flows — the affordability input for the suggestion.
    private func monthTotal(_ dates: [(Date, Double)]) -> Double {
        let calendar = Calendar.current
        let now = Date()
        return dates
            .filter { calendar.isDate($0.0, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.1 }
    }

    /// Live suggestion — recomputes as the keypad changes, so the offered
    /// amount can never exceed the income being logged nor what this
    /// month's income-vs-expense margin can actually spare.
    private var autoMoveSuggestion: AutoMoveSuggestion? {
        guard FeatureFlags.autoMoveSuggestionsEnabled else { return nil }
        return AutoMoveSuggestion.compute(
            goals: goals,
            incomeAmount: enteredAmount,
            monthIncomeTotal: monthTotal(allIncomes.map { ($0.date, $0.amount) }),
            monthExpenseTotal: monthTotal(allExpenses.map { ($0.date, $0.amount) }),
            monthDepositTotal: GoalDeposits.monthTotal(allDeposits)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.warmLine).frame(width: 40, height: 4)
                .padding(.top, 14).padding(.bottom, 8)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .warmFont(14, weight: .medium).foregroundStyle(Color.warmInkSoft)
                        .frame(width: 32, height: 32)
                        .tappable44()
                }
                .accessibilityLabel("Back")
                Spacer()
                Text("Log income")
                    .warmFont(18, weight: .regular, design: .serif).foregroundStyle(Color.warmInk)
                Spacer()
                Button("Save", action: saveAndDismiss)
                    .warmFont(13, weight: .semibold).foregroundStyle(Color.warmGreen)
                    .opacity(canSave ? 1 : 0.4).disabled(!canSave)
            }
            .padding(.horizontal, 20).padding(.bottom, 4)

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("+$")
                    .warmFont(32, weight: .regular, design: .serif).foregroundStyle(Color.warmGreen)
                Text(formatKeypadAmount(amountStr))
                    .warmFont(72, weight: .regular, design: .serif).foregroundStyle(Color.warmInk)
                    .monospacedDigit().minimumScaleFactor(0.4).lineLimit(1)
            }
            .padding(.top, 8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Income amount"))
            .accessibilityValue(Text("\(amountStr) dollars"))

            TextField("Source · Today", text: $description)
                .warmFont(12).foregroundStyle(Color.warmInkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16).padding(.vertical, 7)
                .background(Color.warmSurface).clipShape(Capsule())
                .overlay(Capsule().stroke(Color.warmLine, lineWidth: 1))
                .padding(.horizontal, 60).padding(.top, 12)

            HStack(spacing: 8) {
                ForEach(sources, id: \.self) { src in
                    let isOn = selectedSource == src
                    Button(action: { selectedSource = src }) {
                        Text(src)
                            .warmFont(13, weight: .semibold)
                            .foregroundStyle(isOn ? Color.warmGreenDeep : Color.warmInkSoft)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(isOn ? Color.warmGreenSoft : Color.clear)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(isOn ? Color.warmGreenSoft : Color.warmLine, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: selectedSource)
                }
            }
            .padding(.horizontal, 20).padding(.top, 20)

            // Auto-move suggestion — computed live from real goals with
            // payday auto-move enabled. YES only ARMS it; the deposit is
            // applied together with the income save (see saveAndDismiss).
            if let suggestion = autoMoveSuggestion {
                HStack(spacing: 10) {
                    Image(systemName: autoMoveArmed ? "checkmark.circle.fill" : "sparkles")
                        .warmFont(13).foregroundStyle(Color.warmGreen)
                        .frame(width: 32, height: 32).background(Color.warmSurface).cornerRadius(10)
                    Text(bannerText(for: suggestion))
                        .warmFont(12).foregroundStyle(Color.warmGreenDeep)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button(autoMoveArmed ? "UNDO" : "YES") {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            autoMoveArmed.toggle()
                        }
                    }
                    .warmFont(11, weight: .bold)
                    .foregroundStyle(autoMoveArmed ? Color.warmGreenDeep : Color.warmOnGreen)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(autoMoveArmed ? Color.warmSurface : Color.warmGreenFill)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(autoMoveArmed ? Color.warmGreen : Color.clear, lineWidth: 1))
                }
                .padding(12).background(Color.warmGreenSoft).cornerRadius(14)
                .padding(.horizontal, 20).padding(.top, 18)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.spring(response: 0.35, dampingFraction: 0.9), value: autoMoveArmed)
            }

            Spacer(minLength: 0)
            WarmKeypad(amountStr: $amountStr)
        }
        .onAppear { vm.setModelContext(modelContext) }
        .alert(isPresented: $vm.showError) {
            Alert(title: Text(Strings.Errors.errorLabel), message: Text(vm.errorMessage), dismissButton: .default(Text(Strings.Buttons.okButton)))
        }
    }

    private func bannerText(for suggestion: AutoMoveSuggestion) -> AttributedString {
        let amount = "$\(Int(suggestion.amount))"
        let origin = selectedSource == IncomeSource.paycheck.label ? "paycheck" : "income"
        let raw = autoMoveArmed
            ? "**Moving \(amount)** to \(suggestion.goal.name) when you save."
            : "**Auto-move \(amount)** to \(suggestion.goal.name) from this \(origin)?"
        return (try? AttributedString(markdown: raw)) ?? AttributedString(raw)
    }

    private func saveAndDismiss() {
        guard canSave, let amt = Double(amountStr), amt > 0 else { return }
        // Snapshot the suggestion BEFORE the income insert mutates the
        // month totals — this is exactly what the banner was showing.
        let armedSuggestion = autoMoveArmed ? autoMoveSuggestion : nil
        vm.incomeDescription = description.isEmpty ? selectedSource : description
        vm.amount = amountStr
        vm.addIncome(source: selectedSource)
        if let suggestion = armedSuggestion {
            do {
                try GoalDeposits.record(
                    goal: suggestion.goal, amount: suggestion.amount,
                    note: "Payday auto-move", source: .autoMove, context: modelContext
                )
            } catch {
                // The income itself is already saved; the move failing must
                // not lose it. Surface through the income VM's alert.
                vm.errorMessage = "Income saved, but the auto-move to \(suggestion.goal.name) failed."
                vm.showError = true
                return
            }
        }
        onSave()
    }
}

// MARK: - Quick deposit

struct WarmQuickDepositView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var goals: [GoalModel]
    let onBack: () -> Void; let onSave: () -> Void

    @State private var selectedGoal: GoalModel?
    @State private var selectedPreset: Double = 50
    @State private var errorMessage: String?
    private let presets: [Double] = [25, 50, 100, 250]

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.warmLine).frame(width: 40, height: 4)
                .padding(.top, 14).padding(.bottom, 8)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .warmFont(14, weight: .medium).foregroundStyle(Color.warmInkSoft)
                        .frame(width: 32, height: 32)
                        .tappable44()
                }
                .accessibilityLabel("Back")
                Spacer()
                Text("Move money")
                    .warmFont(18, weight: .regular, design: .serif).foregroundStyle(Color.warmInk)
                Spacer()
                Color.clear.frame(width: 32, height: 32)
            }
            .padding(.horizontal, 20).padding(.bottom, 14)

            // Compact amount + presets
            VStack(spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("$")
                        .warmFont(28, weight: .regular, design: .serif).foregroundStyle(Color.warmInkMuted)
                    Text("\(Int(selectedPreset))")
                        .warmFont(60, weight: .regular, design: .serif).foregroundStyle(Color.warmInk)
                        .monospacedDigit()
                }
                HStack(spacing: 6) {
                    ForEach(presets, id: \.self) { p in
                        let isOn = selectedPreset == p
                        Button(action: { selectedPreset = p }) {
                            Text("$\(Int(p))")
                                .warmFont(12, weight: .semibold)
                                .foregroundStyle(isOn ? Color.warmGreenDeep : Color.warmInkSoft)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(isOn ? Color.warmGreenSoft : Color.clear)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(isOn ? Color.warmGreenSoft : Color.warmLine, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.15), value: selectedPreset)
                    }
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 18)

            // Goal picker
            VStack(alignment: .leading, spacing: 8) {
                Text("TO WHICH GOAL")
                    .warmFont(11, weight: .semibold).foregroundStyle(Color.warmInkMuted).tracking(0.8)
                    .padding(.horizontal, 20)

                if goals.isEmpty {
                    Text("No goals yet — create one first.")
                        .warmFont(13).foregroundStyle(Color.warmInkMuted)
                        .padding(.horizontal, 20)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(goals.enumerated()), id: \.element.id) { i, goal in
                                let isOn = selectedGoal?.id == goal.id
                                Button(action: { selectedGoal = isOn ? nil : goal }) {
                                    HStack(spacing: 12) {
                                        RoundedRectangle(cornerRadius: 10).fill(goal.color)
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Text(goal.name.prefix(1).uppercased())
                                                    .warmFont(16, weight: .regular, design: .serif)
                                                    .foregroundStyle(Color.warmOnGreen)
                                            )
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(goal.name)
                                                .warmFont(14, weight: .semibold).foregroundStyle(Color.warmInk)
                                                .lineLimit(1)
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    RoundedRectangle(cornerRadius: 2).fill(goal.trackColor).frame(height: 4)
                                                    RoundedRectangle(cornerRadius: 2).fill(goal.color)
                                                        .frame(width: geo.size.width * goal.progress, height: 4)
                                                }
                                            }
                                            .frame(height: 4)
                                        }
                                        Spacer()
                                        ZStack {
                                            Circle().stroke(isOn ? Color.warmGreen : Color.warmLine, lineWidth: 2)
                                                .frame(width: 22, height: 22)
                                            if isOn {
                                                Circle().fill(Color.warmGreenFill).frame(width: 22, height: 22)
                                                Image(systemName: "checkmark")
                                                    .warmFont(10, weight: .bold).foregroundStyle(Color.warmOnGreen)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 14).padding(.vertical, 12)
                                    .background(isOn ? Color.warmGreenTint : Color.warmSurface)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .animation(.easeInOut(duration: 0.15), value: selectedGoal?.id)

                                if i < goals.count - 1 {
                                    Divider().padding(.horizontal, 14)
                                }
                            }
                        }
                        .background(Color.warmSurface)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.warmLine, lineWidth: 1))
                    }
                    .padding(.horizontal, 20)
                }
            }

            Spacer(minLength: 12)

            Button(action: saveDeposit) {
                let goalName = selectedGoal.map { $0.name.components(separatedBy: ",").first ?? $0.name }
                Text(goalName.map { "Add $\(Int(selectedPreset)) to \($0)" } ?? "Select a goal")
                    .warmFont(15, weight: .semibold).foregroundStyle(Color.warmOnGreen)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(selectedGoal != nil ? Color.warmGreenFill : Color.warmInkMuted)
                    .cornerRadius(14)
            }
            .disabled(selectedGoal == nil)
            .animation(.easeInOut(duration: 0.2), value: selectedGoal?.id)
            .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 28)
        }
        .onAppear {
            if selectedGoal == nil {
                selectedGoal = goals.first(where: { $0.isFavorite }) ?? goals.first
            }
        }
        .alert("Couldn't save the deposit", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func saveDeposit() {
        guard let goal = selectedGoal, selectedPreset > 0 else { return }
        do {
            try GoalDeposits.record(goal: goal, amount: selectedPreset, source: .manual, context: modelContext)
            onSave()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View { MainNavigationView() }
}
