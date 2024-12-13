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
                Text("Weekly Report")
                    .font(.title)
                    .fontWeight(.bold)

                VStack {
                    DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $viewModel.endDate, displayedComponents: .date)
                }
                
                HStack {
                    Spacer()
                    Button(action: viewModel.fetchReportData) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Fetch Report")
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
                    Text("Income Distribution")
                        .font(.title3)
                        .fontWeight(.bold)

                    Chart(viewModel.weeklyIncomes) { income in
                        BarMark(
                            x: .value("Description", income.incomeDescription),
                            y: .value("Amount", income.amount)
                        )
                    }
                    .frame(height: 200)
                }
            }

            // Expense Chart
            if !viewModel.weeklyExpenses.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Expense Distribution")
                        .font(.title3)
                        .fontWeight(.bold)

                    Chart(viewModel.weeklyExpenses) { expense in
                        SectorMark(
                            angle: .value("Amount", expense.amount),
                            innerRadius: .ratio(0.5),
                            outerRadius: .ratio(1.0)
                        )
                        .foregroundStyle(by: .value("Description", expense.expenseDescription))
                    }
                    .frame(height: 200)
                }
            }

            if viewModel.weeklyIncomes.isEmpty && viewModel.weeklyExpenses.isEmpty {
                Text("No data available for the selected dates.")
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
