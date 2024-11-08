//
//  AchievementsView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 07/11/24.
//

import SwiftUI

struct AchievementsView: View {
    let achievements = [
        Achievement(id: 1, title: "Primera Meta Alcanzada", description: "Has alcanzado tu primera meta de ahorro.", iconName: "star.fill", achieved: true),
        Achievement(id: 2, title: "Tres Metas Alcanzadas", description: "Has alcanzado tres metas de ahorro diferentes.", iconName: "trophy.fill", achieved: false),
        Achievement(id: 3, title: "Ahorro Mensual Consistente", description: "Has mantenido un ahorro mensual constante durante tres meses.", iconName: "calendar.circle.fill", achieved: true),
        Achievement(id: 4, title: "Sin Gastos Innecesarios", description: "Has evitado gastos innecesarios durante un mes completo.", iconName: "checkmark.seal.fill", achieved: false),
    ]
    
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
