//
//  ExpenseTrackerView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 16/10/24.
//

import SwiftUI

struct ExpenseTrackerView: View {
    @State private var expenses = [
        ExpenseModel(id: 1, description: "Supermercado", amount: 50.75, date: "2023-05-15"),
        ExpenseModel(id: 2, description: "Gasolina", amount: 30.00, date: "2023-05-14")
    ]
    @State private var description = ""
    @State private var amount = ""
    @State private var showCameraView: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Upload Receipt Button
                Button(action: {
                    // Action to upload receipt photo
                    showCameraView = true
                }) {
                    HStack {
                        Image(systemName: "camera")
                            .foregroundColor(.white)
                            .font(.title)
                        Text(Strings.Buttons.scanReceiptButton)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .sheet(isPresented: $showCameraView) {
                    CameraView()
                }
                
                // Expense Form
                VStack(spacing: 15) {
                    TextField(Strings.ExpenseTrackerTab.descriptionPlaceholderLabel, text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField(Strings.ExpenseTrackerTab.amountPlaceholderLabel, text: $amount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: {
                        // Action to add a new expense
                        if let amountValue = Double(amount) {
                            let newExpense = ExpenseModel(id: expenses.count + 1, description: description, amount: amountValue, date: DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none))
                            expenses.append(newExpense)
                            description = ""
                            amount = ""
                        }
                    }) {
                        Text(Strings.Buttons.addExpenseButton)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 2)
                .padding(.horizontal)
                
                // Expense List
                VStack(alignment: .leading, spacing: 10) {
                    Text(Strings.ExpenseTrackerTab.recentExpensesTitle)
                        .font(.title3)
                        .fontWeight(.bold)
                    ForEach(expenses) { expense in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(expense.description)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text(expense.date)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text(String(format: "$%.2f", expense.amount))
                                .font(.headline)
                                .fontWeight(.bold)
                            Button(action: {
                                // Action to edit expense
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                            }
                            .padding(.leading, 10)
                            Button(action: {
                                // Action to delete expense
                                expenses.removeAll { $0.id == expense.id }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .padding(.leading, 10)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .border(Color.gray.opacity(0.2), width: 1)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 2)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGray6))
    }
}

struct ExpenseTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseTrackerView()
    }
}
