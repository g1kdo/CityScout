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

    @Published var user: User? // Firebase User object
    @Published var signedInUser: SignedInUser? // Your custom app-specific user object

    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private var db = Firestore.firestore() // Firestore instance

    private let appId: String = "cityscoutapp-935ad"

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
                self.isAuthenticating = true // Set to true while fetching user data

                // Set isAuthenticated immediately based on Firebase user presence
                self.isAuthenticated = firebaseUser != nil

                // Attempt to create/update SignedInUser from Firebase user
                if let fbUser = firebaseUser {
                    Task {
                        do {
                            self.signedInUser = try await self.createSignedInUser(from: fbUser)
                            // isAuthenticated is already set above, no need to re-set here unless logic changes
                            print("AuthenticationViewModel: SignedInUser updated for: \(self.signedInUser?.email ?? "N/A")")
                        } catch {
                            print("AuthenticationViewModel: Error creating SignedInUser from Firebase user: \(error.localizedDescription)")
                            self.signedInUser = nil // Clear if there's an error
                            self.isAuthenticated = false // Ensure false if creation fails
                        }
                        self.isAuthenticating = false // Done fetching
                    }
                } else {
                    self.signedInUser = nil // No Firebase user, no SignedInUser
                    self.isAuthenticated = false
                    self.isAuthenticating = false // Done fetching
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
            profilePictureURL: firebaseUser.photoURL // This will now correctly convert URL to String
        )

        // Attempt to fetch additional profile data from Firestore
        // CORRECTED FIRESTORE PATH:
        // Using the structure: /artifacts/{appId}/users/{userId}/userProfiles/{userId}
        let docRef = db.collection("artifacts").document(appId).collection("users").document(firebaseUser.uid).collection("userProfiles").document(firebaseUser.uid)
        do {
            let document = try await docRef.getDocument()
            if document.exists {
                let data = document.data() ?? [:]
                user.updateWithProfileData(data) // Update SignedInUser with Firestore data
                print("AuthenticationViewModel: Firestore profile data fetched for \(firebaseUser.email ?? "N/A").")
            } else {
                print("AuthenticationViewModel: No Firestore profile data found for \(firebaseUser.email ?? "N/A"). Creating new document.")
                // If no Firestore document exists, ensure the initial user object is saved to Firestore
                // This handles cases where a user signs in but hasn't created a profile yet.
                // The SignedInUser struct must conform to Encodable for setData(from:)
                try docRef.setData(from: user, merge: true) // Use merge to avoid overwriting if partial data exists
            }
        } catch {
            print("AuthenticationViewModel: Error fetching or setting initial user data from Firestore: \(error.localizedDescription)")
            // Continue even if Firestore fetch/set fails, as user might still be logged in via Auth.
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
        if let firebaseUser = Auth.auth().currentUser {
            isAuthenticating = true // Use isAuthenticating
            do {
                self.signedInUser = try await createSignedInUser(from: firebaseUser)
                self.isAuthenticated = true
                print("AuthenticationViewModel: Existing user loaded from Firebase Auth and Firestore.")
            } catch {
                print("AuthenticationViewModel: Failed to load existing user data: \(error.localizedDescription)")
                self.signedInUser = nil
                self.isAuthenticated = false
                try? Auth.auth().signOut() // Force sign out if data load fails
            }
            isAuthenticating = false // Use isAuthenticating
        } else {
            self.signedInUser = nil
            self.isAuthenticated = false
        }
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
