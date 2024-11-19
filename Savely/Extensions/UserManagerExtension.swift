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
        var data: [String: Any] = [:]
        if let displayName = displayName {
            data["display_name"] = displayName
        }
        if let email = email {
            data["email"] = email
        }
        let userDocRef = Firestore.firestore().collection("users").document(userId)
        try await userDocRef.updateData(data)
    }
}
