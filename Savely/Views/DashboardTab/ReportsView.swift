//
//  ReportsView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 16/10/24.
//

import SwiftUI
import Charts
import SwiftData

/// Income by source and expenses by category over a date range. Reachable
/// from Profile → Reports. Groups by the *stored* chip (legacy rows fall
/// back to the same keyword inference the Money tab uses), so the bars
/// finally mean something.
struct ReportsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ReportsViewModel()

    private struct Slice: Identifiable {
        let label: String
        let amount: Double
        var id: String { label }
    }

    private var incomeBySource: [Slice] {
        var totals: [String: Double] = [:]
        for income in viewModel.weeklyIncomes {
            let key = IncomeSource.display(stored: income.source)?.label ?? "Untagged"
            totals[key, default: 0] += income.amount
        }
        return totals.map { Slice(label: $0.key, amount: $0.value) }.sorted { $0.amount > $1.amount }
    }

    private var expensesByCategory: [Slice] {
        var totals: [String: Double] = [:]
        for expense in viewModel.weeklyExpenses {
            let key = ExpenseCategory.display(stored: expense.category, description: expense.expenseDescription).label
            totals[key, default: 0] += expense.amount
        }
        return totals.map { Slice(label: $0.key, amount: $0.value) }.sorted { $0.amount > $1.amount }
    }

    private var expenseColorScale: KeyValuePairs<String, Color> {
        KeyValuePairs(dictionaryLiteral:
            (ExpenseCategory.coffee.label, ExpenseCategory.coffee.tileColor),
            (ExpenseCategory.food.label, ExpenseCategory.food.tileColor),
            (ExpenseCategory.transit.label, ExpenseCategory.transit.tileColor),
            (ExpenseCategory.shopping.label, ExpenseCategory.shopping.tileColor),
            (ExpenseCategory.other.label, ExpenseCategory.other.tileColor)
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // — Header —
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reports")
                        .font(.system(size: 34, weight: .regular, design: .serif))
                        .foregroundStyle(Color.warmInk)
                    Text(rangeSubtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.warmInkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

                // — Range —
                VStack(spacing: 0) {
                    dateRow(Strings.ReportsView.startDateLabel, selection: $viewModel.startDate)
                    WarmDivider()
                    dateRow(Strings.ReportsView.endDateLabel, selection: $viewModel.endDate)
                }
                .background(Color.warmSurface)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.warmLine, lineWidth: 1))

                if viewModel.isLoading {
                    ProgressView().tint(Color.warmGreen).padding(.vertical, 8)
                }

                // — Income by source —
                if !incomeBySource.isEmpty {
                    chartCard(title: Strings.ReportsView.incomeDistributionLabel) {
                        Chart(incomeBySource) { slice in
                            BarMark(
                                x: .value("Amount", slice.amount),
                                y: .value("Source", slice.label)
                            )
                            .foregroundStyle(Color.warmGreen)
                            .cornerRadius(4)
                        }
                        .chartXAxis { AxisMarks(position: .bottom) { AxisValueLabel(format: .currency(code: "USD").precision(.fractionLength(0))) } }
                        .frame(height: CGFloat(28 * incomeBySource.count + 40))
                    }
                }

                // — Expenses by category —
                if !expensesByCategory.isEmpty {
                    chartCard(title: Strings.ReportsView.expenseDistributionLabel) {
                        Chart(expensesByCategory) { slice in
                            BarMark(
                                x: .value("Amount", slice.amount),
                                y: .value("Category", slice.label)
                            )
                            .foregroundStyle(by: .value("Category", slice.label))
                            .cornerRadius(4)
                        }
                        .chartForegroundStyleScale(expenseColorScale)
                        .chartLegend(.hidden)
                        .chartXAxis { AxisMarks(position: .bottom) { AxisValueLabel(format: .currency(code: "USD").precision(.fractionLength(0))) } }
                        .frame(height: CGFloat(28 * expensesByCategory.count + 40))
                    }
                }

                if !viewModel.isLoading && incomeBySource.isEmpty && expensesByCategory.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "chart.bar").font(.system(size: 36)).foregroundStyle(Color.warmInkMuted)
                        Text(Strings.ReportsView.noDataLabel)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.warmInkSoft)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }

                Spacer(minLength: 16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.warmBg)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.setModelContext(modelContext) }
        .onChange(of: viewModel.startDate) { viewModel.fetchReportData() }
        .onChange(of: viewModel.endDate) { viewModel.fetchReportData() }
    }

    private var rangeSubtitle: String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return "\(f.string(from: viewModel.startDate)) – \(f.string(from: viewModel.endDate))"
    }

    private func dateRow(_ title: String, selection: Binding<Date>) -> some View {
        HStack(spacing: 16) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.warmInk)
            Spacer()
            DatePicker(title, selection: selection, displayedComponents: .date)
                .labelsHidden()
                .tint(Color.warmGreen)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundStyle(Color.warmInk)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.warmSurface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.warmLine, lineWidth: 1))
    }
}

#Preview {
    NavigationStack { ReportsView() }
}

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}
