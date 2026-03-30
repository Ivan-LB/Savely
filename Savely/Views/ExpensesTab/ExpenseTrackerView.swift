//
//  ExpenseTrackerView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 16/10/24.
//

import SwiftUI
import SwiftData

struct ExpenseTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ExpenseTrackerViewModel()
    @State private var showCameraView: Bool = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case description
        case amount
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Scan Receipt Button
                Button(action: {
                    showCameraView = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text(Strings.Buttons.scanReceiptButton)
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color("primaryYellow"))
                    .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.top)
                .sheet(isPresented: $showCameraView) {
                    let cameraViewModel = CameraViewModel(expenseViewModel: viewModel)
                    CameraView(viewModel: cameraViewModel)
                }

                // Add Expense Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("ADD EXPENSE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    // Description Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField(Strings.ExpenseTrackerTab.descriptionPlaceholderLabel, text: $viewModel.expenseDescription)
                            .font(.body)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .focused($focusedField, equals: .description)
                    }
                    
                    // Amount Field with Add Button
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amount")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                Text("$")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 12)
                                
                                TextField(Strings.ExpenseTrackerTab.amountPlaceholderLabel, text: $viewModel.amount)
                                    .font(.body)
                                    .keyboardType(.decimalPad)
                                    .focused($focusedField, equals: .amount)
                                    .padding(.vertical, 12)
                                    .padding(.trailing, 12)
                            }
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        
                        // Add Button
                        Button(action: {
                            viewModel.addExpense()
                            focusedField = nil
                        }) {
                            Image(systemName: "plus")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(Color(red: 0.3, green: 0.5, blue: 0.4))
                                .cornerRadius(16)
                        }
                        .padding(.top, 28)
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.horizontal)

                // Recent Activity Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Recent Activity")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            // Navigate to all expenses
                        }) {
                            Text("View All")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color(red: 0.3, green: 0.5, blue: 0.4))
                        }
                    }
                    .padding(.horizontal)
                    
                    if viewModel.expenses.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No expenses yet")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Add your first expense to get started")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(viewModel.expenses.prefix(10)) { expense in
                                ExpenseRowView(
                                    expense: expense,
                                    onDelete: {
                                        viewModel.deleteExpense(expense)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            if viewModel.modelContext == nil {
                viewModel.setModelContext(modelContext)
            }
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(title: Text(Strings.Errors.errorLabel), message: Text(viewModel.errorMessage), dismissButton: .default(Text(Strings.Buttons.okButton)))
        }
    }
}
// MARK: - Expense Row Component
struct ExpenseRowView: View {
    let expense: ExpenseModel
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon based on description
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 48, height: 48)
                
                Image(systemName: expenseIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color(red: 0.3, green: 0.5, blue: 0.4))
            }
            
            // Expense Details
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.expenseDescription)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Amount
            Text("-$\(String(format: "%.2f", expense.amount))")
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(.red)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .contextMenu {
            Button(role: .destructive, action: {
                showDeleteConfirmation = true
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog("Delete Expense", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this expense?")
        }
    }
    
    private var expenseIcon: String {
        let description = expense.expenseDescription.lowercased()
        
        if description.contains("food") || description.contains("restaurant") || description.contains("starbucks") || description.contains("coffee") {
            return "cup.and.saucer.fill"
        } else if description.contains("grocery") || description.contains("groceries") || description.contains("market") || description.contains("whole foods") {
            return "cart.fill"
        } else if description.contains("transport") || description.contains("uber") || description.contains("lyft") || description.contains("taxi") || description.contains("trip") {
            return "car.fill"
        } else if description.contains("entertainment") || description.contains("movie") || description.contains("game") {
            return "tv.fill"
        } else if description.contains("shopping") || description.contains("clothes") || description.contains("amazon") {
            return "bag.fill"
        } else if description.contains("health") || description.contains("medical") || description.contains("pharmacy") {
            return "cross.case.fill"
        } else if description.contains("chipotle") || description.contains("mexican") || description.contains("restaurant") {
            return "fork.knife"
        } else {
            return "dollarsign.circle.fill"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy • h:mm a"
        return formatter.string(from: expense.date)
    }
}

#Preview {
    ExpenseTrackerView()
}
