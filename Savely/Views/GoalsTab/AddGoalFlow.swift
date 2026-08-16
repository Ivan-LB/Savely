import SwiftUI
import SwiftData

// MARK: - Add Goal state carried through all steps

final class AddGoalState: ObservableObject {
    @Published var name: String = ""
    @Published var color: GoalColor = .green
    @Published var amountStr: String = "0"
    /// The calendar always holds a date so MiniCalendarView's binding stays
    /// non-optional; `hasDeadline` says whether it counts. "No date" flips it
    /// off; picking any day or duration flips it back on.
    @Published var deadline: Date = Calendar.current.date(byAdding: .month, value: 18, to: Date()) ?? Date()
    @Published var hasDeadline: Bool = true
    @Published var autoDeposit: Bool = true
    @Published var isFavorite: Bool = false

    var amount: Double { Double(amountStr) ?? 0 }

    /// Required pace to the chosen date; 0 without a date (pace is undefined
    /// then — the user sets an auto-move amount later in the edit sheet).
    var weeklyPace: Double {
        guard hasDeadline else { return 0 }
        return GoalPace.requiredWeeklyPace(remaining: amount, deadline: deadline, now: Date()) ?? 0
    }

    var monthlyPace: Double { weeklyPace * GoalPace.weeksPerMonth }

    var canPlant: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && amount > 0 }
}

// MARK: - Flow container

