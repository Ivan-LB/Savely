//
//  UserManagerExtension.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 18/11/24.
//

import Foundation
import Firebase

extension UserManager {
    func updateUser(userId: String, displayName: String?, email: String?) async throws {
        let docRef = Firestore.firestore().collection("users").document(userId)
        var updateData: [String: Any] = [:]
        
        if let displayName = displayName, !displayName.isEmpty {
            updateData["display_name"] = displayName
        }
        if let email = email, !email.isEmpty {
            updateData["email"] = email
        }
        
        if !updateData.isEmpty {
            try await docRef.updateData(updateData)
        }
    }
}
