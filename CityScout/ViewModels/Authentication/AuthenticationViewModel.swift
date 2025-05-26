//
//  AuthenticationViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 07/05/2025.
//

import Foundation
import FirebaseAuth
import SwiftUI
import FirebaseFirestore

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage = ""
    @Published var successMessage = ""
    @Published var showAlert: Bool = false
    @Published var isAuthenticating = false
    @Published var isAuthenticated = false
    @Published var user: User? // Firebase User object
    @Published var signedInUser: SignedInUser? // Your custom app-specific user object

    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private var db = Firestore.firestore() // Firestore instance

    init() {
        registerAuthStateHandler()
        // Immediately try to check for an existing user on initialization
        Task { await checkCurrentUser() }
    }

    deinit {
        if let handle = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    private func registerAuthStateHandler() {
        if authStateHandler == nil {
            authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
                guard let self = self else { return }
                self.user = firebaseUser
                self.isAuthenticated = firebaseUser != nil

                // Attempt to create/update SignedInUser from Firebase user
                if let fbUser = firebaseUser {
                    Task {
                        do {
                            self.signedInUser = try await self.createSignedInUser(from: fbUser)
                            print("AuthenticationViewModel: SignedInUser updated for: \(self.signedInUser?.email ?? "N/A")")
                        } catch {
                            print("AuthenticationViewModel: Error creating SignedInUser from Firebase user: \(error.localizedDescription)")
                            self.signedInUser = nil // Clear if there's an error
                        }
                    }
                } else {
                    self.signedInUser = nil // No Firebase user, no SignedInUser
                }
            }
        }
    }

    // Function to create a SignedInUser from a Firebase.User object and fetch Firestore data
    func createSignedInUser(from firebaseUser: FirebaseAuth.User) async throws -> SignedInUser {
        var user = SignedInUser(
            id: firebaseUser.uid,
            displayName: firebaseUser.displayName,
            email: firebaseUser.email ?? "",
            profilePictureURL: firebaseUser.photoURL
        )

        // Attempt to fetch additional profile data from Firestore
        let docRef = db.collection("users").document(firebaseUser.uid)
        do {
            let document = try await docRef.getDocument()
            if document.exists {
                let data = document.data() ?? [:]
                user.updateWithProfileData(data) // Assume SignedInUser has this method

                // Override displayName if firstName and lastName are available in Firestore
                if let firstName = user.firstName, !firstName.isEmpty {
                    let lastName = user.lastName ?? ""
                    user.displayName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        } catch {
            print("Error fetching additional user data from Firestore: \(error.localizedDescription)")
            // Continue even if Firestore fetch fails, as user might still be logged in.
        }
        return user
    }

    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            showAlert = true
            return
        }

        isAuthenticating = true
        errorMessage = ""
        successMessage = ""

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            // The authStateHandler will pick up result.user and update signedInUser
            successMessage = "Signed in successfully! Welcome back."
            showAlert = true
        } catch {
            errorMessage = getAuthErrorMessage(error: error)
            showAlert = true
        }
        isAuthenticating = false
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            // The authStateHandler will clear `user` and `signedInUser`
            successMessage = "You have been signed out."
            showAlert = true
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // Helper to check for existing user on app launch
    func checkCurrentUser() async {
        if let firebaseUser = Auth.auth().currentUser {
            isAuthenticating = true
            do {
                self.signedInUser = try await createSignedInUser(from: firebaseUser)
                self.isAuthenticated = true
                print("AuthenticationViewModel: Existing user loaded from Firebase Auth and Firestore.")
            } catch {
                print("AuthenticationViewModel: Failed to load existing user data: \(error.localizedDescription)")
                self.signedInUser = nil
                self.isAuthenticated = false
                try? Auth.auth().signOut() // Force sign out if data load fails
            }
            isAuthenticating = false
        } else {
            self.signedInUser = nil
            self.isAuthenticated = false
        }
    }

    private func getAuthErrorMessage(error: Error) -> String {
        if let errorCode = AuthErrorCode(rawValue: (error as NSError).code) {
            switch errorCode {
            case .userNotFound:
                return "No account found with this email. Please check your email or sign up."
            case .wrongPassword:
                return "Incorrect password. Please try again."
            case .invalidEmail:
                return "The email address is not valid."
            case .networkError:
                return "Network error. Please check your internet connection."
            case .userDisabled:
                return "Your account has been disabled. Please contact support."
            default:
                return "Sign in failed: \(error.localizedDescription)"
            }
        }
        return "An unknown error occurred during sign in."
    }
}
