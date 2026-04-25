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

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationStack { DashboardView() }.tag(0)
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
                }
            )
            .presentationBackground(Color.warmBg)
            .presentationCornerRadius(28)
            .presentationDetents(quickScreen == .actionSheet ? [.height(540)] : [.large])
            .presentationDragIndicator(.hidden)
        }
        .fullScreenCover(isPresented: $showAddGoalFlow) {
            AddGoalFlowView(isPresented: $showAddGoalFlow)
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
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(isExpanded ? Color.warmGreen : Color.warmInk)
                    .cornerRadius(18)
                    .shadow(
                        color: (isExpanded ? Color.warmGreen : .black).opacity(isExpanded ? 0.38 : 0.18),
                        radius: 10, x: 0, y: 4
                    )
                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
            }
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
                    .font(.system(size: 22, weight: isActive ? .semibold : .regular))
                Text(label)
                    .font(.system(size: 10, weight: isActive ? .semibold : .medium))
            }
            .foregroundStyle(isActive ? Color.warmGreen : Color.warmInkMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick-add container

struct WarmQuickAddContainer: View {
    @Binding var screen: QuickAddScreen
    let onDismiss: () -> Void
    let onNewGoal: () -> Void

    var body: some View {
        Group {
            switch screen {
            case .actionSheet:
                WarmActionSheet(
                    onSelect: { s in withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) { screen = s } },
                    onDismiss: onDismiss,
                    onNewGoal: onNewGoal
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
    let icon: String; let label: String; let sub: String
    let bg: Color; let fg: Color; let target: QuickAddScreen?; let isNewGoal: Bool
}

private let quickActions: [QuickAction] = [
    QuickAction(icon: "wallet.pass",  label: "Log expense",       sub: "Coffee, groceries, anything",  bg: .warmAmberSoft, fg: .warmAmber, target: .expense,  isNewGoal: false),
    QuickAction(icon: "arrow.up",     label: "Log income",        sub: "Paycheck, gift, side work",    bg: .warmGreenSoft, fg: .warmGreen, target: .income,   isNewGoal: false),
    QuickAction(icon: "target",       label: "Deposit to a goal", sub: "Move money toward a goal",     bg: .warmSkySoft,   fg: .warmSky,   target: .deposit,  isNewGoal: false),
    QuickAction(icon: "camera",       label: "Scan a receipt",    sub: "We'll read the total",          bg: .warmClaySoft,  fg: .warmClay,  target: .expense,  isNewGoal: false),
    QuickAction(icon: "plus",         label: "New goal",          sub: "Start something new",
                bg: Color(red: 0.925, green: 0.910, blue: 0.957),
                fg: Color(red: 0.490, green: 0.416, blue: 0.722), target: nil, isNewGoal: true),
]

struct WarmActionSheet: View {
    let onSelect: (QuickAddScreen) -> Void
    let onDismiss: () -> Void
    let onNewGoal: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.warmLine).frame(width: 40, height: 4)
                .padding(.top, 14).padding(.bottom, 12)

            HStack(alignment: .center) {
                Text("What's the move?")
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .foregroundStyle(Color.warmInk)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.warmInkSoft)
                        .frame(width: 32, height: 32)
                        .background(Color.warmSurface)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.warmLine, lineWidth: 1))
                }
            }
            .padding(.horizontal, 20)

            Text("Pick what to log right now.")
                .font(.system(size: 13)).foregroundStyle(Color.warmInkMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20).padding(.top, 2).padding(.bottom, 18)

            VStack(spacing: 0) {
                ForEach(Array(quickActions.enumerated()), id: \.offset) { i, action in
                    Button(action: {
                        if action.isNewGoal { onNewGoal() }
                        else if let t = action.target { onSelect(t) }
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: action.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(action.fg)
                                .frame(width: 40, height: 40)
                                .background(action.bg)
                                .cornerRadius(12)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(action.label)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color.warmInk)
                                Text(action.sub)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.warmInkMuted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .medium))
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

            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11)).foregroundStyle(Color.warmAmber)
                (Text("Tip: long-press ") +
                 Text("+").fontWeight(.bold).foregroundColor(Color.warmInk) +
                 Text(" to repeat your last action."))
                    .font(.system(size: 12)).foregroundStyle(Color.warmInkMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(Color.warmLine)
            )
            .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 28)
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
                                    .font(.system(size: 20, weight: .light))
                            } else {
                                Text(key)
                                    .font(.system(size: 24, weight: .regular, design: .serif))
                            }
                        }
                        .foregroundStyle(Color.warmInk)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.warmSurface)
        }
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

