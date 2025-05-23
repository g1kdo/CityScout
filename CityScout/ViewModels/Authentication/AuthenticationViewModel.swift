//
//  AuthenticationViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 07/05/2025.
//

import Foundation
import FirebaseAuth
import SwiftUI

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage = ""
    @Published var successMessage = ""
    @Published var showAlert: Bool = false
    @Published var isAuthenticating = false
    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var signedInUser: SignedInUser? // Custom app-specific user object

    private var authStateHandler: AuthStateDidChangeListenerHandle?

    init() {
        registerAuthStateHandler()
    }

    // Don't forget to invalidate the handler when the ViewModel is deinitialized
    deinit {
        if let handle = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    private func registerAuthStateHandler() {
        if authStateHandler == nil {
            authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                guard let self = self else { return }
                self.user = user
                self.isAuthenticated = user != nil
                // Map Firebase User to your SignedInUser if needed
                if let firebaseUser = user {
                    self.signedInUser = SignedInUser(
                        id: firebaseUser.uid,
                        displayName: firebaseUser.displayName,
                        email: firebaseUser.email ?? "(unknown email)"
                    )
                } else {
                    self.signedInUser = nil
                }
            }
        }
    }

    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            showAlert = true // Show alert for validation error
            return
        }

        isAuthenticating = true
        errorMessage = "" // Clear previous error
        successMessage = "" // Clear previous success

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            user = result.user
            isAuthenticated = true
            successMessage = "Signed in successfully! Welcome back." // Set success message
            showAlert = true // Show success alert
        } catch {
            errorMessage = getAuthErrorMessage(error: error) // Use helper for user-friendly messages
            showAlert = true // Show error alert
            isAuthenticated = false
        }

        isAuthenticating = false
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            user = nil
            signedInUser = nil
            successMessage = "You have been signed out."
            showAlert = true
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // Helper to get more user-friendly Firebase Auth error messages
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
            // Add more cases as needed for specific AuthErrorCode values
            default:
                return "Sign in failed: \(error.localizedDescription)"
            }
        }
        return "An unknown error occurred during sign in."
    }
}
