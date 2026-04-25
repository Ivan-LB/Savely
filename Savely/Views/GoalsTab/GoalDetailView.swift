import SwiftUI
import SwiftData

struct GoalDetailView: View {
    @Bindable var goal: GoalModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // — Header info —
                VStack(alignment: .leading, spacing: 6) {
                    if goal.isFavorite {
                        HStack(spacing: 5) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.warmAmber)
                            Text("FAVORITE")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.warmInkMuted)
                                .tracking(0.8)
                        }
                    }
                    Text(goal.name)
                        .font(.system(size: 36, weight: .regular, design: .serif))
                        .foregroundStyle(Color.warmInk)
                        .lineSpacing(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 20)

                // — Large ring —
                ZStack {
                    Circle()
                        .stroke(goal.trackColor, lineWidth: 16)
                    Circle()
                        .trim(from: 0, to: goal.progress)
                        .stroke(goal.color, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: goal.progress)
                    VStack(spacing: 4) {
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text("\(Int(goal.progress * 100))")
                                .font(.system(size: 52, weight: .regular, design: .serif))
                                .foregroundStyle(Color.warmInk)
                            Text("%")
                                .font(.system(size: 26))
                                .foregroundStyle(Color.warmInkMuted)
                        }
                        Text(formattedAmount(goal.current) + " of " + formattedAmount(goal.target))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.warmInkMuted)
                            .tracking(0.5)
                    }
                }
                .frame(width: 200, height: 200)
                .padding(.bottom, 24)

                // — Stat pills —
                HStack(spacing: 8) {
                    StatPill(label: "Remaining", value: formattedAmount(max(0, goal.target - goal.current)), accent: goal.color)
                    StatPill(label: "Per week", value: formattedAmount(perWeek), accent: goal.color)
                    StatPill(label: "ETA", value: etaString, accent: goal.color)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                // — Deposit card —
                DepositCard(goal: goal, modelContext: modelContext)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
            }
        }
        .background(Color.warmBg)
        .navigationTitle("Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.warmInk)
                        .frame(width: 36, height: 36)
                        .background(Color.warmSurface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.warmLine, lineWidth: 1))
                }
            }
        }
    }

    private var perWeek: Double {
        let remaining = max(0, goal.target - goal.current)
        return remaining / 24
    }

    private var etaString: String {
        guard goal.progress < 1.0 else { return "Done!" }
        let remaining = goal.target - goal.current
        guard remaining > 0 else { return "Done!" }
        let weeksLeft = remaining / max(1, perWeek)
        let eta = Calendar.current.date(byAdding: .weekOfYear, value: Int(weeksLeft), to: Date()) ?? Date()
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: eta)
    }

    private func formattedAmount(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency; f.currencySymbol = "$"; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "$0"
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let label: String
    let value: String
    var accent: Color = .warmGreen

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.warmInkMuted)
                .tracking(0.6)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundStyle(Color.warmInk)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.warmSurface)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.18), lineWidth: 1.5))
    }
}

// MARK: - Deposit Card

struct DepositCard: View {
    @Bindable var goal: GoalModel
    let modelContext: ModelContext
    @State private var amountText = ""
    @State private var note = ""
    private let quickAmounts: [Double] = [25, 50, 100, 250]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Handle
            HStack { Spacer(); Capsule().fill(Color.warmLine).frame(width: 40, height: 4); Spacer() }

            VStack(alignment: .leading, spacing: 4) {
                Text("Add a deposit")
                    .font(.system(size: 22, weight: .regular, design: .serif))
                    .foregroundStyle(Color.warmInk)
                Text("Move money toward \(goal.name.components(separatedBy: ",").first ?? goal.name).")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.warmInkMuted)
            }

            // Amount
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("$")
                    .font(.system(size: 48, weight: .regular, design: .serif))
                    .foregroundStyle(Color.warmInkMuted)
                TextField("0", text: $amountText)
                    .font(.system(size: 64, weight: .regular, design: .serif))
                    .foregroundStyle(Color.warmInk)
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: .infinity)
                Text(".00")
                    .font(.system(size: 32, weight: .regular, design: .serif))
                    .foregroundStyle(Color.warmInkMuted)
            }

            // Quick pills
            HStack(spacing: 8) {
                ForEach(quickAmounts, id: \.self) { amt in
                    let isSelected = amountText == String(Int(amt))
                    Button(action: { amountText = String(Int(amt)) }) {
                        Text("$\(Int(amt))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(isSelected ? goal.color : Color.warmInkMuted)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSelected ? goal.trackColor : Color.clear)
                            .cornerRadius(999)
                            .overlay(Capsule().stroke(isSelected ? goal.color.opacity(0.3) : Color.warmLine, lineWidth: 1))
                    }
                }
            }

            // Note field
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

            // CTA
            Button(action: saveDeposit) {
                Text(amountText.isEmpty ? "Add deposit" : "Add $\(amountText) to \(goalFirstName)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(goal.color)
                    .cornerRadius(14)
            }
            .disabled(depositAmount == nil)
            .opacity(depositAmount == nil ? 0.5 : 1)
        }
        .padding(20)
        .background(Color.warmSurface)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.warmLine, lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    private var depositAmount: Double? { Double(amountText) }
    private var goalFirstName: String { goal.name.components(separatedBy: ",").first ?? goal.name }

    private func saveDeposit() {
        guard let amt = depositAmount, amt > 0 else { return }
        goal.current = min(goal.current + amt, goal.target)
        try? modelContext.save()
        amountText = ""
        note = ""
    }
}
