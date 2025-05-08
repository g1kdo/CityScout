import SwiftUI
import FirebaseAuth
import AuthenticationServices // Potentially needed for Apple Sign In in the future

// MARK: – Model for the signed-in user
struct SignedInUser: Identifiable {
    let id: String        // Firebase UID
    let displayName: String // Full name
    let email: String
}

// MARK: – The updated SignUpView
struct SignUpView: View {
    // Drives the full-screen cover when non-nil
    @State private var signedInUser: SignedInUser? = nil
    @StateObject private var viewModel = SignUpViewModel()
    @StateObject private var googleAuthViewModel = GoogleAuthViewModel()
    // @StateObject private var appleAuthViewModel = AppleAuthViewModel() // If you integrate Apple Sign In

    // Form state (using ViewModel's properties now)
    @State private var isAgreed = false

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                headerSection
                fieldsSection
                termsSection
                signUpButton
                dividerSection
                socialSection
                footerSection
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
        .navigationBarHidden(true)
        .alert(viewModel.errorMessage, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .fullScreenCover(item: $signedInUser) { user in
            HomeView(user: user)
        }
    }

    // ─── Sections ────────────────────────────────────────────

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("Sign Up Here!")
                .font(.title.bold())
                .padding(.top, 15)

            Text("Please fill in the details and create a new account")
                .font(.system(size: 18))
                .foregroundColor(.gray)
                .padding(.bottom, 15)
        }
    }

    private var fieldsSection: some View {
        Group {
            FloatingField(
                label: "Full Name",
                placeholder: "Enter your full name",
                text: $viewModel.fullName
            )

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

    private var termsSection: some View {
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
                    )
            }

            Text("I agree with the ")
            Text("Terms of Service")
                .foregroundColor(Color(hex: "#FF7029"))
                .onTapGesture { openURL("https://your.app/terms") }
            Text(" and ")
            Text("Privacy Policy")
                .foregroundColor(Color(hex: "#FF7029"))
                .onTapGesture { openURL("https://your.app/privacy") }
        }
        .font(.footnote)
    }

    private var signUpButton: some View {
        Button {
            Task {
                if !isAgreed {
                    viewModel.errorMessage = "You must agree to the Terms and Privacy Policy."
                    viewModel.showAlert = true
                } else {
                    await viewModel.signUpUser()
                }
            }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Sign Up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color(hex: "#24BAEC"))
            .cornerRadius(10)
        }
        .disabled(
            !isAgreed ||
            viewModel.fullName.isEmpty ||
            viewModel.email.isEmpty ||
            viewModel.password.isEmpty ||
            viewModel.isLoading
        )
        .opacity(
            (!isAgreed || viewModel.fullName.isEmpty || viewModel.email.isEmpty || viewModel.password.isEmpty)
            ? 0.6 : 1.0
        )
    }

    private var dividerSection: some View {
        HStack {
            Capsule()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.5))
            Text("Or sign up with")
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
                        print("Successfully signed up/in with Google")
                        // Potentially update signedInUser here if your GoogleAuthViewModel handles user info
                    } else {
                        print(googleAuthViewModel.errorMessage)
                        viewModel.errorMessage = googleAuthViewModel.errorMessage // Show Google error in the app's alert
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
                print("Facebook Sign In Tapped")
            } label: {
                Image("facebook_logo")
                    .resizable()
                    .frame(width: 40, height: 40)
            }

            Button {
                // TODO: Implement Apple Sign In using appleAuthViewModel
                print("Apple Sign In Tapped")
                // appleAuthViewModel.startSignInWithAppleFlow()
            } label: {
                Image("apple_logo")
                    .resizable()
                    .frame(width: 30, height: 40)
            }
        }
    }

    private var footerSection: some View {
        HStack {
            Text("Already have an account?")
                .foregroundColor(.gray)
                .font(.footnote)
            NavigationLink("Sign In", destination: Text("SignInView Placeholder")) // Replace with your actual SignInView
                .foregroundColor(Color(hex: "#FF7029"))
                .font(.footnote)
        }
        .padding(.bottom, 20)
    }

    private func openURL(_ str: String) {
        guard let url = URL(string: str) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: – FloatingField helper (Assuming this is defined elsewhere or in Version 2)

struct FloatingField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)

            HStack {
                Image(systemName: isSecure ? "lock.fill" : "person.fill")
                    .foregroundColor(.secondary)

                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}


#Preview {
    SignUpView()
}