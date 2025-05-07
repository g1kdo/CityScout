//
//  SignInView.swift
//  CityScout
//
//  Created by Umuco Auca on 30/04/2025.
//

import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var errorMessage = ""
    @State private var shouldNavigateToHome = false
    
    var body: some View {
        GeometryReader { geometry in
            
        ScrollView {
            VStack(spacing: 30) {
                Spacer() // Top spacing
                    .frame(height: geometry.size.height / 15)
                VStack(alignment: .center, spacing: 10) {
                    
                    Text("Sign in to your account")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Please sign in to your account")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: 340)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email Address")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                    TextField("", text: $email)
                        .placeholder(when: email.isEmpty) {
                            Text("").foregroundColor(.gray)
                        }
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .frame(height: 50)
                        .background(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.gray.opacity(0.3)))
                }
                .frame(maxWidth: 340)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                    HStack {
                        Group {
                            if isPasswordVisible {
                                TextField("", text: $password)
                                    .placeholder(when: password.isEmpty) {
                                        Text("").foregroundColor(.gray)
                                    }
                            } else {
                                SecureField("", text: $password)
                                    .placeholder(when: password.isEmpty) {
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
                    
                    HStack {
                        Spacer()
                        Button {
                            // TODO: Implement forgot password action
                            print("Forgot Password Tapped")
                        } label: {
                            Text("Forgot Password?")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#FF6900")) // Using your orange color
                        }
                    }
                }
                .frame(maxWidth: 340)
                
                Button {
                    signInTapped()
                } label: {
                    Text("Sign In")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                        .frame(width: 340, height: 50)
                        .background(Color(red: 0/255, green: 175/255, blue: 240/255)) // Your blue color
                        .cornerRadius(10)
                }
                
                VStack(spacing: 10) {
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color.gray.opacity(0.3))
                        Text("Or sign in with")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color.gray.opacity(0.3))
                    }
                    .frame(maxWidth: 340)
                    
                    HStack(spacing: 15) {
                        Button {
                            // TODO: Implement Google Sign In
                            print("Google Sign In Tapped")
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
                            // TODO: Implement Apple Sign In
                            print("Apple Sign In Tapped")
                        } label: {
                            Image("apple_logo")
                                .resizable()
                                .frame(width: 30, height: 40)
                        }
                    }
                }
                
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Button {
                        // TODO: Implement navigation to sign up view
                        print("Sign up Tapped")
                    } label: {
                        Text("Sign up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#FF6900")) // Your orange color
                    }
                }
                
                Spacer() // Bottom spacing
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .alert(isPresented: Binding(get: { !errorMessage.isEmpty }, set: { _ in errorMessage = "" })) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
        .navigationDestination(isPresented: $shouldNavigateToHome) {
            // Replace with your actual HomeView
            Text("Home Screen Placeholder")
        }
        .navigationBarHidden(true)
    }
}
    func signInTapped() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }
        signInUser(email: email, password: password)
    }

    func signInUser(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Sign in failed: \(error.localizedDescription)")
                errorMessage = "Sign in failed: \(error.localizedDescription)"
                return
            }
            // Signed in successfully
            print("User signed in: \(authResult?.user.email ?? "No Email")")
            navigateToHomeScreen()
        }
    }

    func navigateToHomeScreen() {
        shouldNavigateToHome = true
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
