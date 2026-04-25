import SwiftUI
import SwiftData

// MARK: - Add Goal state carried through all steps

final class AddGoalState: ObservableObject {
    @Published var name: String = ""
    @Published var emoji: String = "✈️"
    @Published var color: GoalColor = .green
    @Published var amountStr: String = "0"
    @Published var deadline: Date = Calendar.current.date(byAdding: .month, value: 18, to: Date()) ?? Date()
    @Published var autoDeposit: Bool = true
    @Published var showReminders: Bool = true
    @Published var isFavorite: Bool = false

    var amount: Double { Double(amountStr) ?? 0 }

    var weeklyPace: Double {
        let weeks = max(1, Calendar.current.dateComponents([.weekOfYear], from: Date(), to: deadline).weekOfYear ?? 78)
        return amount / Double(weeks)
    }

    var monthlyPace: Double { weeklyPace * 4.33 }

    func weeksBetweenNowAndDeadline() -> Int {
        max(1, Calendar.current.dateComponents([.weekOfYear], from: Date(), to: deadline).weekOfYear ?? 78)
    }
}

// MARK: - Flow container

struct AddGoalFlowView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    @StateObject private var state = AddGoalState()
    @State private var step = 1
    @State private var showSuccess = false

    var body: some View {
        if showSuccess {
            AddGoalSuccessView(
                state: state,
                onDeposit: { isPresented = false },
                onHome: { isPresented = false }
            )
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
        }
    }

    private func plantGoal() {
        guard !state.name.isEmpty, state.amount > 0 else { return }
        let goal = GoalModel(
            name: state.name,
            current: 0,
            target: state.amount,
            color: state.color,
            isFavorite: state.isFavorite
        )
        modelContext.insert(goal)
        try? modelContext.save()
        withAnimation(.easeInOut(duration: 0.4)) { showSuccess = true }
    }
}

// MARK: - Shared header

struct AddGoalHeader: View {
    let step: Int; let total: Int
    let onBack: () -> Void; let onSkip: () -> Void
    var showClose: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Button(action: onBack) {
                    Image(systemName: showClose ? "xmark" : "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.warmInk)
                        .frame(width: 36, height: 36)
                        .background(Color.warmSurface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.warmLine, lineWidth: 1))
                }
                Spacer()
                Text("New goal · ")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.warmInkMuted)
                + Text("\(step)").font(.system(size: 13, weight: .semibold)).foregroundColor(Color.warmInk)
                + Text(" of \(total)").font(.system(size: 13)).foregroundColor(Color.warmInkMuted)
                Spacer()
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.warmInkMuted)
                        .frame(width: 36, height: 36)
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

// MARK: - Step 1: Intent — name, emoji, color

