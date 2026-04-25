import SwiftUI
import SwiftData

struct IncomesTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = IncomesTrackerViewModel()
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case description, amount }

    // 7-month bar heights (most recent = current month)
    private var barData: [(String, Double)] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .month, value: -offset, to: now) ?? now
            let total = viewModel.incomes.filter {
                calendar.isDate($0.date, equalTo: date, toGranularity: .month)
            }.reduce(0) { $0 + $1.amount }
            let f = DateFormatter(); f.dateFormat = "MMM"
            return (f.string(from: date), total)
        }
    }
    private var maxBar: Double { max(barData.map(\.1).max() ?? 1, 1) }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // — Header —
                VStack(alignment: .leading, spacing: 2) {
                    Text("Income")
                        .font(.system(size: 34, weight: .regular, design: .serif))
                        .foregroundStyle(Color.warmInk)
                    Text("April · \(formattedAmount(viewModel.totalIncomeThisMonth))")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.warmInkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

                // — 7-month trend chart —
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("7-month trend")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.warmInkMuted)
                            .tracking(0.6)
                            .textCase(.uppercase)
                        Spacer()
                        if viewModel.percentageChange > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.up").font(.system(size: 10, weight: .semibold))
                                Text(String(format: "+%.0f%%", viewModel.percentageChange))
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(Color.warmGreen)
                        }
                    }
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(Array(barData.enumerated()), id: \.offset) { idx, bar in
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(idx == barData.count - 1 ? Color.warmGreen : Color.warmGreenSoft)
                                    .frame(height: max(4, CGFloat(bar.1 / maxBar) * 80))
                                Text(bar.0)
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.warmInkMuted)
                            }
                            .frame(maxWidth: .infinity, alignment: .bottom)
                        }
                    }
                    .frame(height: 100, alignment: .bottom)
                }
                .padding(18)
                .background(Color.warmSurface)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.warmLine, lineWidth: 1))

                // — Inline add —
                HStack(spacing: 10) {
                    TextField("Source…", text: $viewModel.incomeDescription)
                        .font(.system(size: 14))
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
                            .frame(width: 70)
                            .focused($focusedField, equals: .amount)
                    }
                    .frame(height: 40)
                    .background(Color.warmBg)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.warmLineSoft, lineWidth: 1))

                    Button(action: { viewModel.addIncome(); focusedField = nil }) {
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

                // — History —
                VStack(alignment: .leading, spacing: 8) {
                    Text("History")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.warmInkMuted)
                        .tracking(1)
                        .textCase(.uppercase)
                        .padding(.leading, 4)

                    if viewModel.incomes.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "tray").font(.system(size: 40)).foregroundStyle(Color.warmInkMuted)
                            Text("No income yet").font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.warmInkSoft)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 44)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(viewModel.incomes.prefix(20).enumerated()), id: \.element.id) { idx, income in
                                IncomeRowWarm(income: income, onDelete: { viewModel.deleteIncome(income) })
                                if idx < min(viewModel.incomes.count - 1, 19) {
                                    Divider().padding(.leading, 58).overlay(Color.warmLineSoft)
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
        .onAppear { if viewModel.modelContext == nil { viewModel.setModelContext(modelContext) } }
    }

    private func formattedAmount(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencySymbol = "$"; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "$0"
    }
}

// MARK: - Income Row (warm style)

struct IncomeRowWarm: View {
    let income: IncomeModel
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.warmGreenSoft)
                .frame(width: 36, height: 36)
                .overlay(Image(systemName: "arrow.up").font(.system(size: 14, weight: .medium)).foregroundStyle(Color.warmGreen))

            VStack(alignment: .leading, spacing: 2) {
                Text(income.incomeDescription)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.warmInk)
                Text(shortDate(income.date))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.warmInkMuted)
            }
            Spacer()
            Text("+\(formattedAmount(income.amount))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.warmGreen)
                .monospacedDigit()
        }
        .padding(.horizontal, 14).padding(.vertical, 14)
        .contextMenu {
            Button(role: .destructive, action: { showDeleteConfirmation = true }) { Label("Delete", systemImage: "trash") }
        }
        .confirmationDialog("Delete Income", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Are you sure you want to delete this income?") }
    }

    private func shortDate(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"
        return f.string(from: d)
    }
    private func formattedAmount(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencySymbol = "$"; f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: v)) ?? "$0"
    }
}

#Preview { IncomesTrackerView() }
