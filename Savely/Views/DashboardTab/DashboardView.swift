//
//  DashboardView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 16/10/24.
//

import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
                Text(Strings.DashboardTab.welcomeHeader)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.green)
                    .padding(.horizontal)
                
                // Overview Card
                VStack(spacing: 15) {
                    Text(Strings.DashboardTab.savingsSummaryTitle)
                        .font(.title3)
                        .fontWeight(.bold)
                    ZStack {
                        Circle()
                            .trim(from: 0, to: 0.75)
                            .stroke(Color.green, lineWidth: 8)
                            .frame(width: 160, height: 160)
                            .rotationEffect(.degrees(-90))
                        Text("75%")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    Text(Strings.DashboardTab.monthlyGoalLabel)
                        .font(.subheadline)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: UIConstants.UIShadow.shadow)
                .padding(.horizontal)

                // Quick Actions
                HStack() {
                    QuickActionButton(
                        iconName: "creditcard.fill",
                        label: Strings.Buttons.addIncomeButton,
                        action: viewModel.addIncomeAction
                    )
//                    Spacer()
//                    QuickActionButton(
//                        iconName: "camera.fill",
//                        label: Strings.Buttons.addExpenseButton,
//                        action: viewModel.addExpenseAction
//                    )
//                    Spacer()
//                    QuickActionButton(
//                        iconName: "plus.circle.fill",
//                        label: Strings.Buttons.newGoalButton,
//                        action: viewModel.newGoalAction
//                    )
                }
                .padding(.horizontal)

                // Weekly Spending Chart
//                VStack(alignment: .leading, spacing: 10) {
//                    Text(Strings.DashboardTab.weeklyExpensesTitle)
//                        .font(.title3)
//                        .fontWeight(.bold)
//                    Chart {
//                        BarMark(
//                            x: .value("Día", "Lun"),
//                            y: .value("Gasto", 20)
//                        )
//                        BarMark(
//                            x: .value("Día", "Mar"),
//                            y: .value("Gasto", 45)
//                        )
//                        BarMark(
//                            x: .value("Día", "Mié"),
//                            y: .value("Gasto", 28)
//                        )
//                        BarMark(
//                            x: .value("Día", "Jue"),
//                            y: .value("Gasto", 80)
//                        )
//                        BarMark(
//                            x: .value("Día", "Vie"),
//                            y: .value("Gasto", 99)
//                        )
//                        BarMark(
//                            x: .value("Día", "Sáb"),
//                            y: .value("Gasto", 43)
//                        )
//                        BarMark(
//                            x: .value("Día", "Dom"),
//                            y: .value("Gasto", 50)
//                        )
//                    }
//                    .frame(height: 200)
//                }
//                .padding()
//                .frame(maxWidth: .infinity)
//                .background(Color.white)
//                .cornerRadius(10)
//                .shadow(radius: 2)
//                .padding(.horizontal)

                // Tip of the Day Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.blue)
                        Text(Strings.DashboardTab.tipOfTheDayTitle)
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    Text("Establece metas pequeñas y alcanzables. ¡El éxito en pequeños objetivos te motivará a lograr metas más grandes!")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
                .shadow(radius: UIConstants.UIShadow.shadow)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGray6))
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
