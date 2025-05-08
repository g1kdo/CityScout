// SignInView.swift

import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @State private var email              = ""
    @State private var password           = ""
    @State private var errorMessage       = ""
    @State private var showAlert          = false
    @State private var isLoading          = false
    @State private var shouldNavigateHome = false

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer().frame(height: 40)

                VStack(spacing: 8) {
                    Text("Sign in to your account")
                        .font(.title.bold())
                    Text("Please sign in to your account")
                        .foregroundColor(.gray)
                }

                // ── Fields ──
                FloatingField(
                    label: "Email Address",
                    
                    placeholder: "Enter your email",
                    text: $email,
                    keyboardType: .emailAddress,
                    autocapitalization: .never
                )

                FloatingField(
                    label: "Password",
                    
                    placeholder: "Enter your password",
                    text: $password,
                    isSecure: true
                )

                // ── Forgot Password ──
                HStack {
                    Spacer()
                    Button("Forgot Password?") {
                        // TODO
                    }
                    .font(.caption)
                    .foregroundColor(Color(hex: "#FF7029"))
                }

                // ── Sign In Button ──
                PrimaryButton(
                    title: "Sign In",
                    isLoading: isLoading,
                    disabled: email.isEmpty || password.isEmpty
                ) {
                    signInTapped()
                }

                // ── Divider ──
                DividerWithText(text: "Or continue with")

                // ── Social Buttons ──
                HStack(spacing: 20) {
                    SocialLoginButton(provider: .google) {
                        // TODO
                    }
                    SocialLoginButton(provider: .facebook) {
                        // TODO
                    }
                    SocialLoginButton(provider: .apple) {
                        // TODO
                    }
                }

                // ── Sign Up Link ──
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.secondary)
                    Button("Sign up") {
                        // TODO: navigate to SignUpView
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#FF7029"))
                }
                .font(.footnote)

                Spacer()
            }
            .padding(.horizontal)
        }
        .alert(errorMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .navigationDestination(isPresented: $shouldNavigateHome) {
            Text("Home Screen Placeholder")
                }
                .navigationBarHidden(true)
    }

    private func signInTapped() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            showAlert = true
            return
        }
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            isLoading = false
            if let err = error {
                errorMessage = err.localizedDescription
                showAlert = true
            } else {
                shouldNavigateHome = true
            }
        }
    }
}
#Preview {
    SignInView()
}