private let expenseCats: [(label: String, bg: Color, fg: Color)] = [
    ("Coffee",   .warmAmberSoft, .warmAmber),
    ("Food",     .warmGreenSoft, .warmGreen),
    ("Transit",  .warmSkySoft,   .warmSky),
    ("Shopping", .warmClaySoft,  .warmClay),
    ("Other",    .warmBg,        .warmInkSoft),
]

struct WarmQuickExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    let onBack: () -> Void; let onSave: () -> Void

    @State private var amountStr = "0"
    @State private var description = ""
    @State private var selectedCat = "Coffee"
    @StateObject private var vm = ExpenseTrackerViewModel()

    private var canSave: Bool { amountStr != "0" }

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.warmLine).frame(width: 40, height: 4)
                .padding(.top, 14).padding(.bottom, 8)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium)).foregroundStyle(Color.warmInkSoft)
                        .frame(width: 32, height: 32)
                }
                Spacer()
                Text("Log expense")
                    .font(.system(size: 18, weight: .regular, design: .serif)).foregroundStyle(Color.warmInk)
                Spacer()
                Button("Save", action: saveAndDismiss)
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.warmGreen)
                    .opacity(canSave ? 1 : 0.4).disabled(!canSave)
            }
            .padding(.horizontal, 20).padding(.bottom, 4)

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("−$")
                    .font(.system(size: 32, weight: .regular, design: .serif)).foregroundStyle(Color.warmInkMuted)
                Text(formatKeypadAmount(amountStr))
                    .font(.system(size: 72, weight: .regular, design: .serif)).foregroundStyle(Color.warmInk)
                    .monospacedDigit().minimumScaleFactor(0.4).lineLimit(1)
            }
            .padding(.top, 8)

            TextField("Merchant · Today", text: $description)
                .font(.system(size: 12)).foregroundStyle(Color.warmInkSoft)
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
                                .font(.system(size: 13, weight: .semibold))
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
    }

    private func saveAndDismiss() {
        guard canSave, let amt = Double(amountStr), amt > 0 else { return }
        vm.expenseDescription = description.isEmpty ? selectedCat : description
        vm.amount = amountStr; vm.addExpense(); onSave()
    }
}

// MARK: - Quick income

struct WarmQuickIncomeView: View {
    @Environment(\.modelContext) private var modelContext
    let onBack: () -> Void; let onSave: () -> Void

    @State private var amountStr = "0"
    @State private var description = ""
    @State private var selectedSource = "Paycheck"
    @StateObject private var vm = IncomesTrackerViewModel()

