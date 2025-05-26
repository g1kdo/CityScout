//
//  FacebookAuthViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 20/05/2025.
//

import Foundation
import FirebaseAuth
import FBSDKLoginKit
import FacebookCore

@MainActor
class FacebookAuthViewModel: ObservableObject {
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    // Removed: @Published var userEmail: String?
    // Removed: @Published var signedInUser: SignedInUser?
    // Removed: private var authStateHandler: AuthStateDidChangeListenerHandle?
    // Removed: init() and deinit() as they are no longer needed for authStateListener here

    func signInWithFacebook() async -> FirebaseAuth.User? { // Returns Firebase User on success
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }

        // The Facebook SDK's LoginManager.logIn handles token expiration and permissions.
        // We'll just initiate the login flow.
        return await performFacebookLogin()
    }

    private func performFacebookLogin() async -> FirebaseAuth.User? {
        return await withCheckedContinuation { continuation in
            let loginManager = LoginManager()

            // Request permissions during login.
            loginManager.logIn(permissions: ["public_profile", "email"], from: nil) { [weak self] result, error in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }

                Task { @MainActor in
                    self.isLoading = false

                    if let error = error {
                        self.errorMessage = "Facebook Login Error: \(error.localizedDescription)"
                        print("Facebook Login Error: \(error.localizedDescription)")
                        continuation.resume(returning: nil)
                        return
                    }

                    guard let result = result, !result.isCancelled else {
                        self.errorMessage = "Facebook login cancelled."
                        print("Facebook login cancelled.")
                        continuation.resume(returning: nil)
                        return
                    }

                    if result.declinedPermissions.contains("email") {
                        self.errorMessage = "Facebook: Email permission was declined. Some app functionality might be limited."
                        print("Facebook: Email permission was explicitly declined by the user.")
                    }

                    guard let accessToken = result.token?.tokenString else {
                        self.errorMessage = "Facebook access token not found."
                        print("Facebook access token not found.")
                        continuation.resume(returning: nil)
                        return
                    }

                    // Proceed to authenticate with Firebase
                    let firebaseUser = await self.authenticateFirebaseWithFacebook(accessToken: accessToken)
                    continuation.resume(returning: firebaseUser)
                }
            }
        }
    }

    private func authenticateFirebaseWithFacebook(accessToken: String) async -> FirebaseAuth.User? {
        await MainActor.run {
            errorMessage = "" // Clear error before Firebase auth attempt
        }
        let credential = FacebookAuthProvider.credential(withAccessToken: accessToken)

        do {
            let authResult = try await Auth.auth().signIn(with: credential)
            print("Successfully signed in with Facebook and Firebase!")
            return authResult.user // Return the Firebase User
        } catch {
            errorMessage = "Firebase Facebook Auth Error: \(error.localizedDescription)"
            print("Firebase Facebook Auth Error: \(error.localizedDescription)")
            return nil
        }
    }

    // Only log out from Facebook SDK, Firebase Auth will be handled by AuthenticationViewModel
    func signOutFacebookOnly() {
        LoginManager().logOut()
        print("Facebook account signed out from FBSDKLoginKit.")
    }
}
