import SwiftUI
import FirebaseAuth

// MARK: – Model for the signed-in user
struct SignedInUser: Identifiable {
    let id: String           // Firebase UID
    let displayName: String  // Full name
    let email: String
}

// MARK: – The updated SignUpView
struct SignUpView: View {
    // Drives the full-screen cover when non-nil
    @State private var signedInUser: SignedInUser? = nil

    // Form state
    @State private var fullName    = ""
    @State private var email       = ""
    @State private var password    = ""
    @State private var isAgreed    = false
    @State private var isLoading   = false
    @State private var alertMsg    = ""
    @State private var showAlert   = false

    var body: some View {
        NavigationStack {
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
            .alert(alertMsg, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            }
            .fullScreenCover(item: $signedInUser) { user in
                HomeView(user: user)
            }
        }
    }

    // ─── Sections ────────────────────────────────────────────

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("Sign Up Here")
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
                placeholder: "Enter Full Name",
                text: $fullName
            )

            FloatingField(
                label: "Email Address",
                placeholder: "Enter Email",
                text: $email,
                keyboardType: .emailAddress,
                autocapitalization: .never
            )

            FloatingField(
                label: "Password",
                placeholder: "Enter Password",
                text: $password,
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
        Button(action: signUpWithEmail) {
            Group {
                if isLoading {
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
            !isAgreed
            || isLoading
            || fullName.isEmpty
            || email.isEmpty
            || password.isEmpty
        )
    }

    private var dividerSection: some View {
        HStack {
            Capsule()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.5))
            Text("Or sign in with")
                .font(.footnote)
                .foregroundColor(.gray)
            Capsule()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.5))
        }
    }

    private var socialSection: some View {
        HStack(spacing: 14) {
            Button { /* TODO: Google Sign-In */ } label: {
                Image("google_logo")
                    .resizable()
                    .frame(width: 40, height: 40)
            }
            Button { /* TODO: Facebook Sign-In */ } label: {
                Image("facebook_logo")
                    .resizable()
                    .frame(width: 40, height: 40)
            }
            Button { /* TODO: Apple Sign-In */ } label: {
                Image("apple_logo")
                    .resizable()
                    .frame(width: 37, height: 42)
            }
        }
    }

    private var footerSection: some View {
        HStack {
            Text("Already have an account?")
                .foregroundColor(.secondary)
            NavigationLink("Sign In", destination: Text("Sign In Screen"))
                .foregroundColor(Color(hex: "#FF7029"))
        }
        .font(.footnote)
        .padding(.bottom, 20)
    }

    // ─── Actions ─────────────────────────────────────────────

    private func signUpWithEmail() {
        guard isAgreed else {
            alertMsg = "You must agree to the Terms and Privacy Policy."
            showAlert = true
            return
        }
        isLoading = true

        Auth.auth().createUser(withEmail: email, password: password) { _, error in
            isLoading = false
            if let err = error {
                alertMsg = err.localizedDescription
                showAlert = true
                return
            }
            guard let fbUser = Auth.auth().currentUser else { return }

            // Update display name
            let req = fbUser.createProfileChangeRequest()
            req.displayName = fullName
            req.commitChanges { _ in
                signedInUser = SignedInUser(
                    id: fbUser.uid,
                    displayName: fullName,
                    email: fbUser.email ?? "(no email)"
                )
            }
        }
    }

    private func openURL(_ str: String) {
        guard let url = URL(string: str) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: – FloatingField helper

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

// MARK: – HomeView showing the signed-in user’s info

struct HomeView: View {
    let user: SignedInUser

    var body: some View {
        VStack(spacing: 16) {
            Text("🎉 Welcome, \(user.displayName)!")
                .font(.largeTitle.bold())
            Text("Email: \(user.email)")
                .font(.body)
            Text("UID: \(user.id)")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: – Hex string → Color initializer


#Preview {
    SignUpView()
}
