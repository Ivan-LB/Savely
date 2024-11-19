//
//  DBUserModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 18/11/24.
//

import Foundation

struct DBUserModel {
    let userId: String
    let email: String?
    let displayName: String?
    let isOnboardingComplete: Bool?
    let dateCreated: Date?
}