private let goalEmojis = ["✈️", "🏡", "🌿", "🚗", "💍", "🎓", "🎁", "🏥"]

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
                        .font(.system(size: 11, weight: .bold)).foregroundStyle(Color.warmGreen).tracking(1.2)
                    Text("Give it a name\nyou'll recognize.")
                        .font(.system(size: 32, weight: .regular, design: .serif)).foregroundStyle(Color.warmInk)
                        .lineSpacing(2)
                    Text("This is what you'll see on your dashboard.")
                        .font(.system(size: 14)).foregroundStyle(Color.warmInkSoft)
                }
                .padding(.horizontal, 24).padding(.bottom, 24)

                // Live preview chip
                HStack {
                    Spacer()
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(state.color.trackColor).frame(width: 44, height: 44)
                            Text(state.emoji).font(.system(size: 22))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(state.name.isEmpty ? "Your goal name" : state.name)
                                .font(.system(size: 20, weight: .regular, design: .serif))
                                .foregroundStyle(state.name.isEmpty ? Color.warmInkMuted : Color.warmInk)
                            Text("Live preview")
                                .font(.system(size: 11)).foregroundStyle(Color.warmInkMuted)
                        }
                    }
                    .padding(.vertical, 12).padding(.horizontal, 18)
                    .background(Color.warmSurface)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.warmLine, lineWidth: 1))
                    .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
                    Spacer()
                }
                .padding(.bottom, 20)

                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("NAME")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.warmInkMuted).tracking(0.8)
                    HStack {
                        TextField("e.g. Kyoto, autumn '26", text: $state.name)
                            .font(.system(size: 16)).foregroundStyle(Color.warmInk)
                            .focused($nameFocused)
                        if !state.name.isEmpty {
                            Button(action: { state.name = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16)).foregroundStyle(Color.warmInkMuted)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.warmSurface)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(nameFocused ? Color.warmGreen : Color.warmLine, lineWidth: nameFocused ? 1.5 : 1)
                    )
                    .shadow(color: nameFocused ? Color.warmGreenSoft : .clear, radius: 0, x: 0, y: 0)
                    Text("Tip: be specific. Try a specific name like Kyoto trip '26.")
                        .font(.system(size: 12)).foregroundStyle(Color.warmInkMuted).padding(.leading, 4)
                }
                .padding(.horizontal, 20).padding(.bottom, 24)

                // Emoji picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("SYMBOL")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.warmInkMuted).tracking(0.8)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                        ForEach(goalEmojis, id: \.self) { e in
                            let isOn = state.emoji == e
                            Button(action: { state.emoji = e }) {
                                Text(e).font(.system(size: 20))
                                    .frame(width: 44, height: 44)
                                    .background(isOn ? state.color.trackColor : Color.warmSurface)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isOn ? state.color.color : Color.warmLine, lineWidth: isOn ? 1.5 : 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.15), value: state.emoji)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 24)

                // Color picker (6-swatch row from design)
                VStack(alignment: .leading, spacing: 10) {
                    Text("COLOR")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.warmInkMuted).tracking(0.8)
                    HStack(spacing: 12) {
                        ForEach([GoalColor.green, .blue, .yellow, .red, .purple, .brown], id: \.id) { gc in
                            let isOn = state.color == gc
                            Button(action: { state.color = gc }) {
                                Circle()
                                    .fill(gc.color)
                                    .frame(width: 38, height: 38)
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth: isOn ? 3 : 0)
                                    )
                                    .shadow(color: isOn ? gc.color.opacity(0.5) : .clear, radius: 4, y: 2)
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.15), value: state.color)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 32)

                Button(action: onNext) {
                    Text("Continue")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(state.name.isEmpty ? Color.warmInkMuted : Color.warmGreen)
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
    private let presets: [Double] = [1000, 2500, 5000, 10000]

    var body: some View {
        VStack(spacing: 0) {
            AddGoalHeader(step: 2, total: 4, onBack: onBack, onSkip: onSkip)

            VStack(alignment: .leading, spacing: 10) {
                Text("HOW MUCH")
                    .font(.system(size: 11, weight: .bold)).foregroundStyle(Color.warmGreen).tracking(1.2)
                Text("What's the\nfinish line?")
                    .font(.system(size: 32, weight: .regular, design: .serif)).foregroundStyle(Color.warmInk)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24).padding(.bottom, 8)

            // Goal name chip
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(state.color.trackColor).frame(width: 28, height: 28)
                    Text(state.emoji).font(.system(size: 14))
                }
                Text(state.name)
                    .font(.system(size: 13)).foregroundStyle(Color.warmInkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24).padding(.bottom, 8)

            Spacer(minLength: 0)

            // Large amount display
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("$")
                    .font(.system(size: 36, weight: .regular, design: .serif)).foregroundStyle(Color.warmInkMuted)
                Text(formatKeypadAmount(state.amountStr))
                    .font(.system(size: 88, weight: .regular, design: .serif)).foregroundStyle(Color.warmInk)
                    .monospacedDigit().minimumScaleFactor(0.35).lineLimit(1)
            }
            .padding(.horizontal, 20)

            // Pace whisper
            if state.amount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11)).foregroundStyle(Color.warmAmber)
                    Text("About ")
                        .font(.system(size: 12)).foregroundStyle(Color.warmInkMuted)
                    + Text("$\(Int(state.weeklyPace))/week")
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(Color.warmInk)
                    + Text(" for 18 months")
                        .font(.system(size: 12)).foregroundColor(Color.warmInkMuted)
                }
                .padding(.top, 14)
            }

            // Preset chips
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { p in
                    let isOn = state.amountStr == "\(Int(p))"
                    Button(action: { state.amountStr = "\(Int(p))" }) {
                        Text("$\(Int(p).formatted())")
                            .font(.system(size: 13, weight: .semibold))
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
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(state.amount > 0 ? Color.warmGreen : Color.warmInkMuted)
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
                        .font(.system(size: 11, weight: .bold)).foregroundStyle(Color.warmGreen).tracking(1.2)
                    Text("When do you\nwant this by?")
                        .font(.system(size: 32, weight: .regular, design: .serif)).foregroundStyle(Color.warmInk)
                }
                .padding(.horizontal, 24).padding(.bottom, 20)

                // Green pace card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold)).foregroundStyle(.white.opacity(0.85))
                        Text("SUGGESTED PACE")
                            .font(.system(size: 11, weight: .bold)).foregroundStyle(.white.opacity(0.85)).tracking(1.2)
                    }
                    HStack(alignment: .firstTextBaseline) {
                        Text("$\(Int(state.weeklyPace))")
                            .font(.system(size: 38, weight: .regular, design: .serif)).foregroundStyle(.white)
                        Text("/wk")
                            .font(.system(size: 18)).foregroundStyle(.white.opacity(0.7)).padding(.leading, 2)
                        Spacer()
                        Text("~$\(Int(state.monthlyPace))/mo")
                            .font(.system(size: 13)).foregroundStyle(.white.opacity(0.85))
                    }
                    Text("To hit **$\(Int(state.amount))** by **\(formattedDeadline)**.")
                        .font(.system(size: 13)).foregroundStyle(.white.opacity(0.85))
                }
                .padding(18)
                .background(Color.warmGreen)
                .cornerRadius(22)
                .padding(.horizontal, 20).padding(.bottom, 16)

                // Mini calendar
                MiniCalendarView(displayMonth: $displayMonth, selectedDate: $state.deadline)
                    .padding(.horizontal, 20).padding(.bottom, 14)

                // Duration presets
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(durationPresets, id: \.label) { preset in
                            let isOn = (preset.months ?? -1) == selectedDuration
                            Button(action: {
                                if let m = preset.months {
                                    selectedDuration = m
                                    state.deadline = Calendar.current.date(byAdding: .month, value: m, to: Date()) ?? Date()
                                    displayMonth = state.deadline
                                } else {
                                    selectedDuration = -1
                                }
                            }) {
                                Text(preset.label)
                                    .font(.system(size: 13, weight: .semibold))
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
                        .font(.system(size: 15)).foregroundStyle(Color.warmGreen)
                        .frame(width: 36, height: 36).background(Color.warmGreenSoft).cornerRadius(10)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-move on payday")
                            .font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.warmInk)
                        Text("Set $\(Int(state.monthlyPace)) aside the day after each paycheck.")
                            .font(.system(size: 12)).foregroundStyle(Color.warmInkMuted)
                    }
                    Spacer()
                    Toggle("", isOn: $state.autoDeposit)
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
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Color.warmGreen).cornerRadius(14)
                }
                .padding(.horizontal, 20).padding(.bottom, 32)
            }
        }
        .background(Color.warmBg.ignoresSafeArea())
    }

    private var formattedDeadline: String {
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
                    Image(systemName: "chevron.left").font(.system(size: 13)).foregroundStyle(Color.warmInkSoft)
                        .frame(width: 28, height: 28).cornerRadius(8)
                }
                Spacer()
                Text(monthTitle).font(.system(size: 18, weight: .regular, design: .serif)).foregroundStyle(Color.warmInk)
                Spacer()
                Button(action: shiftMonth(1)) {
                    Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(Color.warmInkSoft)
                        .frame(width: 28, height: 28).cornerRadius(8)
                }
            }
            .padding(.bottom, 14)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(dayLabels, id: \.self) { d in
                    Text(d).font(.system(size: 10, weight: .semibold)).foregroundStyle(Color.warmInkMuted)
                }
                ForEach(0..<leadingBlanks, id: \.self) { _ in Color.clear.frame(height: 32) }
                ForEach(1...daysInMonth, id: \.self) { day in
                    let isSelected = isSelectedDay(day)
                    Button(action: { selectDay(day) }) {
                        Text("\(day)")
                            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? .white : Color.warmInk)
                            .frame(maxWidth: .infinity).frame(height: 32)
                            .background(isSelected ? Color.warmGreen : Color.clear)
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
                AddGoalHeader(step: 4, total: 4, onBack: onBack, onSkip: {})

                VStack(alignment: .leading, spacing: 10) {
                    Text("ALMOST THERE")
                        .font(.system(size: 11, weight: .bold)).foregroundStyle(Color.warmGreen).tracking(1.2)
                    Text("Take a look\nbefore we start.")
                        .font(.system(size: 32, weight: .regular, design: .serif)).foregroundStyle(Color.warmInk)
                }
                .padding(.horizontal, 24).padding(.bottom, 24)

                // Hero preview card
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(state.color.trackColor).frame(width: 44, height: 44)
                            Text(state.emoji).font(.system(size: 22))
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(state.name)
                                .font(.system(size: 22, weight: .regular, design: .serif)).foregroundStyle(Color.warmInk)
                            Text("Goal · \(formattedDeadline)")
                                .font(.system(size: 12)).foregroundStyle(Color.warmInkMuted)
                        }
                        Spacer()
                        Text("New")
                            .font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.warmGreenDeep)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color.warmGreenSoft).clipShape(Capsule())
                    }
                    .padding(.bottom, 16)

                    HStack(alignment: .firstTextBaseline) {
                        Text("$0")
                            .font(.system(size: 32, weight: .regular, design: .serif)).foregroundStyle(Color.warmInk)
                        Spacer()
                        Text("of $\(Int(state.amount))")
                            .font(.system(size: 13)).foregroundStyle(Color.warmInkMuted)
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
                        ForEach([("Per week","$\(Int(state.weeklyPace))"),("Per month","$\(Int(state.monthlyPace))"),("By",shortDeadline)], id: \.0) { item in
                            VStack(spacing: 4) {
                                Text(item.0)
                                    .font(.system(size: 9)).foregroundStyle(Color.warmInkMuted).textCase(.uppercase).tracking(0.8)
                                Text(item.1)
                                    .font(.system(size: 16, weight: .regular, design: .serif)).foregroundStyle(Color.warmInk)
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
                .shadow(color: .black.opacity(0.05), radius: 16, y: 6)
                .padding(.horizontal, 20).padding(.bottom, 20)

                // Recap toggles
                VStack(spacing: 0) {
                    RecapToggleRow(label: "Auto-move", sub: "On — $\(Int(state.monthlyPace)) each payday", isOn: $state.autoDeposit)
                    Divider().padding(.horizontal, 16)
                    RecapToggleRow(label: "Reminders", sub: "Friday mornings", isOn: $state.showReminders)
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
                        .font(.system(size: 13)).foregroundStyle(Color.warmAmber)
                    Text("That's **about one less takeout per week**. Doable.")
                        .font(.system(size: 12)).foregroundStyle(Color(red: 0.478, green: 0.337, blue: 0.094))
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
                                .font(.system(size: 14, weight: .semibold))
                            Text("Plant goal")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Color.warmGreen).cornerRadius(14)
                    }
                    Button(action: onBack) {
                        Text("Edit anything")
                            .font(.system(size: 13)).foregroundStyle(Color.warmInkMuted)
                            .padding(.vertical, 14)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 32)
            }
        }
        .background(Color.warmBg.ignoresSafeArea())
    }

    private var formattedDeadline: String {
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"; return f.string(from: state.deadline)
    }
    private var shortDeadline: String {
        let f = DateFormatter(); f.dateFormat = "MMM ''yy"; return f.string(from: state.deadline)
    }
}

