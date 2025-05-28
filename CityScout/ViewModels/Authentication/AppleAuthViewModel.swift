//
//  AppleAuthViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 07/05/2025.
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

@MainActor
class AppleAuthViewModel: NSObject, ObservableObject {
    @Published var errorMessage = ""
    @Published var isAuthenticating = false

    private var currentNonce: String?
    private var signInContinuation: CheckedContinuation<FirebaseAuth.User?, Error>?

    override init() {
        super.init()
    }

    func startSignInWithAppleFlow() async -> FirebaseAuth.User? {
        isAuthenticating = true
        errorMessage = ""

        do {
            return try await withCheckedThrowingContinuation { continuation in
                self.signInContinuation = continuation

                let request = ASAuthorizationAppleIDProvider().createRequest()
                request.requestedScopes = [.fullName, .email]

                let nonce = randomNonceString()
                currentNonce = nonce
                request.nonce = sha256(nonce)

                let authorizationController = ASAuthorizationController(authorizationRequests: [request])
                authorizationController.delegate = self
                authorizationController.presentationContextProvider = self
                authorizationController.performRequests()
            }
        } catch {
            self.errorMessage = error.localizedDescription
            self.isAuthenticating = false
            return nil
        }
    }

    // MARK: - ASAuthorizationControllerDelegate

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                let error = NSError(domain: "AppleAuthViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unexpected Apple credential type."])
                self.errorMessage = error.localizedDescription
                self.isAuthenticating = false
                self.signInContinuation?.resume(throwing: error)
                self.signInContinuation = nil
                return
            }

            guard let nonce = currentNonce else {
                let error = NSError(domain: "AppleAuthViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid state: a login callback was received, but no login request was sent."])
                self.errorMessage = error.localizedDescription
                self.isAuthenticating = false
                self.signInContinuation?.resume(throwing: error)
                self.signInContinuation = nil
                return
            }

            guard let appleIDToken = appleIDCredential.identityToken else {
                let error = NSError(domain: "AppleAuthViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token."])
                self.errorMessage = error.localizedDescription
                self.isAuthenticating = false
                self.signInContinuation?.resume(throwing: error)
                self.signInContinuation = nil
                return
            }

            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                let error = NSError(domain: "AppleAuthViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to serialize token string from data."])
                self.errorMessage = error.localizedDescription
                self.isAuthenticating = false
                self.signInContinuation?.resume(throwing: error)
                self.signInContinuation = nil
                return
            }

            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: idTokenString,
                rawNonce: nonce
            )

            do {
                let result = try await Auth.auth().signIn(with: credential)
                print("Successfully signed in with Apple and Firebase.")

                // **Attempt 1: Explicitly cast to Optional<User> (User?)**
                // This forces the compiler to see it as an Optional, even if it's getting confused.
                guard let firebaseUser = (result.user as FirebaseAuth.User?) else {
                    let error = NSError(domain: "AppleAuthViewModel", code: 4, userInfo: [NSLocalizedDescriptionKey: "Firebase user object is nil after successful Apple sign-in."])
                    self.errorMessage = error.localizedDescription
                    self.isAuthenticating = false
                    self.signInContinuation?.resume(throwing: error)
                    self.signInContinuation = nil
                    return
                }

                // Potentially update user's display name if it's their first time and Apple provided one
                if firebaseUser.displayName == nil || firebaseUser.displayName?.isEmpty == true {
                    if let givenName = appleIDCredential.fullName?.givenName, !givenName.isEmpty {
                        let changeRequest = firebaseUser.createProfileChangeRequest()
                        changeRequest.displayName = "\(givenName) \(appleIDCredential.fullName?.familyName ?? "")".trimmingCharacters(in: .whitespacesAndNewlines)
                        try await changeRequest.commitChanges()
                        print("Updated Firebase user display name from Apple credential.")
                    }
                }
                self.isAuthenticating = false
                self.signInContinuation?.resume(returning: firebaseUser)
                self.signInContinuation = nil

            } catch {
                self.errorMessage = error.localizedDescription
                print("Error signing in with Apple: \(error.localizedDescription)")
                self.isAuthenticating = false
                self.signInContinuation?.resume(throwing: error)
                self.signInContinuation = nil
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = error.localizedDescription
            print("Error occurred during Apple Sign-In: \(error.localizedDescription)")
            self.isAuthenticating = false

            if let signInContinuation = self.signInContinuation {
                if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                    signInContinuation.resume(returning: nil)
                } else {
                    signInContinuation.resume(throwing: error)
                }
                self.signInContinuation = nil
            }
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
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
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

extension AppleAuthViewModel: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {}
