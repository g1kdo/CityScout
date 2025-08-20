// ViewModels/AuthenticationViewModel.swift
import Foundation
import FirebaseAuth
import SwiftUI
import FirebaseFirestore

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage = ""
    @Published var successMessage = ""
    @Published var showAlert: Bool = false
    @Published var isAuthenticating = false
    @Published var isAuthenticated = false

    @Published var isLoadingInitialData = true
    @Published var user: User? // Firebase User object
    @Published var signedInUser: SignedInUser? // Your custom app-specific user object

    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private var db = Firestore.firestore() // Firestore instance

   // private let appId: String = "cityscoutapp-935ad"

    init() {
        registerAuthStateHandler()
        Task { await checkCurrentUser() }
    }

    deinit {
        if let handle = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    private func registerAuthStateHandler() {
            if authStateHandler == nil {
                authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
                    guard let self = self else { return }
                    self.user = firebaseUser
                    self.isAuthenticated = firebaseUser != nil
                    
                    if let fbUser = firebaseUser {
                        self.isLoadingInitialData = true // Start loading when a user is found
                        Task {
                            do {
                                self.signedInUser = try await self.createSignedInUser(from: fbUser)
                                print("AuthenticationViewModel: SignedInUser updated for: \(self.signedInUser?.email ?? "N/A")")
                            } catch {
                                print("AuthenticationViewModel: Error creating SignedInUser from Firebase user: \(error.localizedDescription)")
                                self.signedInUser = nil
                                self.isAuthenticated = false
                            }
                            self.isLoadingInitialData = false // Stop loading after data is fetched
                        }
                    } else {
                        self.signedInUser = nil
                        self.isAuthenticated = false
                        self.isLoadingInitialData = false // Stop loading if no user is found
                    }
                }
            }
        }

    // Function to create a SignedInUser from a Firebase.User object and fetch Firestore data
    func createSignedInUser(from firebaseUser: FirebaseAuth.User) async throws -> SignedInUser {
        var user = SignedInUser(
            id: firebaseUser.uid,
            displayName: firebaseUser.displayName,
            email: firebaseUser.email ?? "",
            profilePictureURL: firebaseUser.photoURL
        )
        
        let docRef = db.collection("users").document(firebaseUser.uid)

        do {
            let document = try await docRef.getDocument()
            if document.exists {
                let data = document.data() ?? [:]
                user.updateWithProfileData(data)
            } else {
                // If the user document doesn't exist, this is a new user
                // We set 'hasSetInterests' to false to start the onboarding flow
                user.hasSetInterests = false
                try docRef.setData(from: user, merge: true)
                print("AuthenticationViewModel: New user document created with 'hasSetInterests' as false.")
            }
        } catch {
            print("AuthenticationViewModel: Error fetching or setting initial user data: \(error.localizedDescription)")
        }
        return user
    }
    
    // New method to explicitly refresh signedInUser from Firestore
    func refreshSignedInUserFromFirestore() async {
        guard let firebaseUser = Auth.auth().currentUser else {
            print("AuthenticationViewModel: No Firebase user to refresh from Firestore.")
            self.signedInUser = nil
            return
        }
        isAuthenticating = true // Use isAuthenticating for loading state
        errorMessage = ""
        do {
            self.signedInUser = try await createSignedInUser(from: firebaseUser)
            print("AuthenticationViewModel: SignedInUser refreshed from Firestore.")
            errorMessage = "" // Clear any previous error
        } catch {
            errorMessage = "Failed to refresh user data: \(error.localizedDescription)"
            print("AuthenticationViewModel: Error refreshing user from Firestore: \(error.localizedDescription)")
        }
        isAuthenticating = false // Use isAuthenticating for loading state
    }


    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            showAlert = true
            return
        }

        isAuthenticating = true // Use isAuthenticating
        errorMessage = ""
        successMessage = ""

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            // The authStateHandler will pick up result.user and update signedInUser
            successMessage = "Signed in successfully! Welcome back."
            showAlert = true
        } catch {
            errorMessage = getAuthErrorMessage(error: error)
            showAlert = true
        }
        isAuthenticating = false // Use isAuthenticating
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            // The authStateHandler will clear `user` and `signedInUser`
            successMessage = "You have been signed out."
            showAlert = true
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // Helper to check for existing user on app launch
    func checkCurrentUser() async {
           guard Auth.auth().currentUser != nil else {
               // No user is signed in, so we are not loading.
               self.isLoadingInitialData = false
               self.signedInUser = nil
               self.isAuthenticated = false
               return
           }

           // A user is signed in, so we must load their data.
           self.isLoadingInitialData = true
           do {
               self.signedInUser = try await createSignedInUser(from: Auth.auth().currentUser!)
               self.isAuthenticated = true
               print("AuthenticationViewModel: Existing user loaded from Firebase Auth and Firestore.")
           } catch {
               print("AuthenticationViewModel: Failed to load existing user data: \(error.localizedDescription)")
               self.signedInUser = nil
               self.isAuthenticated = false
               try? Auth.auth().signOut()
           }
           self.isLoadingInitialData = false // Set to false after the operation is complete
       }
    
    private func getAuthErrorMessage(error: Error) -> String {
        if let errorCode = AuthErrorCode(rawValue: (error as NSError).code) {
            switch errorCode {
            case .userNotFound:
                return "No account found with this email. Please check your email or sign up."
            case .wrongPassword:
                return "Incorrect password. Please try again."
            case .invalidEmail:
                return "The email address is not valid."
            case .networkError:
                return "Network error. Please check your internet connection."
            case .userDisabled:
                return "Your account has been disabled. Please contact support."
            default:
                return "Sign in failed: \(error.localizedDescription)"
            }
        }
        return "An unknown error occurred during sign in."
    }
}
