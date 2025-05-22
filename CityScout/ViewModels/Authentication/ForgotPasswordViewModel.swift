//
//  ForgotPasswordViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 22/05/2025.
//


import Foundation
import FirebaseAuth

class ForgotPasswordViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var showCheckEmailState: Bool = false
    @Published var showingAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var emailSentSuccessfully: Bool = false // To indicate success for navigation

    func sendPasswordResetEmail() {
        guard !email.isEmpty else {
            alertMessage = "Please enter your email address."
            showingAlert = true
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error sending password reset email: \(error.localizedDescription)")
                    self?.alertMessage = "Error: \(error.localizedDescription)"
                    self?.showingAlert = true
                    self?.emailSentSuccessfully = false
                } else {
                    print("Password reset email sent successfully to \(self?.email ?? "")")
                    self?.showCheckEmailState = true
                    self?.alertMessage = "A password reset email has been sent to \(self?.email ?? "your email"). Please check your inbox."
                    self?.showingAlert = true
                    self?.emailSentSuccessfully = true // Set to true on success
                }
            }
        }
    }
}
