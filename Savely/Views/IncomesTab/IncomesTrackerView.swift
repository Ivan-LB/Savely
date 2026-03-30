//
//  IncomesTrackerView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 05/11/24.
//

import SwiftUI
import SwiftData

struct IncomesTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = IncomesTrackerViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Total Income Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Income This Month")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Text(String(format: "$%.2f", viewModel.totalIncomeThisMonth))
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                        Text(String(format: "+%.1f%% from last month", viewModel.percentageChange))
                            .font(.subheadline)
                    }
                    .foregroundStyle(.white.opacity(0.9))
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.3, green: 0.5, blue: 0.4), Color(red: 0.25, green: 0.45, blue: 0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                .padding(.top)

                // Add New Income Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Add New Income")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("DESCRIPTION")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            
                            TextField("e.g., Freelance Project", text: $viewModel.incomeDescription)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("AMOUNT")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                Text("$")
                                    .foregroundStyle(.secondary)
                                TextField("0.00", text: $viewModel.amount)
                                    .keyboardType(.decimalPad)
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                    
                    Button(action: {
                        viewModel.addIncome()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text("Add Income")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.3, green: 0.5, blue: 0.4), Color(red: 0.25, green: 0.45, blue: 0.35)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
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
                        Spacer()
                        Button("See All") {
                            // Action for see all
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 0.3, green: 0.5, blue: 0.4))
                    }
                    
                    if viewModel.incomes.isEmpty {
                        Text("No recent activity")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    } else {
                        ForEach(viewModel.incomes.prefix(10)) { income in
                            IncomeActivityRow(income: income) {
                                viewModel.deleteIncome(income)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            if viewModel.modelContext == nil {
                viewModel.setModelContext(modelContext)
            }
        }
    }
}

struct IncomeActivityRow: View {
    let income: IncomeModel
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 48, height: 48)
                
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(iconColor)
            }
            
            // Description and Date
            VStack(alignment: .leading, spacing: 4) {
                Text(income.incomeDescription)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(formatDateTime(income.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Amount and Status
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "+$%.2f", income.amount))
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 0.2, green: 0.6, blue: 0.3))
                
                Text("COMPLETED")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color(red: 0.2, green: 0.6, blue: 0.3).opacity(0.7))
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .contextMenu {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Income", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this income?")
        }
    }
    
    private var iconName: String {
        let description = income.incomeDescription.lowercased()
        
        if description.contains("salary") || description.contains("monthly") {
            return "briefcase.fill"
        } else if description.contains("freelance") || description.contains("design") || description.contains("project") {
            return "paintbrush.fill"
        } else if description.contains("stock") || description.contains("dividend") || description.contains("investment") {
            return "building.columns.fill"
        } else if description.contains("sale") || description.contains("marketplace") || description.contains("sell") {
            return "tag.fill"
        } else {
            return "dollarsign.circle.fill"
        }
    }
    
    private var iconColor: Color {
        Color(red: 0.3, green: 0.5, blue: 0.4)
    }
    
    private var iconBackgroundColor: Color {
        Color(red: 0.3, green: 0.5, blue: 0.4).opacity(0.15)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy • hh:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    IncomesTrackerView()
}
