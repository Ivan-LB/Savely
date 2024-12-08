////
////  ReportsView.swift
////  Savely
////
////  Created by Ivan Lorenzana Belli on 16/10/24.
////
//
//import SwiftUI
//import Charts
//
//struct ReportsView: View {
//    @State private var date: Date = Date()
//    
//    let expenseData = [
//        ExpenseCategoryModel(category: "Alimentación", amount: 300),
//        ExpenseCategoryModel(category: "Transporte", amount: 150),
//        ExpenseCategoryModel(category: "Entretenimiento", amount: 100),
//        ExpenseCategoryModel(category: "Servicios", amount: 200),
//        ExpenseCategoryModel(category: "Otros", amount: 50)
//    ]
//    
//    let savingsData = [
//        MonthlySavingModel(month: "Ene", amount: 100),
//        MonthlySavingModel(month: "Feb", amount: 150),
//        MonthlySavingModel(month: "Mar", amount: 200),
//        MonthlySavingModel(month: "Abr", amount: 180),
//        MonthlySavingModel(month: "May", amount: 250),
//        MonthlySavingModel(month: "Jun", amount: 300)
//    ]
//    
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 20) {
//                // Header Section
////                VStack(alignment: .leading, spacing: 5) {
////                    Text("Reportes Financieros")
////                        .font(.largeTitle)
////                        .fontWeight(.bold)
////                        .foregroundColor(.white)
////                }
////                .padding()
////                .frame(maxWidth: .infinity, alignment: .leading)
////                .background(Color.blue)
//                
//                // Filter Card
//                CardView(content: {
//                    VStack(alignment: .leading, spacing: 15) {
//                        HStack {
//                            Picker(Strings.ReportsView.pickTimePeriodLabel, selection: $date) {
//                                Text(Strings.ReportsView.thisMonthLabel).tag("month")
//                                Text(Strings.ReportsView.thisTrimesterLabel).tag("quarter")
//                                Text(Strings.ReportsView.thisYearLabel).tag("year")
//                            }
//                            .pickerStyle(MenuPickerStyle())
//                            
//                            Button(action: {
//                                // Action for filtering
//                                print("Hola")
//                            }) {
//                                Label(Strings.Buttons.filterButton, systemImage: "line.horizontal.3.decrease.circle")
//                                    .padding(10)
//                                    .background(Color.gray.opacity(0.1))
//                                    .cornerRadius(8)
//                            }
//                        }
//                        .padding(.bottom, 10)
//                        
//                        DatePicker(Strings.ReportsView.pickDateLabel, selection: $date, displayedComponents: .date)
//                            .datePickerStyle(GraphicalDatePickerStyle())
//                    }
//                    .padding()
//                })
//                .padding(.horizontal)
//                
//                // Expense Distribution Chart
//                CardView(content: {
//                    VStack(alignment: .leading, spacing: 10) {
//                        Text(Strings.ReportsView.expenseDistributionLabel)
//                            .font(.title3)
//                            .fontWeight(.bold)
//                        Chart(expenseData) { data in
//                            SectorMark(
//                                angle: .value(Strings.ExpenseTrackerTab.amountPlaceholderLabel, data.amount),
//                                innerRadius: .ratio(0.5)
//                            )
//                        }
//                        .frame(height: 200)
//                    }
//                    .padding()
//                })
//                .padding(.horizontal)
//                
//                // Savings Trend Line Chart
//                CardView(content: {
//                    VStack(alignment: .leading, spacing: 10) {
//                        Text(Strings.ReportsView.savingsTrendLabel)
//                            .font(.title3)
//                            .fontWeight(.bold)
//                        Chart {
//                            ForEach(savingsData) { data in
//                                LineMark(
//                                    x: .value(Strings.Placeholders.monthsLabel, data.month),
//                                    y: .value(Strings.Placeholders.savingsLabel, data.amount)
//                                )
//                            }
//                        }
//                        .frame(height: 200)
//                    }
//                    .padding()
//                })
//                .padding(.horizontal)
//                
//                // Monthly Summary Bar Chart
//                CardView(content: {
//                    VStack(alignment: .leading, spacing: 10) {
//                        Text(Strings.Placeholders.monthlySummaryPlaceholder)
//                            .font(.title3)
//                            .fontWeight(.bold)
//                        Chart {
//                            BarMark(x: .value(Strings.Placeholders.categoryPlaceholder, Strings.Tabs.incomesTab), y: .value(Strings.ExpenseTrackerTab.amountPlaceholderLabel, 2000))
//                            BarMark(x: .value(Strings.Placeholders.categoryPlaceholder, Strings.Tabs.expensesTab), y: .value(Strings.ExpenseTrackerTab.amountPlaceholderLabel, 1500))
//                            BarMark(x: .value(Strings.Placeholders.categoryPlaceholder, Strings.Placeholders.savingsPlaceholder), y: .value(Strings.ExpenseTrackerTab.amountPlaceholderLabel, 500))
//                        }
//                        .frame(height: 200)
//                    }
//                    .padding()
//                })
//                .padding(.horizontal)
//                
//                // Export Report Button
//                Button(action: {
//                    // Action to export report
//                }) {
//                    HStack {
//                        Image(systemName: "square.and.arrow.down")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 20, height: 20)
//                        Text(Strings.Buttons.exportReport)
//                            .fontWeight(.bold)
//                    }
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//                }
//                .padding(.horizontal)
//            }
//            .padding(.vertical)
//        }
//        .background(Color(UIColor.systemGray6))
//    }
//}
//
//struct ReportsView_Previews: PreviewProvider {
//    static var previews: some View {
//        ReportsView()
//    }
//}
