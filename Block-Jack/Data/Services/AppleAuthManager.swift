//
//  AppleAuthManager.swift
//  Block-Jack
//

import Foundation
import AuthenticationServices
import Combine

final class AppleAuthManager: NSObject, ObservableObject {
    static let shared = AppleAuthManager()
    
    @Published var isAuthenticated: Bool = false
    @Published var userId: String? = nil
    
    private override init() {
        super.init()
    }
    
    func performAppleLogin() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

extension AppleAuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            self.userId = appleIDCredential.user
            self.isAuthenticated = true
            print("Apple Sign In Success: \(appleIDCredential.user)")
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign In Error: \(error.localizedDescription)")
    }
}

extension AppleAuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first ?? UIWindow()
    }
}
