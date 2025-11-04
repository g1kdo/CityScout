import Foundation
import FirebaseAuth
import SwiftUI
import FirebaseFirestore
import FirebaseMessaging
import CryptoKit

// Alias the provided Partner structure
typealias CityScoutPartner = Partner

@MainActor
class PartnerAuthenticationViewModel: ObservableObject {
    // Input Fields for "Sign In" / Activation
    @Published var email = ""
    @Published var fullName = "" // User input
    @Published var phoneNumber = "" // User input
    @Published var location = "" // User input
    
    // State Management
    @Published var errorMessage = ""
    @Published var successMessage = ""
    @Published var showAlert: Bool = false
    @Published var isAuthenticating = false
    @Published var isAuthenticated = false

    @Published var isLoadingInitialData = true
    @Published var user: User? // Firebase User object
    @Published var signedInPartner: CityScoutPartner? // Your custom partner object

    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()
    private let partnerCollection = "partners" // Dedicated collection for partners

    init() {
        registerAuthStateHandler()
        Task { await checkCurrentUser() }
        
        // Removed FCM token logic for brevity and focus, but keep it if needed.
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
                    self.isLoadingInitialData = true
                    Task {
                        do {
                            // Ensure the user is a Partner and load data
                            self.signedInPartner = try await self.fetchPartnerData(for: fbUser.uid)
                            print("PartnerAuthVM: SignedInPartner data loaded for: \(self.signedInPartner?.partnerEmail ?? "N/A")")
                        } catch {
                            print("PartnerAuthVM: Error loading partner data. The user is not a partner or data is corrupt: \(error.localizedDescription)")
                            self.signedInPartner = nil
                            // Force sign out if they successfully authenticated but aren't a partner
                            try? Auth.auth().signOut()
                        }
                        self.isLoadingInitialData = false
                    }
                } else {
                    self.signedInPartner = nil
                    self.isAuthenticated = false
                    self.isLoadingInitialData = false
                }
            }
        }
    }
    
    /// Fetches partner data from the /partners collection
    private func fetchPartnerData(for userId: String) async throws -> CityScoutPartner {
        let docRef = db.collection(partnerCollection).document(userId)
        let document = try await docRef.getDocument()
        
        guard document.exists else {
            throw NSError(domain: "PartnerAuthVM", code: 404, userInfo: [NSLocalizedDescriptionKey: "Partner document not found in Firestore."])
        }
        
        return try document.data(as: CityScoutPartner.self)
    }

    // MARK: - Core Activation / Sign In Logic
    
    /// This function serves as the "Sign In" button action.
    /// It checks for a persistent session first, otherwise it triggers the activation flow.
    func completeProfileAndActivate() async {
        guard !email.isEmpty, !fullName.isEmpty, !phoneNumber.isEmpty, !location.isEmpty else {
            errorMessage = "Please fill in all fields (Email, Full Name, Phone, and Location) to activate your account."
            showAlert = true
            return
        }

        // If a user is already authenticated (persistent session), no action needed
        guard user == nil else {
            successMessage = "You are already signed in."
            showAlert = true
            return
        }

        isAuthenticating = true
        errorMessage = ""
        
        // --- 1. Query Firestore to find the pre-created partner document by email ---
        let querySnapshot: QuerySnapshot
        do {
            querySnapshot = try await db.collection(partnerCollection)
                .whereField("partnerEmail", isEqualTo: email)
                .getDocuments()
        } catch {
            errorMessage = "Failed to check partner database: \(error.localizedDescription)"
            showAlert = true
            isAuthenticating = false
            return
        }
        
        guard let partnerDoc = querySnapshot.documents.first else {
            errorMessage = "Partner account not found with this email. Please contact support to be added."
            showAlert = true
            isAuthenticating = false
            return
        }
        
        // --- 2. Check if the Partner is already activated (has a UID) ---
        if let currentUID = partnerDoc.data()["id"] as? String, currentUID.isEmpty == false {
            // This case means the Auth user exists, but the session somehow expired or was cleared.
            // Since the user is not providing a password, we must rely on a persistent session
            // or a secondary secure flow (like email link or a recovery/key system) to re-authenticate.
            // For now, we simply inform them.
            errorMessage = "This account is already activated. Please restart the app or ensure your email/password credentials aren't needed to use the persistent session."
            showAlert = true
            isAuthenticating = false
            return
        }

        // --- 3. First-Time Activation Process ---
        do {
            // A. Generate Cryptographically Strong Session Key (used as Firebase Auth Password)
            let sessionKey = KeyGeneratorAndHasher.generateSecretKey()
            guard let (salt, hash) = KeyGeneratorAndHasher.hashSecretKey(sessionKey) else {
                throw NSError(domain: "PartnerAuthVM", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to generate secure session key."])
            }
            
            // B. Create the Firebase Auth User using the secure key as the password
            let authResult = try await Auth.auth().createUser(withEmail: email, password: sessionKey)
            let userId = authResult.user.uid
            
            // C. Update Firestore Document with All Missing Data
            let updateData: [String: Any] = [
                "id": userId, // Set the Firestore document ID to the Firebase UID
                "fullName": fullName,
                "phoneNumber": phoneNumber,
                "location": location,
                "sessionKeyHash": hash,
                "sessionKeySalt": salt,
                "partnerEmail": email, // Ensure email is correctly merged
            ]
            
            // Update the document using its existing reference
            try await partnerDoc.reference.setData(updateData, merge: true)
            
            // D. **Crucial:** Save the PLAIN-TEXT 'sessionKey' securely on the device (e.g., iOS Keychain)
            // In a real app, this key would be used to generate/refresh persistent session tokens.
            print("--- ACTIVATION SUCCESSFUL ---")
            print("The session key: \(sessionKey) should be securely stored in the iOS KEYCHAIN for persistent login.")
            print("--- --------------------- ---")
            
            // E. Final Sign In (already done by createUser, but ensures state is handled)
            // The authStateHandler will now pick up the user and load the updated partner data.
            
            successMessage = "Account activated and profile completed successfully! You are now signed in."
            showAlert = true
            
        } catch {
            // If createUser or setData fails, show the error
            errorMessage = "Activation failed: \(getAuthErrorMessage(error: error))"
            showAlert = true
        }
        
        isAuthenticating = false
    }
    
    // MARK: - Standard Auth Functions
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            // In a real app, clear the securely stored sessionKey from the Keychain here
            successMessage = "You have been signed out."
            showAlert = true
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // Helper to check for existing user on app launch
    func checkCurrentUser() async {
        guard let fbUser = Auth.auth().currentUser else {
            self.isLoadingInitialData = false
            self.signedInPartner = nil
            self.isAuthenticated = false
            return
        }

        self.isLoadingInitialData = true
        do {
            self.signedInPartner = try await fetchPartnerData(for: fbUser.uid)
            self.isAuthenticated = true
            print("PartnerAuthVM: Existing partner loaded via persistent session.")
        } catch {
            print("PartnerAuthVM: Failed to load partner data for existing user: \(error.localizedDescription). Forcing sign out.")
            self.signedInPartner = nil
            self.isAuthenticated = false
            // Clear bad session
            try? Auth.auth().signOut()
        }
        self.isLoadingInitialData = false
    }

    private func getAuthErrorMessage(error: Error) -> String {
        if let errorCode = AuthErrorCode(rawValue: (error as NSError).code) {
            switch errorCode {
            case .emailAlreadyInUse:
                // This means the Auth account exists, but the Firestore check failed to identify it as activated.
                return "The email is already registered in our system. You must rely on the persistent session mechanism to sign in."
            case .invalidEmail:
                return "The email address is not valid."
            default:
                return "Sign in/Activation failed: \(error.localizedDescription)"
            }
        }
        return "An unknown error occurred."
    }
}
