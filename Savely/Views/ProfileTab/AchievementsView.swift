//
//  AchievementsView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 07/11/24.
//

import SwiftUI

struct AchievementsView: View {
    let achievements = AchievementsData.allAchievements

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(achievements) { achievement in
                    HStack(spacing: 15) {
                        Image(systemName: achievement.iconName)
                            .font(.largeTitle)
                            .foregroundColor(achievement.achieved ? Color("primaryYellow") : .gray)

                        VStack(alignment: .leading) {
                            Text(achievement.title)
                                .font(.title3)
                                .fontWeight(.bold)
                            Text(achievement.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if achievement.achieved {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color("primaryGreen"))
                        }
                    }
                    .padding()
                    .background(Color("cardBackgroundColor"))
                    .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
                    .shadow(radius: UIConstants.UIShadow.shadowMedium)
                    .padding(.horizontal)
                    .opacity(achievement.achieved ? 1.0 : 0.5)
                }
            }
            .padding(.vertical)
        }
        .background(Color("backgroundColor"))
        .navigationTitle(Text(Strings.Achievements.title))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AchievementsView_Previews: PreviewProvider {
    static var previews: some View {
        AchievementsView()
            .environment(
                \ .colorScheme, .dark // Cambiar a .light para modo claro
            )
    }
}
