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
                            .foregroundColor(achievement.achieved ? .yellow : .gray)
                        
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
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                    .opacity(achievement.achieved ? 1.0 : 0.5)
                }
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGray6))
    }
}

struct AchievementsView_Previews: PreviewProvider {
    static var previews: some View {
        AchievementsView()
    }
}
