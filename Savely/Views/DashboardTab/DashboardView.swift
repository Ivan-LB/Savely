//
//  DashboardView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 16/10/24.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query var goals: [GoalModel]
    @Environment(\.modelContext) private var modelContext
    @StateObject private var tipsViewModel = TipsAndSuggestionViewModel()
    
    var favoriteGoal: GoalModel? {
        return goals.first(where: { $0.isFavorite })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Welcome Header
                VStack(spacing: 8) {
                    Text("Welcome to Savely")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color(red: 0.3, green: 0.5, blue: 0.4))
                    
                    Text("Your financial health is looking good today.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top)
                
                // Active Goal Card
                if let goal = favoriteGoal {
                    ActiveGoalCardView(goal: goal)
                        .padding(.horizontal)
                } else {
                    NoActiveGoalCardView()
                        .padding(.horizontal)
                }
                
                // Carousel for Tips and Reports
                DashboardCarouselView(tipsViewModel: tipsViewModel)
                    .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            if tipsViewModel.modelContext == nil {
                tipsViewModel.setModelContext(modelContext)
            }
        }
    }
}

// MARK: - Active Goal Card
struct ActiveGoalCardView: View {
    let goal: GoalModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Spacer()
                
                Text("ACTIVE GOAL")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            // Circular Progress
            ZStack {
                // Background Circle
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                // Progress Circle
                Circle()
                    .trim(from: 0, to: goal.progress)
                    .stroke(
                        Color(red: 0.3, green: 0.5, blue: 0.4),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: goal.progress)
                
                // Percentage Text
                VStack(spacing: 4) {
                    Text("\(Int(goal.progress * 100))%")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(Color(red: 0.3, green: 0.5, blue: 0.4))
                    
                    Text("of $\(formattedAmount(goal.target))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 20)
            
            // Goal Name and Remaining
            VStack(spacing: 8) {
                Text(goal.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(red: 0.3, green: 0.5, blue: 0.4))
                        .frame(width: 6, height: 6)
                    
                    Text("$\(formattedAmount(goal.target - goal.current)) to go")
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 0.3, green: 0.5, blue: 0.4))
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private func formattedAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }
}

// MARK: - No Active Goal Card
struct NoActiveGoalCardView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("ACTIVE GOAL")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                Image(systemName: "target")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                Text("No Active Goal")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text("Set a goal to track your progress")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Dashboard Carousel
struct DashboardCarouselView: View {
    @ObservedObject var tipsViewModel: TipsAndSuggestionViewModel
    @State private var currentIndex: Int = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Carousel Content
            TabView(selection: $currentIndex) {
                // Tip Card
                DashboardTipCardView(viewModel: tipsViewModel)
                    .tag(0)
                
                // Report Card
                DashboardReportCardView()
                    .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 380)
            
            // Custom Page Indicators
            HStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { index in
                    Circle()
                        .fill(currentIndex == index ? Color(red: 0.3, green: 0.5, blue: 0.4) : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentIndex)
                }
            }
        }
    }
}

// MARK: - Dashboard Tip Card
struct DashboardTipCardView: View {
    @ObservedObject var viewModel: TipsAndSuggestionViewModel
    @State private var isDismissed = false
    
    var body: some View {
        if !isDismissed, let tip = viewModel.currentTip {
            VStack(alignment: .leading, spacing: 20) {
                // Header with Icon
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.3, green: 0.5, blue: 0.4))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    }
                    
                    Text("Savely AI Tip")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(red: 0.3, green: 0.5, blue: 0.4))
                    
                    Spacer()
                }
                
                // Tip Content
                Text(tip.content)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(5)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            .padding(.horizontal)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                Text("No tips available")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            .padding(.horizontal)
        }
    }
}

// MARK: - Dashboard Report Card
struct DashboardReportCardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ReportsViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title3)
                        .foregroundStyle(Color(red: 0.3, green: 0.5, blue: 0.4))
                    
                    Text("Reports")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(currentMonthYear)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Simple Bar Chart
            HStack(alignment: .bottom, spacing: 40) {
                BarChartColumn(
                    title: "INCOME",
                    amount: totalIncome,
                    color: Color(.systemGray4),
                    maxAmount: maxAmount
                )
                
                BarChartColumn(
                    title: "SPENDING",
                    amount: totalExpenses,
                    color: Color(red: 0.3, green: 0.5, blue: 0.4),
                    maxAmount: maxAmount
                )
                
                BarChartColumn(
                    title: "SAVINGS",
                    amount: totalIncome - totalExpenses,
                    color: Color(.systemGray4),
                    maxAmount: maxAmount
                )
            }
            .frame(height: 160)
            .padding(.vertical, 20)
            
            Divider()
            
            // Net Flow
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NET FLOW")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("+$\(String(format: "%.2f", totalIncome - totalExpenses))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Button(action: {
                    // Navigate to detailed reports
                }) {
                    HStack(spacing: 4) {
                        Text("Details")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundStyle(Color(red: 0.3, green: 0.5, blue: 0.4))
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
        .onAppear {
            if viewModel.modelContext == nil {
                viewModel.setModelContext(modelContext)
            }
        }
    }
    
    private var totalIncome: Double {
        viewModel.weeklyIncomes.reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpenses: Double {
        viewModel.weeklyExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var maxAmount: Double {
        max(totalIncome, totalExpenses, totalIncome - totalExpenses, 100)
    }
    
    private var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: Date()).uppercased()
    }
}

// MARK: - Bar Chart Column
struct BarChartColumn: View {
    let title: String
    let amount: Double
    let color: Color
    let maxAmount: Double
    
    var body: some View {
        VStack(spacing: 8) {
            // Bar
            ZStack(alignment: .bottom) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(height: 140)
                
                // Filled portion
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(height: barHeight)
            }
            .frame(maxWidth: .infinity)
            
            // Label
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private var barHeight: CGFloat {
        guard maxAmount > 0 else { return 0 }
        let ratio = amount / maxAmount
        return CGFloat(ratio) * 140
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
