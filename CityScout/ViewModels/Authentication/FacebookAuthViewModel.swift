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
    @Published var userEmail: String?
    @Published var signedInUser: SignedInUser? 

    // Firebase Auth State Listener (optional, but good for consistency)
    private var authStateHandler: AuthStateDidChangeListenerHandle?

    init() {
        setupAuthStateListener()
    }

    deinit {
        if let handle = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    private func setupAuthStateListener() {
        if authStateHandler == nil {
            authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
                guard let self = self else { return }
                if let firebaseUser = user, firebaseUser.providerData.contains(where: { $0.providerID == FacebookAuthProviderID }) {
                    // Only update signedInUser if it's the *current* user signed in with Facebook
                    self.signedInUser = SignedInUser(
                        id: firebaseUser.uid,
                        displayName: firebaseUser.displayName,
                        email: firebaseUser.email ?? "(unknown email)"
                    )
                } else if self.signedInUser != nil {
                    // If the user signed out, or switched to a different provider
                    self.signedInUser = nil
                }
            }
        }
    }


    func signInWithFacebook() async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = ""
            userEmail = nil // Clear previous email on new attempt
            signedInUser = nil // Clear previous user
        }

        // Check if there's an existing access token and valid permissions
        if let accessToken = AccessToken.current, !accessToken.isExpired {
            if accessToken.permissions.contains("email") {
                print("Facebook: Already logged in with valid token and email permission.")
                return await authenticateFirebaseWithFacebook(accessToken: accessToken.tokenString)
            } else {
                print("Facebook: Existing token, but email permission missing. Re-attempting login.")
            }
        }

        return await withCheckedContinuation { continuation in
            let loginManager = LoginManager()

            // Request permissions during login.
            loginManager.logIn(permissions: ["public_profile", "email"], from: nil) { [weak self] result, error in
                guard let self = self else { return }
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

                    if result.declinedPermissions.contains("email") {
                        self.errorMessage = "Facebook: Email permission was declined. Some app functionality might be limited."
                        print("Facebook: Email permission was explicitly declined by the user.")
                    }

                    guard let accessToken = result.token?.tokenString else {
                        self.errorMessage = "Facebook access token not found."
                        print("Facebook access token not found.")
                        continuation.resume(returning: false)
                        return
                    }

                    let firebaseAuthSuccess = await self.authenticateFirebaseWithFacebook(accessToken: accessToken)

                    if firebaseAuthSuccess && result.grantedPermissions.contains("email") {
                        self.fetchFacebookUserEmail()
                    } else if firebaseAuthSuccess {
                        // If Firebase auth was successful but email wasn't granted or fetched,
                        // ensure signedInUser is populated based on Firebase user
                        if let firebaseUser = Auth.auth().currentUser {
                            self.signedInUser = SignedInUser(
                                id: firebaseUser.uid,
                                displayName: firebaseUser.displayName,
                                email: firebaseUser.email ?? "(unknown email)"
                            )
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
            Auth.auth().signIn(with: credential) { [weak self] authResult, firebaseError in
                guard let self = self else { return }
                Task { @MainActor in
                    if let firebaseError = firebaseError {
                        self.errorMessage = "Firebase Facebook Auth Error: \(firebaseError.localizedDescription)"
                        print("Firebase Facebook Auth Error: \(firebaseError.localizedDescription)")
                        self.signedInUser = nil
                        continuation.resume(returning: false)
                    } else {
                        print("Successfully signed in with Facebook and Firebase!")
                        if let firebaseUser = authResult?.user {
                             self.signedInUser = SignedInUser(
                                id: firebaseUser.uid,
                                displayName: firebaseUser.displayName,
                                email: firebaseUser.email ?? "(unknown email)"
                            )
                        }
                        continuation.resume(returning: true)
                    }
                }
            }
        }
    }

    private func fetchFacebookUserEmail() {
        print("Attempting to fetch Facebook user email...")
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
                    // Update the signedInUser email if it's a new email or more accurate
                    if var currentUser = self.signedInUser {
                        currentUser.email = email
                        self.signedInUser = currentUser
                    }
                    print("Fetched Facebook user email: \(email)")
                } else {
                    self.errorMessage = "Facebook email not found in profile data or permission not granted."
                    print("Facebook email not found in profile data or permission not granted.")
                }
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            LoginManager().logOut() // Facebook SDK logout
            self.signedInUser = nil
            self.errorMessage = ""
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
