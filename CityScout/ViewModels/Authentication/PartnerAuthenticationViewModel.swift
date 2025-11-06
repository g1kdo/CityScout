import Foundation
import FirebaseAuth
import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import PhotosUI
import UIKit
import CryptoKit

// Alias the provided Partner structure
typealias CityScoutPartner = Partner
// Assuming KeychainService is available and implemented as discussed

@MainActor
class PartnerAuthenticationViewModel: ObservableObject {
    // Input Fields for "Sign In" / Activation
    @Published var email = ""
    @Published var partnerDisplayName = ""
    @Published var phoneNumber = ""
    @Published var location = ""
    @Published var profilePictureURL: URL?

    // Image Handling
    @Published var selectedPhotoItem: PhotosPickerItem? // For PhotosUI binding
    @Published var profileImage: UIImage? // The loaded UIImage representation
    
    // State Management
    @Published var errorMessage = ""
    @Published var successMessage = ""
    @Published var showAlert: Bool = false
    @Published var isAuthenticating = false
    @Published var isAuthenticated = false

    @Published var isLoadingInitialData = true
    @Published var user: User?
    @Published var signedInPartner: CityScoutPartner?

    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let partnerCollection = "partners" // Dedicated collection for partners

    init() {
        registerAuthStateHandler()
        // Start the process by checking the current user/session
        Task { await checkCurrentUser() }
    }

