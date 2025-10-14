// ViewModels/AuthenticationViewModel.swift
import Foundation
import FirebaseAuth
import SwiftUI
import FirebaseFirestore
import FirebaseMessaging

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
        
        // NEW: Subscribe to FCM token refreshes
        PushNotificationManager.shared.onTokenRefresh = { [weak self] token in
            guard let self = self, let userId = self.user?.uid else { return }
            self.signedInUser?.fcmToken = token
            Task {
                await self.saveFCMToken(token, for: userId)
            }
        }
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
                                
                                // NEW: Save FCM token on successful sign-in/load
                                if let token = Messaging.messaging().fcmToken {
                                    self.signedInUser?.fcmToken = token
                                    await self.saveFCMToken(token, for: fbUser.uid)
                                }
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
    
    // NEW: Method to save the FCM token to Firestore
    private func saveFCMToken(_ token: String, for userId: String) async {
        do {
            try await db.collection("users").document(userId).setData(["fcmToken": token], merge: true)
            print("FCM token saved successfully for user: \(userId)")
        } catch {
            print("Error saving FCM token: \(error.localizedDescription)")
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
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
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
    
    func setStatus(isOnline: Bool) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        
        // 1. Prepare the data to be written
        let statusData: [String: Any] = [
            "isOnline": isOnline,
            "lastSeen": Timestamp(date: Date())
        ]
        
        // 2. Determine the correct collection: Check /partners first
        let partnerDocRef = db.collection("partners").document(userId)
        
        do {
            let partnerDocument = try await partnerDocRef.getDocument()
            
            // 3. If the partner document exists, update the status there.
            if partnerDocument.exists {
                try await partnerDocRef.setData(statusData, merge: true)
                print("Status updated in partners collection for \(userId)")
            } else {
                // 4. If the partner document does NOT exist, assume it's a standard user and update the /users collection.
                let userDocRef = db.collection("users").document(userId)
                try await userDocRef.setData(statusData, merge: true)
                print("Status updated in users collection for \(userId)")
            }
            
        } catch {
            print("Error updating status for \(userId): \(error.localizedDescription)")
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