struct RecapToggleRow: View {
    let label: String; let sub: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.warmInk)
                Text(sub).font(.system(size: 12)).foregroundStyle(Color.warmInkMuted)
            }
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().tint(Color.warmGreen)
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
            Color.warmGreen.ignoresSafeArea()

            GeometryReader { geo in
                ForEach(Array(dots.enumerated()), id: \.offset) { _, dot in
                    Circle()
                        .fill(dot.3 ? Color.warmAmber : Color.white)
                        .frame(width: dot.2, height: dot.2)
                        .opacity(0.5)
                        .position(x: geo.size.width * dot.0, y: geo.size.height * dot.1)
                }
            }

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle().fill(Color.white.opacity(0.14)).frame(width: 132, height: 132)
                    Circle().fill(Color.white).frame(width: 88, height: 88)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(Color.warmGreen)
                        )
                }
                .padding(.bottom, 28)

                Text("Planted.")
                    .font(.system(size: 42, weight: .regular, design: .serif))
                    .foregroundStyle(.white)
                    .padding(.bottom, 12)

                Text("\(state.name) is on your home screen.\nAdd the first dollar?")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)

                Spacer()

                VStack(spacing: 10) {
                    Button(action: onDeposit) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus").font(.system(size: 14, weight: .semibold))
                            Text("Add a deposit").font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(Color.warmGreen)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(Color.white).cornerRadius(14)
                    }
                    Button(action: onHome) {
                        Text("Back to home")
                            .font(.system(size: 15, weight: .medium)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(Color.white.opacity(0.15)).cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.25), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 28).padding(.bottom, 52)
            }
        }
    }
}