    private let sources = ["Paycheck", "Freelance", "Gift", "Other"]
    private var canSave: Bool { amountStr != "0" }

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.warmLine).frame(width: 40, height: 4)
                .padding(.top, 14).padding(.bottom, 8)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium)).foregroundStyle(Color.warmInkSoft)
                        .frame(width: 32, height: 32)
                }
                Spacer()
                Text("Log income")
                    .font(.system(size: 18, weight: .regular, design: .serif)).foregroundStyle(Color.warmInk)
                Spacer()
                Button("Save", action: saveAndDismiss)
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.warmGreen)
                    .opacity(canSave ? 1 : 0.4).disabled(!canSave)
            }
            .padding(.horizontal, 20).padding(.bottom, 4)

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("+$")
                    .font(.system(size: 32, weight: .regular, design: .serif)).foregroundStyle(Color.warmGreen)
                Text(formatKeypadAmount(amountStr))
                    .font(.system(size: 72, weight: .regular, design: .serif)).foregroundStyle(Color.warmInk)
                    .monospacedDigit().minimumScaleFactor(0.4).lineLimit(1)
            }
            .padding(.top, 8)

            TextField("Source · Today", text: $description)
                .font(.system(size: 12)).foregroundStyle(Color.warmInkSoft)
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
                            .font(.system(size: 13, weight: .semibold))
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

            // Auto-move hint banner
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13)).foregroundStyle(Color.warmGreen)
                    .frame(width: 32, height: 32).background(Color.warmSurface).cornerRadius(10)
                Text("**Auto-move $230** to Kyoto from this paycheck?")
                    .font(.system(size: 12)).foregroundStyle(Color.warmGreenDeep)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("YES") {}
                    .font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.warmGreen).clipShape(Capsule())
            }
            .padding(12).background(Color.warmGreenSoft).cornerRadius(14)
            .padding(.horizontal, 20).padding(.top, 18)

            Spacer(minLength: 0)
            WarmKeypad(amountStr: $amountStr)
        }
        .onAppear { vm.setModelContext(modelContext) }
    }

    private func saveAndDismiss() {
        guard canSave, let amt = Double(amountStr), amt > 0 else { return }
        vm.incomeDescription = description.isEmpty ? selectedSource : description
        vm.amount = amountStr; vm.addIncome(); onSave()
    }
}

// MARK: - Quick deposit

struct WarmQuickDepositView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var goals: [GoalModel]
    let onBack: () -> Void; let onSave: () -> Void

    @State private var selectedGoal: GoalModel?
    @State private var selectedPreset: Double = 50
    private let presets: [Double] = [25, 50, 100, 250]

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.warmLine).frame(width: 40, height: 4)
                .padding(.top, 14).padding(.bottom, 8)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium)).foregroundStyle(Color.warmInkSoft)
                        .frame(width: 32, height: 32)
                }
                Spacer()
                Text("Move money")
                    .font(.system(size: 18, weight: .regular, design: .serif)).foregroundStyle(Color.warmInk)
                Spacer()
                Color.clear.frame(width: 32, height: 32)
            }
            .padding(.horizontal, 20).padding(.bottom, 14)

            // Compact amount + presets
            VStack(spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("$")
                        .font(.system(size: 28, weight: .regular, design: .serif)).foregroundStyle(Color.warmInkMuted)
                    Text("\(Int(selectedPreset))")
                        .font(.system(size: 60, weight: .regular, design: .serif)).foregroundStyle(Color.warmInk)
                        .monospacedDigit()
                }
                HStack(spacing: 6) {
                    ForEach(presets, id: \.self) { p in
                        let isOn = selectedPreset == p
                        Button(action: { selectedPreset = p }) {
                            Text("$\(Int(p))")
                                .font(.system(size: 12, weight: .semibold))
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
                    .font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.warmInkMuted).tracking(0.8)
                    .padding(.horizontal, 20)

                if goals.isEmpty {
                    Text("No goals yet — create one first.")
                        .font(.system(size: 13)).foregroundStyle(Color.warmInkMuted)
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
                                                    .font(.system(size: 16, weight: .regular, design: .serif))
                                                    .foregroundStyle(.white)
                                            )
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(goal.name)
                                                .font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.warmInk)
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
                                                Circle().fill(Color.warmGreen).frame(width: 22, height: 22)
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
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
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(selectedGoal != nil ? Color.warmGreen : Color.warmInkMuted)
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
    }

    private func saveDeposit() {
        guard let goal = selectedGoal, selectedPreset > 0 else { return }
        goal.current = min(goal.current + selectedPreset, goal.target)
        try? modelContext.save()
        onSave()
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View { MainNavigationView() }
}