struct AddGoalFlowView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    @StateObject private var state = AddGoalState()
    @State private var step = 1
    @State private var showSuccess = false
    @State private var plantedGoal: GoalModel?
    @State private var showDeposit = false
    @State private var saveError: String?

    var body: some View {
        if showSuccess {
            AddGoalSuccessView(
                state: state,
                onDeposit: { showDeposit = true },
                onHome: { isPresented = false }
            )
            .sheet(isPresented: $showDeposit, onDismiss: { isPresented = false }) {
                if let goal = plantedGoal {
                    DepositSheet(goal: goal, modelContext: modelContext)
                }
            }
        } else {
            Group {
                switch step {
                case 1: AddGoalStep1View(state: state, onNext: { step = 2 }, onClose: { isPresented = false })
                case 2: AddGoalStep2View(state: state, onBack: { step = 1 }, onNext: { step = 3 }, onSkip: { step = 3 })
                case 3: AddGoalStep3View(state: state, onBack: { step = 2 }, onNext: { step = 4 }, onSkip: { step = 4 })
                default: AddGoalStep4View(state: state, onBack: { step = 3 }, onPlant: {
                    plantGoal()
                })
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: step)
            .alert("Couldn't save the goal", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    private func plantGoal() {
        guard state.canPlant else { return } // the button is disabled before this; belt and braces
        let goal = GoalModel(
            name: state.name.trimmingCharacters(in: .whitespaces),
            current: 0,
            target: state.amount,
            color: state.color,
            isFavorite: state.isFavorite,
            autoMoveEnabled: state.autoDeposit,
            autoMoveAmount: state.hasDeadline ? state.monthlyPace.rounded() : 0,
            deadline: state.hasDeadline ? state.deadline : nil
        )
        modelContext.insert(goal)
        do {
            try modelContext.save()
            plantedGoal = goal
            withAnimation(.easeInOut(duration: 0.4)) { showSuccess = true }
        } catch {
            modelContext.delete(goal)
            saveError = "Please try again."
        }
    }
}

// MARK: - Shared header

struct AddGoalHeader: View {
    let step: Int; let total: Int
    let onBack: () -> Void; let onSkip: () -> Void
    var showClose: Bool = false
    var showSkip: Bool = true
    // Concatenated Text needs a Font value, so scale it here instead of via warmFont.
    @ScaledMetric(relativeTo: .subheadline) private var headerSize: CGFloat = 13

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Button(action: onBack) {
                    Image(systemName: showClose ? "xmark" : "chevron.left")
                        .warmFont(14, weight: .medium)
                        .foregroundStyle(Color.warmInk)
                        .frame(width: 36, height: 36)
                        .background(Color.warmSurface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.warmLine, lineWidth: 1))
                        .tappable44()
                }
                .accessibilityLabel(showClose ? "Close" : "Back")
                Spacer()
                Text("New goal · ")
                    .font(.system(size: headerSize))
                    .foregroundStyle(Color.warmInkMuted)
                + Text("\(step)").font(.system(size: headerSize, weight: .semibold)).foregroundColor(Color.warmInk)
                + Text(" of \(total)").font(.system(size: headerSize)).foregroundColor(Color.warmInkMuted)
                Spacer()
                if showSkip {
                    Button(action: onSkip) {
                        Text("Skip")
                            .warmFont(13)
                            .foregroundStyle(Color.warmInkMuted)
                            .frame(width: 36, height: 36)
                    }
                } else {
                    Color.clear.frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            HStack(spacing: 4) {
                ForEach(1...total, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i <= step ? Color.warmGreen : Color.warmLine)
                        .frame(height: 3)
                        .animation(.easeInOut(duration: 0.25), value: step)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Step 1: Intent — name, color


struct AddGoalStep1View: View {
    @ObservedObject var state: AddGoalState
    let onNext: () -> Void; let onClose: () -> Void
    @FocusState private var nameFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                AddGoalHeader(step: 1, total: 4, onBack: onClose, onSkip: onNext, showClose: true)

                // Section label + headline
                VStack(alignment: .leading, spacing: 10) {
                    Text("WHAT YOU'RE SAVING FOR")
                        .warmFont(11, weight: .bold).foregroundStyle(Color.warmGreen).tracking(1.2)
                    Text("Give it a name\nyou'll recognize.")
                        .warmFont(32, weight: .regular, design: .serif).foregroundStyle(Color.warmInk)
                        .lineSpacing(2)
                    Text("This is what you'll see on your dashboard.")
                        .warmFont(14).foregroundStyle(Color.warmInkSoft)
                }
                .padding(.horizontal, 24).padding(.bottom, 24)

                // Live preview chip
                HStack {
                    Spacer()
                    HStack(spacing: 12) {
                        GoalInitialCircle(name: state.name, color: state.color, size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(state.name.isEmpty ? "Your goal name" : state.name)
                                .warmFont(20, weight: .regular, design: .serif)
                                .foregroundStyle(state.name.isEmpty ? Color.warmInkMuted : Color.warmInk)
                            Text("Live preview")
                                .warmFont(11).foregroundStyle(Color.warmInkMuted)
                        }
                    }
                    .padding(.vertical, 12).padding(.horizontal, 18)
                    .background(Color.warmSurface)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.warmLine, lineWidth: 1))
                    Spacer()
                }
                .padding(.bottom, 20)

                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("NAME")
                        .warmFont(11, weight: .semibold).foregroundStyle(Color.warmInkMuted).tracking(0.8)
                    HStack {
                        TextField("e.g. Kyoto, autumn '26", text: $state.name)
                            .warmFont(16).foregroundStyle(Color.warmInk)
                            .focused($nameFocused)
                        if !state.name.isEmpty {
                            Button(action: { state.name = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .warmFont(16).foregroundStyle(Color.warmInkMuted)
                                    .tappable44()
                            }
                            .accessibilityLabel("Clear name")
                        }
                    }
                    .padding(14)
                    .background(Color.warmSurface)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(nameFocused ? Color.warmGreen : Color.warmLine, lineWidth: nameFocused ? 1.5 : 1)
                    )
                    Text("Tip: be specific. Try a specific name like Kyoto trip '26.")
                        .warmFont(12).foregroundStyle(Color.warmInkMuted).padding(.leading, 4)
                }
                .padding(.horizontal, 20).padding(.bottom, 24)

                // Color picker (6-swatch row from design)
                VStack(alignment: .leading, spacing: 10) {
                    Text("COLOR")
                        .warmFont(11, weight: .semibold).foregroundStyle(Color.warmInkMuted).tracking(0.8)
                    HStack(spacing: 12) {
                        ForEach([GoalColor.green, .blue, .yellow, .red, .purple, .brown], id: \.id) { gc in
                            let isOn = state.color == gc
                            Button(action: { state.color = gc }) {
                                Circle()
                                    .fill(gc.color)
                                    .frame(width: 38, height: 38)
                                    .overlay(
                                        Circle().stroke(Color.warmSurface, lineWidth: isOn ? 3 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.15), value: state.color)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 32)

                Button(action: onNext) {
                    Text("Continue")
                        .warmFont(15, weight: .semibold).foregroundStyle(Color.warmOnGreen)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(state.name.isEmpty ? Color.warmInkMuted : Color.warmGreenFill)
                        .cornerRadius(14)
                }
                .disabled(state.name.isEmpty)
                .padding(.horizontal, 20).padding(.bottom, 32)
            }
        }
        .background(Color.warmBg.ignoresSafeArea())
        .onAppear { nameFocused = true }
    }
}

// MARK: - Step 2: Amount

struct AddGoalStep2View: View {
    @ObservedObject var state: AddGoalState
    let onBack: () -> Void; let onNext: () -> Void; let onSkip: () -> Void
    @ScaledMetric(relativeTo: .footnote) private var noteSize: CGFloat = 12
    private let presets: [Double] = [1000, 2500, 5000, 10000]

    var body: some View {
        VStack(spacing: 0) {
            AddGoalHeader(step: 2, total: 4, onBack: onBack, onSkip: onSkip)

            VStack(alignment: .leading, spacing: 10) {
                Text("HOW MUCH")
                    .warmFont(11, weight: .bold).foregroundStyle(Color.warmGreen).tracking(1.2)
                Text("What's the\nfinish line?")
                    .warmFont(32, weight: .regular, design: .serif).foregroundStyle(Color.warmInk)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24).padding(.bottom, 8)

            // Goal name chip
            HStack(spacing: 10) {
                GoalInitialCircle(name: state.name, color: state.color, size: 28)
                Text(state.name)
                    .warmFont(13).foregroundStyle(Color.warmInkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24).padding(.bottom, 8)

            Spacer(minLength: 0)

            // Large amount display
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("$")
                    .warmFont(36, weight: .regular, design: .serif).foregroundStyle(Color.warmInkMuted)
                Text(formatKeypadAmount(state.amountStr))
                    .warmFont(88, weight: .regular, design: .serif).foregroundStyle(Color.warmInk)
                    .monospacedDigit().minimumScaleFactor(0.35).lineLimit(1)
            }
            .padding(.horizontal, 20)

            // Pace whisper
            if state.amount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .warmFont(11).foregroundStyle(Color.warmAmber)
                    Text("About ")
                        .font(.system(size: noteSize)).foregroundStyle(Color.warmInkMuted)
                    + Text("$\(Int(state.weeklyPace))/week")
                        .font(.system(size: noteSize, weight: .semibold)).foregroundColor(Color.warmInk)
                    + Text(" for 18 months")
                        .font(.system(size: noteSize)).foregroundColor(Color.warmInkMuted)
                }
                .padding(.top, 14)
            }

            // Preset chips
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { p in
                    let isOn = state.amountStr == "\(Int(p))"
                    Button(action: { state.amountStr = "\(Int(p))" }) {
                        Text("$\(Int(p).formatted())")
                            .warmFont(13, weight: .semibold)
                            .foregroundStyle(isOn ? Color.warmGreenDeep : Color.warmInkSoft)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(isOn ? Color.warmGreenSoft : Color.clear)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(isOn ? Color.warmGreenSoft : Color.warmLine, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: state.amountStr)
                }
            }
            .padding(.top, 22).padding(.horizontal, 20)

            Spacer(minLength: 0)

            // Keypad + continue
            VStack(spacing: 10) {
                WarmKeypad(amountStr: $state.amountStr)
                Button(action: onNext) {
                    Text("Continue")
                        .warmFont(15, weight: .semibold).foregroundStyle(Color.warmOnGreen)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(state.amount > 0 ? Color.warmGreenFill : Color.warmInkMuted)
                        .cornerRadius(14)
                }
                .disabled(state.amount <= 0)
                .padding(.horizontal, 14).padding(.bottom, 14)
            }
        }
        .background(Color.warmBg.ignoresSafeArea())
    }
}

