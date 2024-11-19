//
//  AuthDataResultModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 18/11/24.
//

import Foundation
import FirebaseAuth

struct AuthDataResultModel {
    let uid: String
    let email: String?
    let name: String?
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email
        self.name = user.displayName
    }
}

enum AuthProviderOption: String {
    case email = "password"
    case apple = "apple.com"
}
