//
//  SignUpViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 07/05/2025.
//

import Foundation
import FirebaseAuth

@MainActor
class SignUpViewModel: ObservableObject {
    @Published var fullName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = "" // New property for success
    @Published var showAlert = false
    @Published var signedInUser: SignedInUser? = nil // Assuming SignedInUser is defined elsewhere

    func signUpUser() async {
        guard !fullName.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "All fields must be filled."
            showAlert = true // Show alert for validation error
            return
        }

        isLoading = true
        errorMessage = "" // Clear previous error
        successMessage = "" // Clear previous success

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let fbUser = result.user

            let profileChange = fbUser.createProfileChangeRequest()
            profileChange.displayName = fullName
            try await profileChange.commitChanges()

            signedInUser = SignedInUser(
                id: fbUser.uid,
                displayName: fullName,
                email: fbUser.email ?? "(unknown email)"
            )
            successMessage = "Account created successfully! Welcome \(fullName)." // Set success message
            showAlert = true // Show success alert
        } catch {
            errorMessage = getAuthErrorMessage(error: error) // Use helper to get user-friendly message
            showAlert = true // Show error alert
            signedInUser = nil
        }

        isLoading = false
    }

    // Helper to get more user-friendly Firebase Auth error messages
    private func getAuthErrorMessage(error: Error) -> String {
        if let errorCode = AuthErrorCode(rawValue: (error as NSError).code) {
            switch errorCode {
            case .emailAlreadyInUse:
                return "This email address is already in use. Please sign in or use a different email."
            case .invalidEmail:
                return "The email address is not valid."
            case .weakPassword:
                return "The password is too weak. Please use a stronger password (at least 6 characters)."
            // Add more cases as needed for specific AuthErrorCode values
            default:
                return "Sign up failed: \(error.localizedDescription)"
            }
        }
        return "An unknown error occurred during sign up."
    }
}