// MARK: - Step 3: Deadline + pace

private let durationPresets: [(label: String, months: Int?)] = [
    ("6 mo", 6), ("1 yr", 12), ("18 mo", 18), ("2 yr", 24), ("No date", nil)
]

struct AddGoalStep3View: View {
    @ObservedObject var state: AddGoalState
    let onBack: () -> Void; let onNext: () -> Void; let onSkip: () -> Void

    @State private var selectedDuration = 18
    @State private var displayMonth: Date = {
        var c = Calendar.current; var comps = c.dateComponents([.year, .month], from: Date())
        comps.month = (comps.month ?? 1) + 18; return c.date(from: comps) ?? Date()
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                AddGoalHeader(step: 3, total: 4, onBack: onBack, onSkip: onSkip)

                VStack(alignment: .leading, spacing: 10) {
                    Text("TIMING")
                        .warmFont(11, weight: .bold).foregroundStyle(Color.warmGreen).tracking(1.2)
                    Text("When do you\nwant this by?")
                        .warmFont(32, weight: .regular, design: .serif).foregroundStyle(Color.warmInk)
                }
                .padding(.horizontal, 24).padding(.bottom, 20)

                // Green pace card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .warmFont(11, weight: .bold).foregroundStyle(Color.warmOnGreen.opacity(0.85))
                        Text("SUGGESTED PACE")
                            .warmFont(11, weight: .bold).foregroundStyle(Color.warmOnGreen.opacity(0.85)).tracking(1.2)
                    }
                    HStack(alignment: .firstTextBaseline) {
                        Text(state.hasDeadline ? "$\(Int(state.weeklyPace))" : "—")
                            .warmFont(38, weight: .regular, design: .serif).foregroundStyle(Color.warmOnGreen)
                        Text("/wk")
                            .warmFont(18).foregroundStyle(Color.warmOnGreen.opacity(0.7)).padding(.leading, 2)
                        Spacer()
                        Text(state.hasDeadline ? "~$\(Int(state.monthlyPace))/mo" : "no date")
                            .warmFont(13).foregroundStyle(Color.warmOnGreen.opacity(0.85))
                    }
                    Text(state.hasDeadline
                         ? "To hit **$\(Int(state.amount))** by **\(formattedDeadline)**."
                         : "No target date — save at your own pace.")
                        .warmFont(13).foregroundStyle(Color.warmOnGreen.opacity(0.85))
                }
                .padding(18)
                .background(Color.warmGreenFill)
                .cornerRadius(22)
                .padding(.horizontal, 20).padding(.bottom, 16)

                // Mini calendar — picking a day turns the date back on
                MiniCalendarView(displayMonth: $displayMonth, selectedDate: $state.deadline)
                    .opacity(state.hasDeadline ? 1 : 0.45)
                    .onChange(of: state.deadline) { state.hasDeadline = true; selectedDuration = -2 }
                    .padding(.horizontal, 20).padding(.bottom, 14)

                // Duration presets
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(durationPresets, id: \.label) { preset in
                            let isOn = (preset.months ?? -1) == selectedDuration
                            Button(action: {
                                if let m = preset.months {
                                    selectedDuration = m
                                    state.hasDeadline = true
                                    state.deadline = Calendar.current.date(byAdding: .month, value: m, to: Date()) ?? Date()
                                    displayMonth = state.deadline
                                } else {
                                    selectedDuration = -1
                                    state.hasDeadline = false
                                }
                            }) {
                                Text(preset.label)
                                    .warmFont(13, weight: .semibold)
                                    .foregroundStyle(isOn ? Color.warmGreenDeep : Color.warmInkSoft)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(isOn ? Color.warmGreenSoft : Color.clear)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(isOn ? Color.warmGreenSoft : Color.warmLine, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.15), value: selectedDuration)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 14)

                // Auto-deposit toggle
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .warmFont(15).foregroundStyle(Color.warmGreen)
                        .frame(width: 36, height: 36).background(Color.warmGreenSoft).cornerRadius(10)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-move on payday")
                            .warmFont(14, weight: .semibold).foregroundStyle(Color.warmInk)
                        Text(state.hasDeadline
                             ? "Set $\(Int(state.monthlyPace)) aside the day after each paycheck."
                             : "Pick the amount later in the goal's settings.")
                            .warmFont(12).foregroundStyle(Color.warmInkMuted)
                    }
                    Spacer()
                    Toggle("Auto-move on payday", isOn: $state.autoDeposit)
                        .labelsHidden()
                        .tint(Color.warmGreen)
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(Color.warmSurface)
                .cornerRadius(18)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.warmLine, lineWidth: 1))
                .padding(.horizontal, 20).padding(.bottom, 32)

                Button(action: onNext) {
                    Text("Continue")
                        .warmFont(15, weight: .semibold).foregroundStyle(Color.warmOnGreen)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Color.warmGreenFill).cornerRadius(14)
                }
                .padding(.horizontal, 20).padding(.bottom, 32)
            }
        }
        .background(Color.warmBg.ignoresSafeArea())
    }

    private var formattedDeadline: String {
        guard state.hasDeadline else { return "—" }
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"
        return f.string(from: state.deadline)
    }
}

