//
//  SignInWithAppleHelper.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 18/11/24.
//

import Foundation
import CryptoKit
import AuthenticationServices
import UIKit
import SwiftUI

struct SignInWithAppleButtonViewRepresentable: UIViewRepresentable {
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        ASAuthorizationAppleIDButton(authorizationButtonType: type, authorizationButtonStyle: style)
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) { }
}

struct SignInWithAppleResult {
    let token: String
    let nonce: String
    let name: String?
    let email: String?
}

final class SignInWithAppleHelper: NSObject {
    
    static let shared = SignInWithAppleHelper()
    private override init() { }
    
    private var completionHandler: ((Result<SignInWithAppleResult, Error>) -> Void)? = nil
    private var currentNonce: String? = nil
    
    /// Start Sign In With Apple and present OS modal.
    ///
    /// - Parameter viewController: ViewController to present OS modal on. If nil, function will attempt to find the top-most ViewController. Throws an error if no ViewController is found.
    @MainActor
    func startSignInWithAppleFlow(viewController: UIViewController? = nil) async throws -> SignInWithAppleResult {
        return try await withCheckedThrowingContinuation { continuation in
            startSignInWithAppleFlow { result in
                switch result {
                case .success(let signInWithAppleResult):
                    continuation.resume(returning: signInWithAppleResult)
                    return
                case .failure(let error):
                    continuation.resume(throwing: error)
                    return
                }
            }
        }
    }
    
    @MainActor
    func startSignInWithAppleFlow(viewController: UIViewController? = nil, completion: @escaping (Result<SignInWithAppleResult, Error>) -> Void) {
        guard let topVC = viewController ?? topViewController() else {
            completion(.failure(URLError(.cannotConnectToHost)))
            return
        }

        let nonce = randomNonceString()
        currentNonce = nonce
        completionHandler = completion
        showOSPrompt(nonce: nonce, on: topVC)
    }
    
}

// MARK: PRIVATE

private extension SignInWithAppleHelper {
        
    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError(
                        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                    )
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    private func showOSPrompt(nonce: String, on viewController: UIViewController) {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = viewController

        authorizationController.performRequests()
    }
    
    private enum SignInWithAppleError: LocalizedError {
        case invalidCredential
        case invalidState
        case unableToFetchToken
        case unableToSerializeToken
        case unableToFindNonce
        
        var errorDescription: String? {
            switch self {
            case .invalidCredential:
                return "Invalid credential: ASAuthorization failure."
            case .invalidState:
                return "Invalid state: A login callback was received, but no login request was sent."
            case .unableToFetchToken:
                return "Unable to fetch identity token"
            case .unableToSerializeToken:
                return "Unable to serialize token string from data"
            case .unableToFindNonce:
                return "Unable to find current nonce."
            }
        }
    }
    
    private func getTokenFromAuthorization(authorization: ASAuthorization) throws -> String {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw SignInWithAppleError.invalidCredential
        }

        guard let appleIDToken = appleIDCredential.identityToken else {
            throw SignInWithAppleError.unableToFetchToken
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw SignInWithAppleError.unableToSerializeToken
        }
        
        return idTokenString
    }
    
    private func getCurrentNonce() throws -> String {
        guard let currentNonce else {
            throw SignInWithAppleError.unableToFindNonce
        }
        return currentNonce
    }
    
    @MainActor
    private func topViewController(controller: UIViewController? = nil) -> UIViewController? {
        let controller = controller ?? UIApplication.shared.keyWindow?.rootViewController
        
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
    
}

extension SignInWithAppleHelper: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        do {
            let token = try getTokenFromAuthorization(authorization: authorization)
            let nonce = try getCurrentNonce()
            
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw SignInWithAppleError.invalidCredential
            }
            
            let fullName = appleIDCredential.fullName
            let name: String? = {
                guard let fullName = fullName else { return nil }
                let nameComponents = [fullName.givenName, fullName.familyName].compactMap { $0 }
                return nameComponents.isEmpty ? nil : nameComponents.joined(separator: " ")
            }()

            let email = appleIDCredential.email
            
            let result = SignInWithAppleResult(token: token, nonce: nonce, name: name, email: email)
            completionHandler?(.success(result))
        } catch {
            completionHandler?(.failure(error))
            return
        }
    }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completionHandler?(.failure(error))
        return
    }
}

extension UIViewController: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
