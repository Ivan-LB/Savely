//
//  UserManager.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 18/11/24.
//

import Foundation
import FirebaseFirestore

final class UserManager {
    
    static let shared = UserManager()
    private init() { }
    
    func createNewUser(auth: AuthDataResultModel, displayName: String?) async throws {
        var userData: [String: Any] = [
            "user_id": auth.uid,
            "date_created": Timestamp(),
            "isOnboardingComplete": false
        ]
        if let email = auth.email {
            userData["email"] = email
        }
        if let displayName = displayName, !displayName.isEmpty {
            userData["display_name"] = displayName
        }
        try await Firestore.firestore().collection("users").document(auth.uid).setData(userData, merge: false)
    }
    
    func getUser(userId: String) async throws -> DBUserModel{
        let snapshot = try await Firestore.firestore().collection("users").document(userId).getDocument()
        
        guard let data = snapshot.data(), let userId = data["user_id"] as? String  else {
            throw URLError(.badServerResponse)
        }
        let email = data["email"] as? String
        let displayName = data["display_name"] as? String
        let isOnboardingComplete = data["is_onboarding_complete"] as? Bool
        let dateCreated = data["date_created"] as? Date
        
        return DBUserModel(userId: userId, email: email, displayName: displayName, isOnboardingComplete: isOnboardingComplete, dateCreated: dateCreated)
    }
    
    func updateOnboardingStatus(isComplete: Bool) async throws {
        guard let uid = AuthenticationManager.shared.currentUser?.uid else { return }
        let docRef = Firestore.firestore().collection("users").document(uid)
        try await docRef.updateData(["isOnboardingComplete": isComplete])
    }
}
