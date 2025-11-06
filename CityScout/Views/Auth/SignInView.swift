import SwiftUI
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn // Added for GIDSignIn, needed for signOut if social is linked
import FacebookLogin // Added for FacebookLogin, needed for signOut if social is linked

struct SignInView: View {
    @StateObject private var viewModel = AuthenticationViewModel() // Main auth VM
    @StateObject private var googleAuthViewModel = GoogleAuthViewModel()
    @StateObject private var appleAuthViewModel = AppleAuthViewModel()
    @StateObject private var facebookAuthViewModel = FacebookAuthViewModel()
    @StateObject private var partnerVM = PartnerAuthenticationViewModel()

    // No longer need shouldNavigateHome, we'll observe viewModel.user
    // @State private var shouldNavigateHome = false
    @State private var isSignUpActive = false
    @State private var isForgotPasswordActive = false
    @State private var isPartner = false

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
        // Observe changes to viewModel.user to navigate
        .fullScreenCover(item: $viewModel.signedInUser) { signedInUser in
            // Pass the signedInUser object to HomeView
            HomeView()
                .environmentObject(viewModel) // Pass the authentication view model
        }
        .navigationDestination(isPresented: $isSignUpActive) {
            SignUpView() // Assuming you have a SignUpView
                .environmentObject(viewModel) // Pass authVM to SignUpView as well
        }
        .navigationDestination(isPresented: $isForgotPasswordActive) {
            ForgotPasswordView()
                .environmentObject(viewModel)
        }
        .navigationDestination(isPresented: $isPartner) {
            PartnerSignUpView()
                .environmentObject(partnerVM)
        }
        .onAppear {
            // Check if a user is already signed in when the view appears
            Task {
                await viewModel.checkCurrentUser()
            }
        }
    }

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
            Button("I am a partner") {
                isPartner = true
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(Color(hex: "#FF7029"))
            Spacer()
            Button("Forgot Password?") {
                isForgotPasswordActive = true
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(Color(hex: "#FF7029"))

        }
    }

    private var signInButton: some View {
        Button {
            Task {
                await viewModel.signIn()
                // No need to set shouldNavigateHome here, the .fullScreenCover will react to viewModel.user
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
                    if (await googleAuthViewModel.signInWithGoogle()) != nil {
                        print("Successfully signed in with Google")
//                        viewModel.user = try await viewModel.createSignedInUser(from: firebaseUser)
                    } else {
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
                Task {
                    // Assuming facebookAuthViewModel.signInWithFacebook() also returns FirebaseAuth.User?
                    if (await facebookAuthViewModel.signInWithFacebook()) != nil {
                        print("Successfully signed in with Facebook")
//                        viewModel.user = try await viewModel.createSignedInUser(from: firebaseUser)
                    } else {
                        viewModel.errorMessage = facebookAuthViewModel.errorMessage
                        viewModel.showAlert = true
                    }
                }
            } label: {
                Image("facebook_logo")
                    .resizable()
                    .frame(width: 40, height: 40)
            }
            // Apple Sign-in integration would also need to result in a `FirebaseAuth.User`
            Button {
               // appleAuthViewModel.startSignInWithAppleFlow() // This will likely need a completion handler or publisher
                // You'll need to observe the appleAuthViewModel for successful sign-in
                // and then call viewModel.createSignedInUser(from: firebaseUser)
                // and set viewModel.user.
                Task {
                    if (await appleAuthViewModel.startSignInWithAppleFlow()) != nil {
                                   print("Successfully signed in with Apple")
                                   // The authStateDidChangeListener in AuthenticationViewModel
                                   // will automatically pick up this firebaseUser and
                                   // update viewModel.signedInUser. No need to assign here.
                               } else {
                                   // Handle the case where Apple sign-in failed or was cancelled
                                   // The errorMessage should already be set by appleAuthViewModel
                                   viewModel.errorMessage = appleAuthViewModel.errorMessage
                                   viewModel.showAlert = true
                               }
                           }
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
