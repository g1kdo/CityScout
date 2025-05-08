//
//  SignInView.swift
//  CityScout
//
//  Created by Umuco Auca on 30/04/2025.
//

import SwiftUI
import FirebaseAuth
import AuthenticationServices

struct SignInView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @StateObject private var googleAuthViewModel = GoogleAuthViewModel()
    @StateObject private var appleAuthViewModel = AppleAuthViewModel()
    @State private var isPasswordVisible = false
    @State private var shouldNavigateHome = false
    @State private var isSignUpActive = false

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
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email Address")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                    TextField("", text: $viewModel.email)
                        .placeholder(when: viewModel.email.isEmpty) {
                            Text("").foregroundColor(.gray)
                        }
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .frame(height: 50)
                        .background(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.gray.opacity(0.3)))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                    HStack {
                        Group {
                            if isPasswordVisible {
                                TextField("", text: $viewModel.password)
                                    .placeholder(when: viewModel.password.isEmpty) {
                                        Text("").foregroundColor(.gray)
                                    }
                            } else {
                                SecureField("", text: $viewModel.password)
                                    .placeholder(when: viewModel.password.isEmpty) {
                                        Text("").foregroundColor(.gray)
                                    }
                            }
                        }

                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal) // Add horizontal padding to the HStack
                    .frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.gray.opacity(0.3)))
                }

                // ── Forgot Password ──
                HStack {
                    Spacer()
                    Button("Forgot Password?") {
                        // TODO: Implement forgot password action
                        print("Forgot Password Tapped")
                    }
                    .font(.caption)
                    .foregroundColor(Color(hex: "#FF7029"))
                }

                // ── Sign In Button ──
                Button {
                    Task {
                        await viewModel.signIn()
                    }
                } label: {
                    Text(viewModel.isAuthenticating ? "Signing In..." : "Sign In")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, height: 50)
                        .background(Color(red: 0/255, green: 175/255, blue: 240/255)) // Your blue color
                        .cornerRadius(10)
                }

                // ── Divider ──
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.3))
                    Text("Or continue with")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.3))
                }
                .padding(.vertical)

                // ── Social Buttons ──
                HStack(spacing: 20) {
                    Button {
                        Task {
                            let success = await googleAuthViewModel.signInWithGoogle()
                            if success {
                                print("Successfully signed in with Google")
                                // Potentially navigate home here if your view model doesn't handle it
                            } else {
                                print(googleAuthViewModel.errorMessage)
                            }
                        }
                    } label: {
                        Image("google_logo")
                            .resizable()
                            .frame(width: 40, height: 40)
                    }

                    Button {
                        // TODO: Implement Facebook Sign In
                        print("Facebook Sign In Tapped")
                    } label: {
                        Image("facebook_logo")
                            .resizable()
                            .frame(width: 40, height: 40)
                    }

                    Button {
                        appleAuthViewModel.startSignInWithAppleFlow()
                    } label: {
                        Image("apple_logo")
                            .resizable()
                            .frame(width: 30, height: 40)
                    }
                }

                // ── Sign Up Link ──
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                    Button("Sign up") {
                        navigateToSignUp()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#FF7029"))
                    .font(.footnote)
                }

                Spacer()
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .alert(isPresented: Binding(get: { !viewModel.errorMessage.isEmpty }, set: { _ in viewModel.errorMessage = "" })) {
            Alert(title: Text("Error"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")))
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $shouldNavigateHome) {
            Text("Home Screen Placeholder") // Replace with your actual Home View
        }
        .navigationDestination(isPresented: $isSignUpActive) {
            SignUpView() // Assuming you have a SignUpView
        }
    }

    private func navigateToSignUp() {
        isSignUpActive = true
    }
}

// Helper extension for TextField placeholder
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    SignInView()
}