// MARK: - Mini calendar

struct MiniCalendarView: View {
    @Binding var displayMonth: Date
    @Binding var selectedDate: Date
    private let dayLabels = ["S","M","T","W","T","F","S"]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: shiftMonth(-1)) {
                    Image(systemName: "chevron.left").warmFont(13).foregroundStyle(Color.warmInkSoft)
                        .frame(width: 28, height: 28).cornerRadius(8)
                        .tappable44()
                }
                .accessibilityLabel("Previous month")
                Spacer()
                Text(monthTitle).warmFont(18, weight: .regular, design: .serif).foregroundStyle(Color.warmInk)
                Spacer()
                Button(action: shiftMonth(1)) {
                    Image(systemName: "chevron.right").warmFont(13).foregroundStyle(Color.warmInkSoft)
                        .frame(width: 28, height: 28).cornerRadius(8)
                        .tappable44()
                }
                .accessibilityLabel("Next month")
            }
            .padding(.bottom, 14)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(dayLabels, id: \.self) { d in
                    Text(d).warmFont(10, weight: .semibold).foregroundStyle(Color.warmInkMuted)
                }
                ForEach(0..<leadingBlanks, id: \.self) { _ in Color.clear.frame(height: 32) }
                ForEach(1...daysInMonth, id: \.self) { day in
                    let isSelected = isSelectedDay(day)
                    Button(action: { selectDay(day) }) {
                        Text("\(day)")
                            .warmFont(13, weight: isSelected ? .semibold : .regular)
                            .foregroundStyle(isSelected ? Color.warmOnGreen : Color.warmInk)
                            .frame(maxWidth: .infinity).frame(height: 32)
                            .background(isSelected ? Color.warmGreenFill : Color.clear)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .background(Color.warmSurface)
        .cornerRadius(22)
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.warmLine, lineWidth: 1))
    }

    private var monthTitle: String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f.string(from: displayMonth)
    }
    private var leadingBlanks: Int {
        Calendar.current.component(.weekday, from: firstOfMonth) - 1
    }
    private var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: displayMonth)?.count ?? 30
    }
    private var firstOfMonth: Date {
        let c = Calendar.current
        return c.date(from: c.dateComponents([.year, .month], from: displayMonth)) ?? displayMonth
    }
    private func isSelectedDay(_ day: Int) -> Bool {
        let c = Calendar.current
        return c.component(.day, from: selectedDate) == day &&
               c.component(.month, from: selectedDate) == c.component(.month, from: displayMonth) &&
               c.component(.year, from: selectedDate) == c.component(.year, from: displayMonth)
    }
    private func selectDay(_ day: Int) {
        var comps = Calendar.current.dateComponents([.year, .month], from: displayMonth)
        comps.day = day
        if let d = Calendar.current.date(from: comps) { selectedDate = d }
    }
    private func shiftMonth(_ delta: Int) -> () -> Void {
        { displayMonth = Calendar.current.date(byAdding: .month, value: delta, to: displayMonth) ?? displayMonth }
    }
}

