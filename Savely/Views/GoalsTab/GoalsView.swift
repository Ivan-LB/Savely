//
//  GoalsView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 16/10/24.
//

import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = GoalsViewModel()
    @FocusState private var focusedField: GoalField?
    
    enum GoalField: Hashable {
        case name
        case amount
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Add New Goal Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Add New Goal")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    // Goal Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal Name")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        
                        TextField(Strings.GoalsView.goalNamePlaceholder, text: $viewModel.name)
                            .font(.body)
                            .padding(14)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .focused($focusedField, equals: .name)
                    }
                    
                    // Target Amount & Color Row
                    HStack(spacing: 12) {
                        // Target Amount
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Amount")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            
                            HStack {
                                Text("$")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 14)
                                
                                TextField("0.00", text: $viewModel.targetAmount)
                                    .font(.body)
                                    .keyboardType(.decimalPad)
                                    .focused($focusedField, equals: .amount)
                                    .padding(.vertical, 14)
                                    .padding(.trailing, 14)
                            }
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Color Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Color")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            
                            Menu {
                                ForEach(GoalColor.allCases) { color in
                                    Button(action: {
                                        viewModel.selectedColor = color
                                    }) {
                                        HStack {
                                            Circle()
                                                .fill(color.color)
                                                .frame(width: 20, height: 20)
                                            Text(color.rawValue.capitalized)
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(viewModel.selectedColor.color)
                                        .frame(width: 24, height: 24)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(14)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        .frame(width: 100)
                    }
                    
                    // Create Goal Button
                    Button(action: {
                        viewModel.addGoal()
                        focusedField = nil
                    }) {
                        Text("Create Goal")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.3, green: 0.5, blue: 0.4))
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.modelContext == nil)
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.horizontal)
                .padding(.top)

                // Active Goals Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Active Goals")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            // Navigate to all goals
                        }) {
                            Text("View All")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color(red: 0.3, green: 0.5, blue: 0.4))
                        }
                    }
                    .padding(.horizontal)
                    
                    if viewModel.goals.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "target")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No goals yet")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Create your first goal to get started")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(viewModel.goals) { goal in
                                GoalCardView(
                                    goal: goal,
                                    onFavoriteToggle: {
                                        viewModel.setFavorite(goal: goal)
                                    },
                                    onDelete: {
                                        viewModel.deleteGoal(goal)
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
                print("Setting modelContext in viewModel")
                viewModel.setModelContext(modelContext)
            }
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(title: Text(Strings.Errors.errorLabel), message: Text(viewModel.errorMessage), dismissButton: .default(Text(Strings.Buttons.okButton)))
        }
    }
}
// MARK: - Goal Card Component
struct GoalCardView: View {
    let goal: GoalModel
    let onFavoriteToggle: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header: Icon, Name, and Favorite Star
            HStack(spacing: 12) {
                // Icon with color background
                ZStack {
                    Circle()
                        .fill(goal.color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: goalIcon)
                        .font(.system(size: 24))
                        .foregroundStyle(goal.color)
                }
                
                // Goal Name and Target Date
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text(targetDateText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Favorite Star
                Button(action: onFavoriteToggle) {
                    Image(systemName: goal.isFavorite ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundStyle(goal.isFavorite ? .yellow : .gray)
                }
            }
            
            // Progress Section
            VStack(spacing: 8) {
                HStack {
                    Text("$\(Int(goal.current)) / $\(Int(goal.target))")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(goal.progress * 100))%")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(goal.color)
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray6))
                            .frame(height: 8)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 6)
                            .fill(goal.color)
                            .frame(width: geometry.size.width * goal.progress, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .contextMenu {
            Button(role: .destructive, action: {
                showDeleteConfirmation = true
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog("Delete Goal", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this goal?")
        }
    }
    
    private var goalIcon: String {
        let name = goal.name.lowercased()
        
        if name.contains("car") || name.contains("tesla") || name.contains("vehicle") || name.contains("auto") {
            return "car.fill"
        } else if name.contains("vacation") || name.contains("trip") || name.contains("travel") || name.contains("bali") || name.contains("summer") {
            return "airplane"
        } else if name.contains("house") || name.contains("home") || name.contains("apartment") || name.contains("down payment") {
            return "house.fill"
        } else if name.contains("wedding") || name.contains("marriage") {
            return "heart.fill"
        } else if name.contains("education") || name.contains("school") || name.contains("college") {
            return "graduationcap.fill"
        } else if name.contains("emergency") || name.contains("savings") {
            return "shield.fill"
        } else if name.contains("phone") || name.contains("iphone") || name.contains("laptop") || name.contains("computer") {
            return "laptopcomputer"
        } else {
            return "dollarsign.circle.fill"
        }
    }
    
    private var targetDateText: String {
        // Calculate estimated completion date based on current progress
        // For now, using a placeholder
        let calendar = Calendar.current
        let futureDate = calendar.date(byAdding: .month, value: 6, to: Date()) ?? Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return "Targeting \(formatter.string(from: futureDate))"
    }
}

#Preview {
    GoalsView()
}

