// SignUpView.swift

import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @State private var fullName     = ""
    @State private var email        = ""
    @State private var password     = ""
    @State private var isAgreed     = false
    @State private var isLoading    = false
    @State private var errorMessage = ""
    @State private var showAlert    = false
    @State private var signedInUser: SignedInUser? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer().frame(height: 30)
                    
                VStack(spacing: 8) {
                    Text("Sign Up Here!")
                        .font(.title.bold())
                    Text("Please fill in the details and create a new account")
                        .foregroundColor(.gray)
                        
                }
          
                // ── Fields ──
                FloatingField(
                    label: "Full Name",
                    
                    placeholder: "Enter your full name",
                    text: $fullName
                )

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

                // ── Terms Checkbox ──
                HStack(alignment: .top) {
                    Button { isAgreed.toggle() } label: {
                        Image(systemName: isAgreed
                              ? "checkmark.square.fill"
                              : "square")
                        .font(.title3)
                        .foregroundColor(
                            isAgreed
                            ? Color(hex: "#24BAEC")
                            : .secondary
                        )}

                    Text("I agree with the ")
                    Text("Terms of Service")
                        .foregroundColor(Color(hex: "#FF7029"))
                        .onTapGesture { /* open URL */ }
                    Text(" and ")
                    Text("Privacy Policy")
                        .foregroundColor(Color(hex: "#FF7029"))
                        .onTapGesture { /* open URL */ }
                }
                .font(.footnote)

                // ── Sign Up Button ──
                PrimaryButton(
                    title: "Sign Up",
                    isLoading: isLoading,
                    disabled: fullName.isEmpty || email.isEmpty || password.isEmpty || !isAgreed
                ) {
                    signUpTapped()
                }

                // ── Divider ──
                DividerWithText(text: "Or Sign up with")

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

                // ── Sign In Link ──
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.gray)
                    Button("Sign In") {
                        // TODO: navigate to SignInView
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
        .fullScreenCover(item: $signedInUser) { user in
            HomeView(user: user)
        }
    }

    private func signUpTapped() {
        guard !fullName.isEmpty, !email.isEmpty, !password.isEmpty, isAgreed else {
            errorMessage = "All fields must be filled and terms agreed."
            showAlert = true
            return
        }
        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { res, err in
            isLoading = false
            if let e = err {
                errorMessage = e.localizedDescription
                showAlert = true
                return
            }
            guard let fbUser = Auth.auth().currentUser else { return }
            let req = fbUser.createProfileChangeRequest()
            req.displayName = fullName
            req.commitChanges { _ in
                signedInUser = SignedInUser(
                    id: fbUser.uid,
                    displayName: fullName,
                    email: fbUser.email ?? ""
                )
            }
        }
    }
}
#Preview {
    SignUpView()
}
