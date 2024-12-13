//
//  ReportsView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 16/10/24.
//

import SwiftUI
import Charts
import SwiftData

struct ReportsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ReportsViewModel

    init() {
        _viewModel = StateObject(wrappedValue: ReportsViewModel(modelContext: Environment(\.modelContext).wrappedValue))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Date Picker
            VStack(alignment: .leading, spacing: 15) {
                Text(Strings.Profile.weeklyReportTitle)
                    .font(.title)
                    .fontWeight(.bold)

                VStack {
                    DatePicker(Strings.ReportsView.startDateLabel, selection: $viewModel.startDate, displayedComponents: .date)
                    DatePicker(Strings.ReportsView.endDateLabel, selection: $viewModel.endDate, displayedComponents: .date)
                }
                
                HStack {
                    Spacer()
                    Button(action: viewModel.fetchReportData) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text(Strings.Buttons.fetchReportButton)
                                .fontWeight(.bold)
                        }
                    }
                    .padding()
                    .background(Color("primaryBlue"))
                    .foregroundColor(.white)
                    .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
                    Spacer()
                }
            }

            // Income Chart
            if !viewModel.weeklyIncomes.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(Strings.ReportsView.incomeDistributionLabel)
                        .font(.title3)
                        .fontWeight(.bold)

                    Chart(viewModel.weeklyIncomes) { income in
                        BarMark(
                            x: .value(Strings.ExpenseTrackerTab.descriptionPlaceholderLabel, income.incomeDescription),
                            y: .value(Strings.ExpenseTrackerTab.amountPlaceholderLabel, income.amount)
                        )
                    }
                    .frame(height: 200)
                }
            }

            // Expense Chart
            if !viewModel.weeklyExpenses.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(Strings.ReportsView.expenseDistributionLabel)
                        .font(.title3)
                        .fontWeight(.bold)

                    Chart(viewModel.weeklyExpenses) { expense in
                        SectorMark(
                            angle: .value(Strings.ExpenseTrackerTab.amountPlaceholderLabel, expense.amount),
                            innerRadius: .ratio(0.5),
                            outerRadius: .ratio(1.0)
                        )
                        .foregroundStyle(by: .value(Strings.ExpenseTrackerTab.descriptionPlaceholderLabel, expense.expenseDescription))
                    }
                    .frame(height: 200)
                }
            }

            if viewModel.weeklyIncomes.isEmpty && viewModel.weeklyExpenses.isEmpty {
                Text(Strings.ReportsView.noDataLabel)
                    .font(.callout)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
        .background(Color("listBackgroundColor"))
        .cornerRadius(UIConstants.UICornerRadius.cornerRadiusMedium)
        .shadow(radius: UIConstants.UIShadow.shadow)
        .onAppear {
            viewModel.setModelContext(modelContext)
            viewModel.fetchReportData()
        }
    }
}

struct ReportsView_Previews: PreviewProvider {
    static var previews: some View {
        ReportsView()
    }
}

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}
