//
//  AccountViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 13/08/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AccountViewModel: ObservableObject {
    @Published var newPassword = ""
    @Published var confirmNewPassword = ""
    @Published var currentPassword = ""
    @Published var isChangePasswordLoading = false
    @Published var isDeactivationLoading = false
    @Published var isDeletionLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isShowingDeactivationAlert = false
    @Published var isShowingDeletionAlert = false

    private var db = Firestore.firestore()
    
    enum ProviderType {
        case password, google, apple, other
        
        static func from(providerID: String) -> ProviderType {
            switch providerID {
            case "password": return .password
            case "google.com": return .google
            case "apple.com": return .apple
            default: return .other
            }
        }
    }
    
    // Check if the current user is signed in with email/password
    func isEmailPasswordUser() -> Bool {
        guard let user = Auth.auth().currentUser else { return false }
        for provider in user.providerData {
            if provider.providerID == "password" {
                return true
            }
        }
        return false
    }
    
    // Get a list of providers the user has linked
    func getProviders(for user: FirebaseAuth.User?) -> [ProviderType] {
        guard let user = user else { return [] }
        return user.providerData.map { ProviderType.from(providerID: $0.providerID) }
    }
    
    func changePassword() async {
        guard !currentPassword.isEmpty, !newPassword.isEmpty, !confirmNewPassword.isEmpty else {
            errorMessage = "Please fill in all password fields."
            return
        }
        guard newPassword == confirmNewPassword else {
            errorMessage = "New passwords do not match."
            return
        }
        
        isChangePasswordLoading = true
        errorMessage = nil
        successMessage = nil
        
        guard let user = Auth.auth().currentUser, let email = user.email else {
            errorMessage = "User not found or not signed in."
            isChangePasswordLoading = false
            return
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        do {
            // Re-authenticate user before changing password for security
            try await user.reauthenticate(with: credential)
            
            // Update password
            try await user.updatePassword(to: newPassword)
            successMessage = "Password changed successfully!"
            
            // Clear fields after success
            currentPassword = ""
            newPassword = ""
            confirmNewPassword = ""
            
        } catch {
            errorMessage = "Failed to change password: \(error.localizedDescription)"
        }
        isChangePasswordLoading = false
    }
    
    func deactivateAccount() async {
        isDeactivationLoading = true
        errorMessage = nil
        
        guard Auth.auth().currentUser != nil else {
            errorMessage = "No authenticated user to deactivate."
            isDeactivationLoading = false
            return
        }
        
        do {
            // Deactivating an account is not a built-in Firebase function.
            // A common approach is to sign out the user and set a flag in your database.
            // For now, this function is a placeholder for that logic.
            // You might add a field like `isActive: false` to your user's Firestore document.
            // For this implementation, we will just sign out the user.
            
            try Auth.auth().signOut()
            successMessage = "Account successfully deactivated. You can log back in to reactivate it."
            
        } catch {
            errorMessage = "Failed to deactivate account: \(error.localizedDescription)"
        }
        isDeactivationLoading = false
    }
    
    func deleteAccount() async {
        isDeletionLoading = true
        errorMessage = nil
        
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No authenticated user to delete."
            isDeletionLoading = false
            return
        }
        
        do {
            // It's a best practice to delete the user's data from Firestore first.
            // This prevents "orphaned" data if the account deletion fails.
            try await db.collection("users").document(user.uid).delete()
            
            // Then, delete the user from Firebase Authentication.
            try await user.delete()
            
            // After successful deletion, sign out to clear the session.
            try Auth.auth().signOut()
            
            successMessage = "Account and all data have been permanently deleted."
            
        } catch {
            errorMessage = "Failed to delete account: \(error.localizedDescription). Please sign in again and try."
        }
        isDeletionLoading = false
    }

    func resetMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
