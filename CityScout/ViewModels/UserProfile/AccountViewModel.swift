//
//  AccountViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 13/08/2025.
//


// ViewModels/AccountViewModel.swift
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
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isShowingDeactivationAlert = false

    private var db = Firestore.firestore()
    
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
        
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No authenticated user to deactivate."
            isDeactivationLoading = false
            return
        }
        
        do {
            // Delete user data from Firestore first
            // This is a crucial step to clean up data before deleting the user
            try await db.collection("users").document(user.uid).delete()
            
            // Delete the user from Firebase Auth
            try await user.delete()
            
            // Sign out to clear the session
            try Auth.auth().signOut()
            
            successMessage = "Account successfully deactivated."
            
        } catch {
            errorMessage = "Failed to deactivate account: \(error.localizedDescription). Please sign in again and try."
        }
        isDeactivationLoading = false
    }

    func resetMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
