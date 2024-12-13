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
                    .foregroundStyle(Color("primaryGreen"))
                    .padding(.horizontal)

                // Overview Card
                VStack(spacing: 15) {
                    Text(Strings.DashboardTab.savingsSummaryTitle)
                        .font(.title3)
                        .fontWeight(.bold)
                    if let goal = favoriteGoal {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                                .frame(width: 160, height: 160)
                            Circle()
                                .trim(from: 0, to: goal.progress)
                                .stroke(goal.color, lineWidth: 8)
                                .frame(width: 160, height: 160)
                                .rotationEffect(.degrees(-90))
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
                .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
                .shadow(radius: UIConstants.UIShadow.shadow)
                .padding(.horizontal)
                
                ReportsView()
                    .padding(.horizontal)
                
                TipsAndSuggestionsView()
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color("backgroundColor"))
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
