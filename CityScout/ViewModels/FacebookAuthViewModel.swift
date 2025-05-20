//
//  FacebookAuthViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 20/05/2025.
//

import Foundation
import FirebaseAuth
import FBSDKLoginKit
import FacebookCore // Ensure this is imported for GraphRequest

class FacebookAuthViewModel: ObservableObject {
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var userEmail: String? // New property to store fetched email

    func signInWithFacebook() async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = ""
            userEmail = nil // Clear previous email on new attempt
        }

        // Check if there's an existing access token and valid permissions
        // This avoids re-prompting the user if they're already logged in
        if let accessToken = AccessToken.current, !accessToken.isExpired {
            // Already logged in with Facebook, check if email is granted
            if accessToken.permissions.contains("email") {
                print("Facebook: Already logged in with valid token and email permission.")
                // Attempt to sign in with Firebase using the existing token
                return await authenticateFirebaseWithFacebook(accessToken: accessToken.tokenString)
            } else {
                // Token exists but email permission is missing.
                // We'll proceed with loginManager.logIn to re-request if needed.
                print("Facebook: Existing token, but email permission missing. Re-attempting login.")
            }
        }

        return await withCheckedContinuation { continuation in
            let loginManager = LoginManager()

            // Request permissions during login.
            // Even with the "Invalid Scopes: email" warning, we still request it.
            // The SDK will decide if it grants it.
            loginManager.logIn(permissions: ["public_profile", "email"], from: nil) { result, error in
                Task { @MainActor in
                    self.isLoading = false

                    if let error = error {
                        self.errorMessage = "Facebook Login Error: \(error.localizedDescription)"
                        print("Facebook Login Error: \(error.localizedDescription)")
                        continuation.resume(returning: false)
                        return
                    }

                    guard let result = result, !result.isCancelled else {
                        self.errorMessage = "Facebook login cancelled."
                        print("Facebook login cancelled.")
                        continuation.resume(returning: false)
                        return
                    }

                    // Check for declined permissions
                    if result.declinedPermissions.contains("email") {
                        self.errorMessage = "Facebook: Email permission was declined. App functionality might be limited."
                        print("Facebook: Email permission was explicitly declined by the user.")
                        // You might choose to show a more specific alert or guide the user.
                        // For now, we'll continue the login process, as other permissions might be granted.
                    }

                    guard let accessToken = result.token?.tokenString else {
                        self.errorMessage = "Facebook access token not found."
                        print("Facebook access token not found.")
                        continuation.resume(returning: false)
                        return
                    }

                    // Proceed to authenticate with Firebase using the Facebook token
                    let firebaseAuthSuccess = await self.authenticateFirebaseWithFacebook(accessToken: accessToken)

                    if firebaseAuthSuccess {
                        // Optionally, fetch user email if it was granted.
                        // This uses Graph API and requires the 'email' permission.
                        // It's good practice to fetch only if needed and granted.
                        if result.grantedPermissions.contains("email") {
                            self.fetchFacebookUserEmail()
                        } else {
                            print("Facebook: Email permission not granted or explicitly declined, skipping email fetch.")
                        }
                    }
                    continuation.resume(returning: firebaseAuthSuccess)
                }
            }
        }
    }

    private func authenticateFirebaseWithFacebook(accessToken: String) async -> Bool {
        await MainActor.run {
            errorMessage = "" // Clear error before Firebase auth attempt
        }
        let credential = FacebookAuthProvider.credential(withAccessToken: accessToken)

        return await withCheckedContinuation { continuation in
            Auth.auth().signIn(with: credential) { authResult, firebaseError in
                Task { @MainActor in
                    if let firebaseError = firebaseError {
                        self.errorMessage = "Firebase Facebook Auth Error: \(firebaseError.localizedDescription)"
                        print("Firebase Facebook Auth Error: \(firebaseError.localizedDescription)")
                        continuation.resume(returning: false)
                    } else {
                        print("Successfully signed in with Facebook and Firebase!")
                        continuation.resume(returning: true)
                    }
                }
            }
        }
    }

    // New function to fetch user's email using Graph API
    private func fetchFacebookUserEmail() {
        print("Attempting to fetch Facebook user email...")
        // Request the 'email' field specifically
        let graphRequest = GraphRequest(graphPath: "me", parameters: ["fields": "email"], httpMethod: .get)
        graphRequest.start { [weak self] connection, result, error in
            guard let self = self else { return }

            Task { @MainActor in
                if let error = error {
                    self.errorMessage = "Failed to fetch Facebook user email: \(error.localizedDescription)"
                    print("Error fetching Facebook user email: \(error.localizedDescription)")
                    return
                }

                if let resultDict = result as? [String: Any], let email = resultDict["email"] as? String {
                    self.userEmail = email
                    print("Fetched Facebook user email: \(email)")
                } else {
                    self.errorMessage = "Facebook email not found in profile data."
                    print("Facebook email not found in profile data or permission not granted.")
                }
            }
        }
    }
}
