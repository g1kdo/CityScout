// ViewModels/ProfileViewModel.swift
import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine
import PhotosUI
import GoogleSignIn
import FBSDKLoginKit
import UIKit
import _PhotosUI_SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var displayName: String = "" // New: for full name or display name
    @Published var location: String = ""
    @Published var mobileNumber: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var showingImagePicker: Bool = false // This might not be strictly needed with PhotosPicker
    @Published var selectedPhotoItem: PhotosPickerItem? = nil {
        didSet {
            Task {
                await loadSelectedImage()
            }
        }
    }
    @Published var profileImage: UIImage? // The image to display/upload (locally)
    @Published var currentProfileImageURL: URL? // Store the current URL, whether from social or custom upload

    private var db = Firestore.firestore()
    private var storage = Storage.storage() // Initialize Firebase Storage
    private var cancellables = Set<AnyCancellable>()

   // private let appId: String = "cityscoutapp-935ad" // Example: Use your Firebase Project ID here

    init() { }

    func setup(with user: SignedInUser?) {
        guard let user = user else {
            // Clear all fields if no user is provided (e.g., user logged out)
            self.displayName = "" // Clear display name
            self.location = ""
            self.mobileNumber = ""
            self.profileImage = nil
            self.currentProfileImageURL = nil
            return
        }

        // Initialize editable fields with current user data.
        self.displayName = user.displayName ?? "" // Use displayName
        self.location = user.location ?? ""
        self.mobileNumber = user.mobileNumber ?? ""

        // Use the helper property `profilePictureAsURL` from SignedInUser
        // This prioritizes the Firestore-stored URL (if exists) over Firebase Auth's photoURL
        if let customOrSocialPhotoURL = user.profilePictureAsURL {
            self.currentProfileImageURL = customOrSocialPhotoURL
            loadImageFromURL(customOrSocialPhotoURL)
        } else {
            self.profileImage = nil
            self.currentProfileImageURL = nil
        }

        // Fetch additional profile data from Firestore (if needed, otherwise rely on SignedInUser data)
        if let userID = user.id, !userID.isEmpty {
            fetchProfileData(for: userID)
        }
    }

    func fetchProfileData(for uid: String? = nil) {
        let userID = uid ?? Auth.auth().currentUser?.uid

        guard let currentUID = userID else {
            errorMessage = "No authenticated user ID to fetch profile data for."
            return
        }

        isLoading = true
        // CORRECTED FIRESTORE PATH:
        // Using the structure: /artifacts/{appId}/users/{userId}/userProfiles/{userId}
//        db.collection("artifacts").document(appId).collection("users").document(currentUID).collection("userProfiles").document(currentUID).getDocument { [weak self] document, error in

        db.collection("users").document(currentUID).getDocument { [weak self] document, error in

            guard let self = self else { return }
            self.isLoading = false
            if let document = document, document.exists {
                let data = document.data() ?? [:]

                // Update local fields directly from Firestore data
                self.displayName = data["displayName"] as? String ?? self.displayName // Use displayName from Firestore
                self.location = data["location"] as? String ?? self.location
                self.mobileNumber = data["mobileNumber"] as? String ?? self.mobileNumber

                // Update the local image URL if a URL string is found in Firestore.
                if let photoURLString = data["profilePictureURL"] as? String, let url = URL(string: photoURLString) {
                    self.currentProfileImageURL = url
                    self.loadImageFromURL(url)
                } else if let socialPhotoURL = Auth.auth().currentUser?.photoURL {
                    // Fallback to Firebase Auth's photoURL (which might be from social login)
                    self.currentProfileImageURL = socialPhotoURL
                    self.loadImageFromURL(socialPhotoURL)
                } else {
                    self.currentProfileImageURL = nil
                    self.profileImage = nil
                }
                print("Firestore data fetched and applied.")

            } else if let error = error {
                self.errorMessage = "Error fetching profile data: \(error.localizedDescription)"
                print("Error fetching profile data: \(error.localizedDescription)")
            } else {
                self.errorMessage = "Profile data not found. It might be a new user or not yet saved."
                print("Profile data not found in Firestore for user: \(currentUID)")
                // If no profile data exists in Firestore, but user is logged in via social,
                // ensure we still display the social profile picture if available.
                if let socialPhotoURL = Auth.auth().currentUser?.photoURL {
                    self.currentProfileImageURL = socialPhotoURL
                    self.loadImageFromURL(socialPhotoURL)
                }
            }
        }
    }

    func updateProfile(signedInUserFromAuthVM: SignedInUser?) async -> Bool {
        guard let firebaseUser = Auth.auth().currentUser else {
            errorMessage = "No authenticated user to update profile for."
            return false
        }

        isLoading = true
        errorMessage = ""

        var updatedFields: [String: Any] = [
            "displayName": displayName, // Use displayName
            "location": location,
            "mobileNumber": mobileNumber
        ]

        var newPhotoURL: URL? = nil

        do {
            // Upload new profile image to Firebase Storage if selected
            if let image = profileImage, selectedPhotoItem != nil { // Check if a new image was actually selected
                newPhotoURL = try await uploadProfileImage(image, for: firebaseUser.uid)
                updatedFields["profilePictureURL"] = newPhotoURL?.absoluteString // Store the storage URL in Firestore
                print("New profile image uploaded and URL obtained: \(newPhotoURL?.absoluteString ?? "N/A")")
            } else if profileImage == nil && selectedPhotoItem == nil && currentProfileImageURL != nil {
                // Scenario: User had a custom image, but now no new image is selected and no PhotosPickerItem.
                // This could imply they want to remove their custom image.
                // You might want to delete the old image from storage and clear the URL.
                // For now, if profileImage is nil and selectedPhotoItem is nil, we assume no change
                // or a desire to revert to social if that was the original.
                // To explicitly remove a custom image, you'd need a "Remove Photo" button.
                // If you want to clear it from Firestore when `profileImage` is nil and `selectedPhotoItem` is nil,
                // you would set `updatedFields["profilePictureURL"] = FieldValue.delete()`
            }

            // Update Firebase Auth display name
            let changeRequest = firebaseUser.createProfileChangeRequest()

            var authProfileChanged = false

            if firebaseUser.displayName != displayName {
                changeRequest.displayName = displayName // Set display name
                authProfileChanged = true
                print("Firebase Auth display name set for update: \(displayName)")
            }

            // Update Firebase Auth photoURL if a new one was uploaded
            // ONLY if newPhotoURL is set (meaning a custom image was uploaded)
            if let uploadedPhotoURL = newPhotoURL, firebaseUser.photoURL?.absoluteString != uploadedPhotoURL.absoluteString {
                changeRequest.photoURL = uploadedPhotoURL
                authProfileChanged = true
                print("Firebase Auth photoURL set for update to custom image.")
            } else if newPhotoURL == nil && selectedPhotoItem == nil {
                // If no new image was uploaded and no PhotosPickerItem was selected,
                // and the current Firebase Auth photoURL is different from the original social one,
                // it means a custom image was previously set and now potentially "cleared" by not selecting a new one.
                // If `currentProfileImageURL` is nil here, it means no image at all.
                // If `signedInUserFromAuthVM?.profilePictureAsURL` is nil, it means no social image either.
                // This logic determines if Firebase Auth's photoURL should be cleared.
                if firebaseUser.photoURL != nil && signedInUserFromAuthVM?.profilePictureAsURL == nil {
                    // This scenario implies clearing the photoURL in Firebase Auth if it was a custom one
                    // and no new image is selected, and there's no social fallback.
                    changeRequest.photoURL = nil
                    authProfileChanged = true
                    print("Firebase Auth photoURL set to nil (custom image removed).")
                }
            }


            if authProfileChanged {
                try await changeRequest.commitChanges()
                print("Firebase Auth profile changes committed (display name and/or photoURL).")
            }

            // CORRECTED FIRESTORE PATH:
            // Using the structure: /artifacts/{appId}/users/{userId}/userProfiles/{userId}
//            try await db.collection("artifacts").document(appId).collection("users").document(firebaseUser.uid).collection("userProfiles").document(firebaseUser.uid).setData(updatedFields, merge: true)

            try await db.collection("users").document(firebaseUser.uid).setData(updatedFields, merge: true)

            print("Profile updated successfully in Firestore.")

            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
            print("Error updating profile: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }

    // MARK: - Image Handling with Firebase Storage

    private func loadImageFromURL(_ url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = image
                }
            } else {
                print("Error loading image from URL: \(error?.localizedDescription ?? "Unknown error")")
                // If image from URL fails to load, clear it locally
                DispatchQueue.main.async {
                    self.profileImage = nil
                }
            }
        }.resume()
    }

    private func loadSelectedImage() async {
        guard let selectedItem = selectedPhotoItem else { return }
        do {
            if let data = try await selectedItem.loadTransferable(type: Data.self) {
                if let image = UIImage(data: data) {
                    profileImage = image // Set the UIImage for local display
                    print("Selected image loaded into profileImage.")
                }
            }
        } catch {
            errorMessage = "Failed to load selected image: \(error.localizedDescription)"
            print("Error loading selected image: \(error.localizedDescription)")
        }
    }

    private func uploadProfileImage(_ image: UIImage, for userID: String) async throws -> URL {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ProfileViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to JPEG data."])
        }

        // CORRECTED STORAGE PATH:
        // Using the structure: /artifacts/{appId}/users/{userId}/profile_images/{fileName}
//        let storageRef = storage.reference().child("artifacts/\(appId)/users/\(userID)/profile_images/\(userID).jpg")
        let storageRef = storage.reference().child("users/\(userID)/profile_images/\(userID).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        return try await withCheckedThrowingContinuation { continuation in
            storageRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    print("Error uploading image to Firebase Storage: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }

                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error getting download URL: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let downloadURL = url else {
                        let noURLError = NSError(domain: "ProfileViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Download URL not found."])
                        continuation.resume(throwing: noURLError)
                        return
                    }
                    print("Image uploaded successfully, download URL: \(downloadURL.absoluteString)")
                    continuation.resume(returning: downloadURL)
                }
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            LoginManager().logOut()

            // Reset local state
            self.displayName = "" // Clear display name
            self.location = ""
            self.mobileNumber = ""
            self.profileImage = nil
            self.currentProfileImageURL = nil // Clear the stored URL
            self.errorMessage = ""
            self.selectedPhotoItem = nil // Clear the photos picker selection

            print("User signed out successfully from Firebase and social providers.")
        } catch {
            errorMessage = "Error signing out: \(error.localizedDescription)"
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
