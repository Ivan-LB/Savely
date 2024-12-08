//
//  DashboardView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 16/10/24.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
//    @EnvironmentObject var viewModel: DashboardViewModel
    @Query var goals: [GoalModel]
    
    var favoriteGoal: GoalModel? {
        return goals.first(where: { $0.isFavorite })
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
                Text(Strings.DashboardTab.welcomeHeader)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.primaryGreen)
                    .padding(.horizontal)
                
                // Overview Card
                VStack(spacing: 15) {
                    Text(Strings.DashboardTab.savingsSummaryTitle)
                        .font(.title3)
                        .fontWeight(.bold)
                    if let goal = favoriteGoal {
                        ZStack {
                            // Círculo de fondo en gris
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                                .frame(width: 160, height: 160)
                            // Círculo de progreso en el color de la meta
                            Circle()
                                .trim(from: 0, to: goal.progress)
                                .stroke(goal.color, lineWidth: 8)
                                .frame(width: 160, height: 160)
                                .rotationEffect(.degrees(-90))
                            // Texto del porcentaje de progreso
                            Text("\(Int(goal.progress * 100))%")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        Text(goal.name)
                            .font(.subheadline)
                    } else {
                        Text(Strings.DashboardTab.noGoalsRecentlyLabel)
                            .font(.headline)
                            .padding()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color("cardBackgroundColor"))
                .cornerRadius(10)
                .shadow(radius: UIConstants.UIShadow.shadow)
                .padding(.horizontal)

                // Quick Actions
                HStack() {
                    QuickActionButton(
                        iconName: "creditcard.fill",
                        label: Strings.Buttons.addIncomeButton,
                        action: {
//                            viewModel.showAddIncome()
                        }
                    )
                    Spacer()
                    QuickActionButton(
                        iconName: "camera.fill",
                        label: Strings.Buttons.addExpenseButton,
                        action: {
//                            viewModel.showAddExpense()
                        }
                    )
                    Spacer()
                    QuickActionButton(
                        iconName: "plus.circle.fill",
                        label: Strings.Buttons.newGoalButton,
                        action: {
//                            viewModel.showAddGoal()
                        }
                    )
                }
                .padding(.horizontal)

                // Tip of the Day Card
                TipsAndSuggestionsView()
                    .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color("GeneralBackground"))
//        .sheet(isPresented: $viewModel.showingAddGoalModal) {
//            AddGoalView()
//                .environmentObject(viewModel.goalsViewModel)
//        }
//        .sheet(isPresented: $viewModel.showingAddIncomeModal) {
//            AddIncomeView()
//                .environmentObject(viewModel.incomesViewModel)
//        }
//        .sheet(isPresented: $viewModel.showingAddExpenseModal) {
//            AddExpenseView()
//                .environmentObject(viewModel.expensesViewModel)
//        }
    }
}

//struct DashboardContainerView: View {
//    @Environment(\.modelContext) private var modelContext
//    
//    var body: some View {
//        DashboardView()
//            .environmentObject(DashboardViewModel(modelContext: modelContext))
//    }
//}
