//
// SignInView.swift
// CityScout
//
// Created by Umuco Auca on 30/04/2025.
//
import SwiftUI
import FirebaseAuth
import AuthenticationServices

struct SignInView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @StateObject private var googleAuthViewModel = GoogleAuthViewModel()
    @StateObject private var appleAuthViewModel = AppleAuthViewModel()
    @StateObject private var facebookAuthViewModel = FacebookAuthViewModel()
    @State private var shouldNavigateHome = false
    @State private var isSignUpActive = false

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                headerSection
                fieldsSection
                forgotPasswordSection
                signInButton
                dividerSection
                socialSection
                footerSection
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
        .navigationBarHidden(true)
        // Corrected alert binding:
        .alert(isPresented: Binding(
                   get: { viewModel.showAlert || googleAuthViewModel.errorMessage.isEmpty == false || facebookAuthViewModel.errorMessage.isEmpty == false || appleAuthViewModel.errorMessage.isEmpty == false },
                   set: { _ in
                       if viewModel.showAlert { viewModel.errorMessage = ""; viewModel.showAlert = false }
                       if googleAuthViewModel.errorMessage.isEmpty == false { googleAuthViewModel.errorMessage = "" }
                       if facebookAuthViewModel.errorMessage.isEmpty == false { facebookAuthViewModel.errorMessage = "" }
                       if appleAuthViewModel.errorMessage.isEmpty == false { appleAuthViewModel.errorMessage = "" }
                   }
               )) {
                   // Determine which error message to show
                   if !viewModel.errorMessage.isEmpty {
                       Alert(title: Text("Sign In Error"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")))
                   } else if !googleAuthViewModel.errorMessage.isEmpty {
                       Alert(title: Text("Google Sign In Error"), message: Text(googleAuthViewModel.errorMessage), dismissButton: .default(Text("OK")))
                   } else if !facebookAuthViewModel.errorMessage.isEmpty {
                       Alert(title: Text("Facebook Sign In Error"), message: Text(facebookAuthViewModel.errorMessage), dismissButton: .default(Text("OK")))
                   } else if !appleAuthViewModel.errorMessage.isEmpty {
                       Alert(title: Text("Apple Sign In Error"), message: Text(appleAuthViewModel.errorMessage), dismissButton: .default(Text("OK")))
                   } else {
                       Alert(title: Text("Unknown Error"), message: Text("An unexpected error occurred."), dismissButton: .default(Text("OK")))
                   }
               }
        .navigationDestination(isPresented: $shouldNavigateHome) {
         HomeView()
        }
        .navigationDestination(isPresented: $isSignUpActive) {
            SignUpView() // Assuming you have a SignUpView
        }
    }

    // --- Sections (as provided in the previous good response) ---

    private var headerSection: some View {
        VStack(spacing: 15) {
            Text("Sign In Here!")
                .font(.title.bold())
                .padding(.top, 15)
            Text("Please sign in to your account")
                .font(.system(size: 18))
                .foregroundColor(.gray)
                .padding(.bottom, 15)
        }
    }

    private var fieldsSection: some View {
        Group {
            FloatingField(
                label: "Email Address",
                placeholder: "Enter your email",
                text: $viewModel.email,
                keyboardType: .emailAddress,
                autocapitalization: .never
            )
            FloatingField(
                label: "Password",
                placeholder: "Enter your password",
                text: $viewModel.password,
                isSecure: true
            )
        }
    }

    private var forgotPasswordSection: some View {
        HStack {
            Spacer()
            Button("Forgot Password?") {
                // TODO: Implement forgot password action
                print("Forgot Password Tapped")
            }
            .font(.caption)
            .foregroundColor(Color(hex: "#FF7029"))
        }
    }

    private var signInButton: some View {
        Button {
            Task {
                await viewModel.signIn()
                if viewModel.errorMessage.isEmpty {
                    shouldNavigateHome = true // Navigate on successful sign-in
                }
            }
        } label: {
            Group {
                if viewModel.isAuthenticating {
                    ProgressView()
                } else {
                    Text("Sign In")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color(hex: "#24BAEC"))
            .cornerRadius(10)
        }
        .disabled(viewModel.email.isEmpty || viewModel.password.isEmpty || viewModel.isAuthenticating)
        .opacity((viewModel.email.isEmpty || viewModel.password.isEmpty || viewModel.isAuthenticating) ? 0.6 : 1.0)
    }

    private var dividerSection: some View {
        HStack {
            Capsule()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.5))
            Text("Or continue with")
                .font(.footnote)
                .foregroundColor(.gray)
            Capsule()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.5))
        }
    }

    private var socialSection: some View {
        HStack(spacing: 20) {
            Button {
                Task {
                    let success = await googleAuthViewModel.signInWithGoogle()
                    if success {
                        print("Successfully signed in with Google")
                        shouldNavigateHome = true // Navigate on successful Google sign-in
                    } else {
                        // Pass the Google error to the main viewModel's alert system
                        viewModel.errorMessage = googleAuthViewModel.errorMessage
                        viewModel.showAlert = true
                    }
                }
            } label: {
                Image("google_logo")
                    .resizable()
                    .frame(width: 40, height: 40)
            }
            Button {
                // TODO: Implement Facebook Sign In
                Task {
                               let success = await facebookAuthViewModel.signInWithFacebook()
                               if success {
                                   print("Successfully signed in with Facebook")
                                   shouldNavigateHome = true // Navigate on successful Facebook sign-in
                               } else {
                                   // Pass the Facebook error to the main viewModel's alert system
                                   viewModel.errorMessage = facebookAuthViewModel.errorMessage
                                   viewModel.showAlert = true
                               }
                           }
            } label: {
                Image("facebook_logo")
                    .resizable()
                    .frame(width: 40, height: 40)
            }
            Button {
                appleAuthViewModel.startSignInWithAppleFlow()
                // You'll need to handle Apple sign-in results and potentially
                // set viewModel.errorMessage and viewModel.showAlert based on its outcome.
            } label: {
                Image("apple_logo")
                    .resizable()
                    .frame(width: 30, height: 40)
            }
        }
    }

    private var footerSection: some View {
        HStack {
            Text("Don't have an account?")
                .foregroundColor(.gray)
                .font(.footnote)
            Button("Sign up") {
                isSignUpActive = true
            }
            .fontWeight(.semibold)
            .foregroundColor(Color(hex: "#FF7029"))
            .font(.footnote)
        }
        .padding(.bottom, 20)
    }
}


#Preview {
    SignInView()
}
