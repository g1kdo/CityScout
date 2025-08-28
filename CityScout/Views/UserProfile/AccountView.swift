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
                
                // Section for Privacy & Security
                Section(header: Text("Privacy & Security")) {
                    NavigationLink(destination: PrivacySecurityView()) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .font(.body)
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                                .background(Color.green)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Text("Security & Data")
                        }
                    }
                }
                
                // Section for Connected Accounts
                Section(header: Text("Connected Accounts")) {
                    ForEach(accountViewModel.getProviders(for: authViewModel.user), id: \.self) { provider in
                        switch provider {
                        case .password:
                            AccountRow(icon: "lock.fill", title: "Email/Password", value: "Connected", color: .blue)
                        case .google:
                            AccountRow(icon: "lock.fill", title: "Google", value: "Connected", color: .red)
                        case .apple:
                            AccountRow(icon: "lock.fill", title: "Apple", value: "Connected", color: .black)
                        default:
                            AccountRow(icon: "lock.fill", title: "Other", value: "Connected", color: .gray)
                        }
                    }
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Button("Deactivate Account") {
                            accountViewModel.isShowingDeactivationAlert = true
                        }
                        .foregroundColor(.red)
                        
                        Text("This makes your account temporarily unavailable but keeps your data, should you choose to return later.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Button("Delete Account and Data") {
                            accountViewModel.isShowingDeletionAlert = true
                        }
                        .foregroundColor(.red)
                        
                        Text("This is permanent. It will permanently delete your account and all associated data, including your profile, messages, and content. This action **cannot** be undone.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
                Text("Are you sure you want to deactivate your account? You can reactivate it at any time by logging back in. Your data will be preserved.")
            }
            .alert("Delete Account and Data", isPresented: $accountViewModel.isShowingDeletionAlert) {
                Button("Delete", role: .destructive) {
                    Task {
                        await accountViewModel.deleteAccount()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action is permanent and cannot be reversed. All of your data will be permanently deleted. Are you absolutely sure?")
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

// Placeholder for the new PrivacySecurityView
struct PrivacySecurityView: View {
    var body: some View {
        Form {
            Section(header: Text("Data Privacy")) {
                Text("Manage how your data is used.")
            }
            Section(header: Text("Security")) {
                Text("Review your login sessions.")
            }
        }
        .navigationTitle("Privacy & Security")
    }
}