    deinit {
        if let handle = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Auth State Listener
    
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
                            // Also clear Keychain if Firebase Auth state is good but Firestore role is bad
                            KeychainService.clearPartnerCredentials() 
                        }
                        self.isLoadingInitialData = false
                    }
                } else {
                    // Firebase User is NIL (signed out or session expired)
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
    
    // MARK: - Image Handling


    func loadImage(from item: PhotosPickerItem) {
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else {
                    throw NSError(domain: "PartnerAuthVM", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to load image data."])
                }
                await MainActor.run {
                    self.profileImage = uiImage
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load image: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
    

    private func uploadProfilePicture(userId: String, image: UIImage) async throws -> URL? {
        // Convert UIImage to JPEG Data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "PartnerAuthVM", code: 501, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to JPEG data."])
        }

        // Define storage path: partner_profiles/{userId}/profile.jpg
        let storageRef = storage.reference().child("partner_profiles/\(userId)/profile.jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        do {
            // Upload the data
            let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            
            // Get the download URL
            let downloadURL = try await storageRef.downloadURL()
            return downloadURL
        } catch {
            print("PartnerAuthVM: Error uploading profile picture: \(error.localizedDescription)")
            // Re-throw the error to be handled upstream
            throw error
        }
    }

    // MARK: - Core Activation / Sign In Logic
    
    func completeProfileAndActivate() async {

        guard !email.isEmpty, !partnerDisplayName.isEmpty, !phoneNumber.isEmpty, !location.isEmpty else {
            errorMessage = "Please fill in all required fields."
            showAlert = true
            return
        }

        isAuthenticating = true
        errorMessage = ""
        
        // --- 1. Query Firestore to find the pre-created partner document by email ---
        let querySnapshot: QuerySnapshot

        do {
             querySnapshot = try await db.collection(partnerCollection)
                .whereField("partnerEmail", isEqualTo: email.lowercased()) // Ensure email is lowercased for searching
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
            errorMessage = "This account is already activated. Attempting silent re-sign-in..."
            await attemptSilentResignIn() 
            isAuthenticating = false
            return
        }

        // --- 3. First-Time Activation Process ---
        do {
            // A. Generate Cryptographically Strong Session Key
            let sessionKey = KeyGeneratorAndHasher.generateSecretKey()
            
            // B. Create the Firebase Auth User using the secure key as the password
            let authResult = try await Auth.auth().createUser(withEmail: email, password: sessionKey)
            let userId = authResult.user.uid
            
            // C. **NEW:** Handle Profile Picture Upload if available
            var finalPhotoURL: URL? = nil
            if let image = self.profileImage {
                do {
                    finalPhotoURL = try await self.uploadProfilePicture(userId: userId, image: image)
                } catch {
                    // Log the error but don't halt the critical activation process
                    print("WARNING: Profile picture upload failed, continuing with other data: \(error.localizedDescription)")
                }
            }

            // D. Update Firestore Document with All Missing Data
            let partnerData: [String: Any] = [
                "id": userId, // Link the Firestore document to the Auth UID
                "partnerDisplayName": partnerDisplayName,
                "phoneNumber": phoneNumber,
                "location": location,
                "profilePictureURL": finalPhotoURL?.absoluteString ?? "" // Save the new URL
            ]
            
            // Use the document ID found in step 1 to update the existing document
            try await db.collection(partnerCollection).document(partnerDoc.documentID).updateData(partnerData)
            
            // E. **Crucial:** Save the PLAIN-TEXT 'sessionKey' securely on the device
            KeychainService.savePartnerSessionKey(sessionKey)
            KeychainService.savePartnerEmail(email)
            print("Activation successful. Key and email stored in Keychain.")
            
            successMessage = "Account activated and profile completed successfully! You are now signed in."
            showAlert = true
            
        } catch {
            errorMessage = "Activation failed: \(getAuthErrorMessage(error: error))"
            showAlert = true
        }
        
        isAuthenticating = false
    }
    
    // MARK: - Silent Re-Sign-In Logic
    
    /// Attempts to re-authenticate the user silently using the stored session key from the Keychain.
    private func attemptSilentResignIn() async {
        // Only run if we are definitely NOT signed in
        guard Auth.auth().currentUser == nil else {
            return 
        }

        // 1. Retrieve the secure credentials
        let storedSessionKey = KeychainService.retrievePartnerSessionKey()
        let storedEmail = KeychainService.retrievePartnerEmail()
        
        guard let sessionKey = storedSessionKey, let email = storedEmail else {
            print("PartnerAuthVM: Silent re-sign-in skipped. No credentials found in Keychain.")
            return
        }

        self.isAuthenticating = true
        self.isLoadingInitialData = true
        
        do {
            // 2. Perform a silent re-sign-in using the stored key as the password
            let _ = try await Auth.auth().signIn(withEmail: email, password: sessionKey)
            
            // Success: The authStateHandler takes over to load partner data.
            print("PartnerAuthVM: Successful silent re-sign-in via stored session key.")
            
        } catch {
            // 3. Failed re-sign-in (e.g., key/hash mismatch, Firebase user deleted)
            print("PartnerAuthVM: Silent re-sign-in failed. \(error.localizedDescription). Clearing credentials.")
            KeychainService.clearPartnerCredentials() // Clear the bad credentials
        }
        
        self.isAuthenticating = false
        // Note: isLoadingInitialData will be set to false by the authStateHandler
    }

    // MARK: - Standard Auth Functions
    
    func signOut() {
        do {
            // 1. Invalidate Firebase session
            try Auth.auth().signOut()
            
            // 2. Clear the secure credentials from the Keychain
            // KeychainService.clearPartnerCredentials()
            
            successMessage = "You have been signed out."
            showAlert = true
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // Helper to check for existing user on app launch
    func checkCurrentUser() async {
        // 1. Check for persistent session first (automatic Firebase feature)
        guard let fbUser = Auth.auth().currentUser else {
            // 2. If no persistent session, attempt to re-authenticate using the stored key
            await attemptSilentResignIn()
            
            // 3. Final check to ensure state is clear if silent sign-in failed
            if Auth.auth().currentUser == nil {
                self.isLoadingInitialData = false
                self.signedInPartner = nil
                self.isAuthenticated = false
            }
            return
        }

        // This path is taken if Firebase successfully restored the session
        self.isLoadingInitialData = true
        do {
            self.signedInPartner = try await fetchPartnerData(for: fbUser.uid)
            self.isAuthenticated = true
            print("PartnerAuthVM: Existing partner loaded via persistent session.")
        } catch {
            print("PartnerAuthVM: Failed to load partner data for existing user: \(error.localizedDescription). Forcing sign out and clearing key.")
            self.signedInPartner = nil
            self.isAuthenticated = false
            try? Auth.auth().signOut()
            KeychainService.clearPartnerCredentials() // Clear key if the user is somehow corrupted
        }
        self.isLoadingInitialData = false
    }

    private func getAuthErrorMessage(error: Error) -> String {
        if let errorCode = AuthErrorCode(rawValue: (error as NSError).code) {
            switch errorCode {
            case .emailAlreadyInUse:
                return "The email is already registered in our system. Attempting silent re-sign-in..."
            case .invalidEmail:
                return "The email address is not valid."
            default:
                return "Sign in/Activation failed: \(error.localizedDescription)"
            }
        }
        return "An unknown error occurred."
    }
    
    // MARK: - Data Refresh
        
        /// Refreshes the signed-in partner's data from Firestore.
        func refreshPartnerData() async {
            guard let firebaseUser = Auth.auth().currentUser else {
                print("PartnerAuthVM: No Firebase user to refresh data for.")
                return
            }
            
            isAuthenticating = true // Show loading
            do {
                // Re-fetch the partner data from the "partners" collection
                self.signedInPartner = try await fetchPartnerData(for: firebaseUser.uid)
                print("PartnerAuthVM: SignedInPartner data refreshed from Firestore.")
            } catch {
                print("PartnerAuthVM: Error refreshing partner data: \(error.localizedDescription)")
                // You could set self.errorMessage here if needed
            }
            isAuthenticating = false // Hide loading
        }
}
