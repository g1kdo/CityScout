//
//  SignUpViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 07/05/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class SignUpViewModel: ObservableObject {
    @Published var fullName = ""
    @Published var email = "" // Corrected 'var email' from 'var var email'
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    @Published var showAlert = false

    private var db = Firestore.firestore()

    func signUpUser() async -> FirebaseAuth.User? {
        defer {
            isLoading = false
        }

        guard !fullName.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "All fields must be filled."
            showAlert = true
            return nil
        }

        isLoading = true
        errorMessage = ""
        successMessage = ""

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)

            // FIX: Explicitly declare fbUser as Optional<User> and cast result.user
            // This forces the compiler to correctly treat it as an Optional.
            let fbUser: FirebaseAuth.User? = result.user as FirebaseAuth.User?

            guard let validFbUser = fbUser else { // This is line 46 now (approx, depending on line changes)
                let error = NSError(domain: "SignUpViewModel", code: 5, userInfo: [NSLocalizedDescriptionKey: "Firebase user object is nil after successful sign-up."])
                errorMessage = getAuthErrorMessage(error: error)
                showAlert = true
                return nil
            }

            let profileChange = validFbUser.createProfileChangeRequest()
            profileChange.displayName = fullName
            try await profileChange.commitChanges()

            let fullNameParts = fullName.split(separator: " ", maxSplits: 1).map(String.init)
            let firstName = fullNameParts.first ?? ""
            let lastName = fullNameParts.count > 1 ? fullNameParts[1] : ""

            let userData: [String: Any] = [
                "email": validFbUser.email ?? "",
                "displayName": fullName,
                "firstName": firstName,
                "lastName": lastName,
                "uid": validFbUser.uid,
                "createdAt": Timestamp()
            ]

            try await db.collection("users").document(validFbUser.uid).setData(userData)

            successMessage = "Account created successfully! Welcome \(fullName)."
            showAlert = true
            print("Sign up successful. Returning Firebase User.")
            return validFbUser
        } catch {
            errorMessage = getAuthErrorMessage(error: error)
            showAlert = true
            return nil
        }
    }

    private func getAuthErrorMessage(error: Error) -> String {
        if let errorCode = AuthErrorCode(rawValue: (error as NSError).code) {
            switch errorCode {
            case .emailAlreadyInUse:
                return "This email address is already in use. Please sign in or use a different email."
            case .invalidEmail:
                return "The email address is not valid."
            case .weakPassword:
                return "The password is too weak. Please use a stronger password (at least 6 characters)."
            default:
                return "Sign up failed: \(error.localizedDescription)"
            }
        }
        return "An unknown error occurred during sign up."
    }
}
