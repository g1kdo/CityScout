//
//  AccountView.swift
//  CityScout
//
//  Created by Umuco Auca on 13/08/2025.
//


import SwiftUI
import FirebaseAuth

struct AccountView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var accountViewModel = AccountViewModel()
    @StateObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationStack {
            Form {
                // Section to display user information
                Section(header: Text("Account Information")) {
                    if let email = authViewModel.signedInUser?.email {
                        AccountRow(icon: "envelope.fill", title: "Email", value: email, color: .purple)
                    }
                }
                
                // Section for trips, comments, and reactions
                // Note: The data for these fields is a placeholder. You'll need to
                // integrate with your actual data source (e.g., Firestore) to
                // fetch and display real values.
                Section(header: Text("Activity Summary")) {
                    AccountRow(icon: "map.fill", title: "Trips", value: "12", color: .teal)
                    AccountRow(icon: "text.bubble.fill", title: "Comments", value: "34", color: .blue)
                    AccountRow(icon: "hand.thumbsup.fill", title: "Reactions", value: "156", color: .orange)
                }
                
                // Conditional section for changing password
                if accountViewModel.isEmailPasswordUser() {
                    Section(header: Text("Change Password")) {
                        SecureField("Current Password", text: $accountViewModel.currentPassword)
                        SecureField("New Password", text: $accountViewModel.newPassword)
                        SecureField("Confirm New Password", text: $accountViewModel.confirmNewPassword)
                        
                        if accountViewModel.isChangePasswordLoading {
                            ProgressView()
                        }
                        
                        if let message = accountViewModel.errorMessage {
                            Text(message)
                                .foregroundColor(.red)
                        }
                        
                        if let message = accountViewModel.successMessage {
                            Text(message)
                                .foregroundColor(.green)
                        }
                        
                        Button("Change Password") {
                            Task {
                                await accountViewModel.changePassword()
                            }
                        }
                        .disabled(accountViewModel.isChangePasswordLoading)
                    }
                }
                
                // Section to delete or deactivate account
                Section(header: Text("Danger Zone")) {
                    Button("Deactivate Account") {
                        accountViewModel.isShowingDeactivationAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .alert("Deactivate Account", isPresented: $accountViewModel.isShowingDeactivationAlert) {
                Button("Deactivate", role: .destructive) {
                    Task {
                        await accountViewModel.deactivateAccount()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to deactivate your account? This action cannot be undone.")
            }
            .onAppear {
                accountViewModel.resetMessages()
            }
        }
    }
}

// A helper view for rows in the Settings screen
struct AccountRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.body)
                .frame(width: 24, height: 24)
                .foregroundColor(.white)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}
