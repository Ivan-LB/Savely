//
//  Achievement.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 07/11/24.
//

import Foundation

struct AchievementModel: Identifiable {
    let id: Int
    let title: String
    let description: String
    let iconName: String
    let achieved: Bool
}
