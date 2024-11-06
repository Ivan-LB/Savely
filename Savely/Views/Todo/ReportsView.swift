//
//  ReportsView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 16/10/24.
//

import SwiftUI
import Charts

struct ReportsView: View {
    @State private var date: Date = Date()
    
    let expenseData = [
        ExpenseCategory(category: "Alimentación", amount: 300),
        ExpenseCategory(category: "Transporte", amount: 150),
        ExpenseCategory(category: "Entretenimiento", amount: 100),
        ExpenseCategory(category: "Servicios", amount: 200),
        ExpenseCategory(category: "Otros", amount: 50)
    ]
    
    let savingsData = [
        MonthlySaving(month: "Ene", amount: 100),
        MonthlySaving(month: "Feb", amount: 150),
        MonthlySaving(month: "Mar", amount: 200),
        MonthlySaving(month: "Abr", amount: 180),
        MonthlySaving(month: "May", amount: 250),
        MonthlySaving(month: "Jun", amount: 300)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
//                VStack(alignment: .leading, spacing: 5) {
//                    Text("Reportes Financieros")
//                        .font(.largeTitle)
//                        .fontWeight(.bold)
//                        .foregroundColor(.white)
//                }
//                .padding()
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .background(Color.blue)
                
                // Filter Card
                CardView(content: {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Picker("Seleccionar Período", selection: $date) {
                                Text("Este mes").tag("month")
                                Text("Este trimestre").tag("quarter")
                                Text("Este año").tag("year")
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                            Button(action: {
                                // Action for filtering
                                print("Hola")
                            }) {
                                Label(Strings.Buttons.filterButton, systemImage: "line.horizontal.3.decrease.circle")
                                    .padding(10)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.bottom, 10)
                        
                        DatePicker("Seleccionar Fecha", selection: $date, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                    }
                    .padding()
                })
                .padding(.horizontal)
                
                // Expense Distribution Chart
                CardView(content: {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Distribución de Gastos")
                            .font(.title3)
                            .fontWeight(.bold)
                        Chart(expenseData) { data in
                            SectorMark(
                                angle: .value("Amount", data.amount),
                                innerRadius: .ratio(0.5)
                            )
                        }
                        .frame(height: 200)
                    }
                    .padding()
                })
                .padding(.horizontal)
                
                // Savings Trend Line Chart
                CardView(content: {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tendencia de Ahorros")
                            .font(.title3)
                            .fontWeight(.bold)
                        Chart {
                            ForEach(savingsData) { data in
                                LineMark(
                                    x: .value("Mes", data.month),
                                    y: .value("Ahorros", data.amount)
                                )
                            }
                        }
                        .frame(height: 200)
                    }
                    .padding()
                })
                .padding(.horizontal)
                
                // Monthly Summary Bar Chart
                CardView(content: {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Resumen Mensual")
                            .font(.title3)
                            .fontWeight(.bold)
                        Chart {
                            BarMark(x: .value("Categoría", "Ingresos"), y: .value("Monto", 2000))
                            BarMark(x: .value("Categoría", "Gastos"), y: .value("Monto", 1500))
                            BarMark(x: .value("Categoría", "Ahorros"), y: .value("Monto", 500))
                        }
                        .frame(height: 200)
                    }
                    .padding()
                })
                .padding(.horizontal)
                
                // Export Report Button
                Button(action: {
                    // Action to export report
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text(Strings.Buttons.exportReport)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGray6))
    }
}

struct ReportsView_Previews: PreviewProvider {
    static var previews: some View {
        ReportsView()
    }
}