// MARK: - Step 4: Review

struct AddGoalStep4View: View {
    @ObservedObject var state: AddGoalState
    let onBack: () -> Void; let onPlant: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                AddGoalHeader(step: 4, total: 4, onBack: onBack, onSkip: {}, showSkip: false)

                VStack(alignment: .leading, spacing: 10) {
                    Text("ALMOST THERE")
                        .warmFont(11, weight: .bold).foregroundStyle(Color.warmGreen).tracking(1.2)
                    Text("Take a look\nbefore we start.")
                        .warmFont(32, weight: .regular, design: .serif).foregroundStyle(Color.warmInk)
                }
                .padding(.horizontal, 24).padding(.bottom, 24)

                // Hero preview card
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        GoalInitialCircle(name: state.name, color: state.color, size: 44)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(state.name)
                                .warmFont(22, weight: .regular, design: .serif).foregroundStyle(Color.warmInk)
                            Text("Goal · \(formattedDeadline)")
                                .warmFont(12).foregroundStyle(Color.warmInkMuted)
                        }
                        Spacer()
                        Text("New")
                            .warmFont(11, weight: .semibold).foregroundStyle(Color.warmGreenDeep)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color.warmGreenSoft).clipShape(Capsule())
                    }
                    .padding(.bottom, 16)

                    HStack(alignment: .firstTextBaseline) {
                        Text("$0")
                            .warmFont(32, weight: .regular, design: .serif).foregroundStyle(Color.warmInk)
                        Spacer()
                        Text("of $\(Int(state.amount))")
                            .warmFont(13).foregroundStyle(Color.warmInkMuted)
                    }
                    .padding(.bottom, 8)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.warmLine).frame(height: 8)
                            RoundedRectangle(cornerRadius: 4).fill(state.color.color)
                                .frame(width: geo.size.width * 0.01, height: 8)
                        }
                    }
                    .frame(height: 8).padding(.bottom, 14)

                    HStack(spacing: 6) {
                        ForEach([("Per week", state.hasDeadline ? "$\(Int(state.weeklyPace))" : "—"),
                                 ("Per month", state.hasDeadline ? "$\(Int(state.monthlyPace))" : "—"),
                                 ("By", shortDeadline)], id: \.0) { item in
                            VStack(spacing: 4) {
                                Text(item.0)
                                    .warmFont(9).foregroundStyle(Color.warmInkMuted).textCase(.uppercase).tracking(0.8)
                                Text(item.1)
                                    .warmFont(16, weight: .regular, design: .serif).foregroundStyle(Color.warmInk)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Color.warmBg).cornerRadius(12)
                        }
                    }
                }
                .padding(22)
                .background(Color.warmSurface)
                .cornerRadius(24)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.warmLine, lineWidth: 1))
                .shadow(color: Color.warmShadow, radius: 16, y: 6)
                .padding(.horizontal, 20).padding(.bottom, 20)

                // Recap toggles
                VStack(spacing: 0) {
                    RecapToggleRow(label: "Auto-move", sub: state.hasDeadline ? "On — $\(Int(state.monthlyPace)) each payday" : "On — amount set later", isOn: $state.autoDeposit)
                    Divider().padding(.horizontal, 16)
                    RecapToggleRow(label: "Favorite", sub: "Show on home screen", isOn: $state.isFavorite)
                }
                .background(Color.warmSurface)
                .cornerRadius(18)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.warmLine, lineWidth: 1))
                .padding(.horizontal, 20).padding(.bottom, 16)

                // Encouragement strip
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles")
                        .warmFont(13).foregroundStyle(Color.warmAmber)
                    Text("That's **about one less takeout per week**. Doable.")
                        .warmFont(12).foregroundStyle(Color.warmAmberDeep)
                }
                .padding(16)
                .background(Color.warmAmberSoft)
                .cornerRadius(14)
                .padding(.horizontal, 20).padding(.bottom, 24)

                // CTA
                VStack(spacing: 0) {
                    Button(action: onPlant) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .warmFont(14, weight: .semibold)
                            Text("Plant goal")
                                .warmFont(15, weight: .semibold)
                        }
                        .foregroundStyle(Color.warmOnGreen)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Color.warmGreenFill).cornerRadius(14)
                    }
                    .disabled(!state.canPlant)
                    .opacity(state.canPlant ? 1 : 0.4)
                    Button(action: onBack) {
                        Text("Edit anything")
                            .warmFont(13).foregroundStyle(Color.warmInkMuted)
                            .padding(.vertical, 14)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 32)
            }
        }
        .background(Color.warmBg.ignoresSafeArea())
    }

    private var formattedDeadline: String {
        guard state.hasDeadline else { return "No date" }
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"; return f.string(from: state.deadline)
    }
    private var shortDeadline: String {
        guard state.hasDeadline else { return "—" }
        let f = DateFormatter(); f.dateFormat = "MMM ''yy"; return f.string(from: state.deadline)
    }
}

