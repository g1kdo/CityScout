//
//  ForgotPasswordView.swift
//  CityScout
//
//  Created by Umuco Auca on 20/05/2025.
//


import SwiftUI
import FirebaseAuth

// MARK: - Forgot Password View

struct ForgotPasswordView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @State private var email: String = ""
    @State private var showCheckEmailState: Bool = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSignInActive: Bool = false


    var body: some View {
        NavigationStack { // Added NavigationView for the back button
            VStack(spacing: 25) {
                
                if showCheckEmailState {
                    HStack {
                        Button(action: {
                            // Action to go back or dismiss
                            showCheckEmailState = false // For example, go back to initial form
                            
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.black)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                } else {
                    HStack {
                        Button(action: {
                            isSignInActive = true
                            
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.black)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                }


                Text("Forgot password")
                    .font(.largeTitle)
                    .fontWeight(.bold) // Exact replica has bold title
                    .padding(.bottom, 5) // Reduced padding as per screenshot

                Text("Enter your email account to reset\nyour password") // Newline for exact replica
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40) // Constrain width

                Spacer() // Pushes content towards center

                if showCheckEmailState {
                    // Check your email state UI
                    Image(systemName: "envelope.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80) // Adjusted size for visual match
                        .foregroundColor(.white)
                        .padding(20)
                        .background(Color(hex: "#FF8C42")) // Orange color from screenshot
                        .cornerRadius(40) // Half of width/height for perfect circle
                        .padding(.bottom, 20)

                    Text("Check your email")
                        .font(.title2) // Slightly smaller than largeTitle but prominent
                        .fontWeight(.bold)
                        .padding(.bottom, 5)

                    Text("We have sent the password\nrecovery instructions to your email")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    // The email field in this state is not a button but a display
                    FloatingField(label: "Email Address", placeholder: "example@cityscout.com", text: $email)
                        .padding(.horizontal)
                        .padding(.top, 20) // Spacing from text above
                        .padding(.bottom, 50) // Space before the very bottom if other elements were there

                } else {
                    // Initial form state UI
                    FloatingField(label: "Email Address", placeholder: "example@cityscout.com", text: $email, keyboardType: .emailAddress, autocapitalization: .never)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    PrimaryButton(title: "Reset Password") {
                        resetPassword()
                    }
                    .padding(.horizontal)
                }

                Spacer() // Pushes content towards center
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Notice"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }

        }
        .navigationDestination(isPresented: $isSignInActive) {
            SignInView()
                .environmentObject(authVM) // Pass authVM to SignInView
        }
    }
    
    func resetPassword() {
        guard !email.isEmpty else {
            alertMessage = "Please enter your email address."
            showAlert = true
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
            } else {
                showCheckEmailState = true
            }
        }
    }
}




#Preview {
    ForgotPasswordView()
}
