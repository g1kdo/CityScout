// ViewModels/ProfileViewModel.swift
import Foundation
import FirebaseAuth
import FirebaseFirestore
// REMOVE: import FirebaseStorage // No longer using Firebase Storage
import Combine
import PhotosUI // For image picking
import GoogleSignIn
import FBSDKLoginKit
import UIKit // For UIImage
import _PhotosUI_SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    // REMOVED: @Published var signedInUser: SignedInUser // Data comes from AuthenticationViewModel
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var location: String = ""
    @Published var mobileNumber: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var showingImagePicker: Bool = false
    @Published var selectedPhotoItem: PhotosPickerItem? = nil {
        didSet {
            Task {
                await loadSelectedImage()
            }
        }
    }
    @Published var profileImage: UIImage? // The image to display/upload (locally)

    private var db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()

    // We no longer take SignedInUser in init; we'll observe AuthenticationViewModel directly
    init() {
        // Initialization will now happen when AuthenticationViewModel provides the user
        // and fetchProfileData is called based on that user.
    }

    // New function to set up initial data and observers based on AuthenticationViewModel
    // This will be called from ProfileView or EditProfileView
    func setup(with user: SignedInUser?) {
        guard let user = user else { return }

        // Initialize editable fields with current user data
        self.firstName = user.firstName ?? ""
        self.lastName = user.lastName ?? ""
        self.location = user.location ?? ""
        self.mobileNumber = user.mobileNumber ?? ""

        // Load profile image from URL if available
        if let url = user.profilePictureURL {
            loadImageFromURL(url)
        }

        // Fetch additional profile data from Firestore (if needed, otherwise rely on SignedInUser data)
        // Only fetch if the user's ID is valid and not a dummy user
        if !user.id.isEmpty {
            fetchProfileData(for: user.id)
        }
    }


    // fetchProfileData now takes a uid to be more flexible, or relies on Auth.auth().currentUser
    func fetchProfileData(for uid: String? = nil) {
        let userID = uid ?? Auth.auth().currentUser?.uid

        guard let currentUID = userID else {
            errorMessage = "No authenticated user ID to fetch profile data for."
            return
        }

        isLoading = true
        db.collection("users").document(currentUID).getDocument { [weak self] document, error in
            guard let self = self else { return }
            self.isLoading = false
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                // Update local fields directly from Firestore data
                self.firstName = data["firstName"] as? String ?? self.firstName
                self.lastName = data["lastName"] as? String ?? self.lastName
                self.location = data["location"] as? String ?? self.location
                self.mobileNumber = data["mobileNumber"] as? String ?? self.mobileNumber

                // Update the local image if a URL is found in Firestore
                if let photoURLString = data["profilePictureURL"] as? String, let url = URL(string: photoURLString) {
                    self.loadImageFromURL(url)
                }

            } else if let error = error {
                self.errorMessage = "Error fetching profile data: \(error.localizedDescription)"
                print("Error fetching profile data: \(error.localizedDescription)")
            } else {
                self.errorMessage = "Profile data not found. It might be a new user or not yet saved."
                print("Profile data not found in Firestore for user: \(currentUID)")
            }
        }
    }

    func updateProfile(signedInUserFromAuthVM: SignedInUser?) async -> Bool {
        guard let firebaseUser = Auth.auth().currentUser else {
            errorMessage = "No authenticated user to update profile for."
            return false
        }
        guard let currentSignedInUser = signedInUserFromAuthVM else {
            errorMessage = "Current user data not available from AuthenticationViewModel."
            return false
        }


        isLoading = true
        errorMessage = ""

        var updatedFields: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "location": location,
            "mobileNumber": mobileNumber
        ]

        do {
            // Update Firebase Auth display name if first name is available and different
            let newDisplayName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
            if firebaseUser.displayName != newDisplayName {
                let changeRequest = firebaseUser.createProfileChangeRequest()
                changeRequest.displayName = newDisplayName
                try await changeRequest.commitChanges()
                print("Firebase Auth display name updated.")
            }

            // Handle profile image update:
            // If a new image was selected (profileImage is not nil),
            // and you want to update Firebase Auth's photoURL with a placeholder
            // or an external URL if you manage image hosting outside Firebase Storage.
            // For now, let's assume `profileImage` can be directly set to Firebase Auth's photoURL
            // if we were able to get a URL for it (e.g., from a pre-uploaded image service).
            // Since we're removing Firebase Storage, we'll simulate a change to photoURL
            // with a simple URL that *might* be provided by a different image service.
            // For a real app, you'd replace `uploadProfileImage` with your actual image upload logic.
            if let image = profileImage {
                // IMPORTANT: Replace this with your actual image hosting solution.
                // For demonstration, we'll set a placeholder or a default URL.
                // In a real app, 'uploadProfileImage' would send the image to your chosen service
                // and return its public URL.
                let mockNewPhotoURL = URL(string: "https://example.com/new_profile_pic_\(firebaseUser.uid).jpg") // Replace with actual hosted URL
                
                // Only update Firebase Auth photoURL if it's different
                if firebaseUser.photoURL?.absoluteString != mockNewPhotoURL?.absoluteString {
                    let changeRequest = firebaseUser.createProfileChangeRequest()
                    changeRequest.photoURL = mockNewPhotoURL // This must be a valid, accessible URL
                    try await changeRequest.commitChanges()
                    print("Firebase Auth photo URL updated to a new mock URL.")
                    updatedFields["profilePictureURL"] = mockNewPhotoURL?.absoluteString // Store in Firestore too
                }
            }


            // Update custom profile data in Firestore
            try await db.collection("users").document(firebaseUser.uid).setData(updatedFields, merge: true)

            // Force AuthenticationViewModel to reload user data
            // (You'll need a method in AuthenticationViewModel for this)
            // Example: NotificationCenter.default.post(name: .didUpdateUserProfile, object: nil)
            // Or, if AuthenticationViewModel has a direct dependency, call a method on it.
            // For now, assume AuthenticationViewModel re-fetches its user on its own or through a sink.
            // Or, you can pass a closure from AuthVM to update the user directly.

            print("Profile updated successfully in Firestore and Firebase Auth.")
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
            print("Error updating profile: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }

    // MARK: - Image Handling (Simplified - no actual upload without Firebase Storage)

    private func loadImageFromURL(_ url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = image
                }
            } else {
                print("Error loading image from URL: \(error?.localizedDescription ?? "Unknown error")")
            }
        }.resume()
    }

    private func loadSelectedImage() async {
        guard let selectedItem = selectedPhotoItem else { return }
        do {
            if let data = try await selectedItem.loadTransferable(type: Data.self) {
                if let image = UIImage(data: data) {
                    profileImage = image // Set the UIImage for local display
                }
            }
        } catch {
            errorMessage = "Failed to load selected image: \(error.localizedDescription)"
            print("Error loading selected image: \(error.localizedDescription)")
        }
    }

    // REMOVED: private func uploadProfileImage(...) - No Firebase Storage

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            LoginManager().logOut()

            // Reset local state
            self.firstName = ""
            self.lastName = ""
            self.location = ""
            self.mobileNumber = ""
            self.profileImage = nil
            self.errorMessage = ""

            print("User signed out successfully from Firebase and social providers.")
            // AuthenticationViewModel will observe Auth.auth().currentUser and update itself
        } catch {
            errorMessage = "Error signing out: \(error.localizedDescription)"
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