struct RecapToggleRow: View {
    let label: String; let sub: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).warmFont(14, weight: .semibold).foregroundStyle(Color.warmInk)
                Text(sub).warmFont(12).foregroundStyle(Color.warmInkMuted)
            }
            Spacer()
            Toggle(label, isOn: $isOn).labelsHidden().tint(Color.warmGreen)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

// MARK: - Success screen

struct AddGoalSuccessView: View {
    let state: AddGoalState
    let onDeposit: () -> Void; let onHome: () -> Void

    private let dots: [(CGFloat, CGFloat, CGFloat, Bool)] = [
        (0.12, 0.18, 8,  false), (0.82, 0.14, 12, true),
        (0.22, 0.76, 6,  false), (0.78, 0.72, 10, true),
        (0.50, 0.10, 5,  false), (0.88, 0.40, 7,  false),
        (0.10, 0.50, 9,  true),  (0.58, 0.84, 6,  false),
    ]

    var body: some View {
        ZStack {
            Color.warmGreenFill.ignoresSafeArea()

            GeometryReader { geo in
                ForEach(Array(dots.enumerated()), id: \.offset) { _, dot in
                    Circle()
                        .fill(dot.3 ? Color.warmAmber : Color.warmOnGreen)
                        .frame(width: dot.2, height: dot.2)
                        .opacity(0.5)
                        .position(x: geo.size.width * dot.0, y: geo.size.height * dot.1)
                }
            }

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle().fill(Color.warmOnGreen.opacity(0.14)).frame(width: 132, height: 132)
                    Circle().fill(Color.warmOnGreen).frame(width: 88, height: 88)
                        .overlay(
                            Image(systemName: "checkmark")
                                .warmFont(36, weight: .semibold)
                                .foregroundStyle(Color.warmGreenFill)
                        )
                }
                .padding(.bottom, 28)

                Text("Planted.")
                    .warmFont(42, weight: .regular, design: .serif)
                    .foregroundStyle(Color.warmOnGreen)
                    .padding(.bottom, 12)

                Text("\(state.name) is on your home screen.\nAdd the first dollar?")
                    .warmFont(15)
                    .foregroundStyle(Color.warmOnGreen.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)

                Spacer()

                VStack(spacing: 10) {
                    Button(action: onDeposit) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus").warmFont(14, weight: .semibold)
                            Text("Add a deposit").warmFont(15, weight: .semibold)
                        }
                        .foregroundStyle(Color.warmGreenFill)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(Color.warmOnGreen).cornerRadius(14)
                    }
                    Button(action: onHome) {
                        Text("Back to home")
                            .warmFont(15, weight: .medium).foregroundStyle(Color.warmOnGreen)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(Color.warmOnGreen.opacity(0.15)).cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.warmOnGreen.opacity(0.25), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 28).padding(.bottom, 52)
            }
        }
    }
}

// MARK: - Goal initial (the pattern WarmGoalCard / WarmQuickDepositView use)

struct GoalInitialCircle: View {
    let name: String
    let color: GoalColor
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(color.color).frame(width: size, height: size)
            Text(name.first.map { String($0).uppercased() } ?? "·")
                .warmFont(size * 0.5, weight: .regular, design: .serif)
                .foregroundStyle(Color.warmOnGreen)
        }
        .accessibilityHidden(true)
    }
}
