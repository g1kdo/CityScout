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
    @Published var displayName: String = ""
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
    @Published var profileImage: UIImage?
    @Published var currentProfileImageURL: URL?

    private var db = Firestore.firestore()
    private var storage = Storage.storage()
    private var cancellables = Set<AnyCancellable>()

    private var reviewViewModel: ReviewViewModel
     
     // Initializer to inject ReviewViewModel
    init(reviewViewModel: ReviewViewModel) {
         self.reviewViewModel = reviewViewModel
     }
    

    func setup(with user: SignedInUser?) {
        guard let user = user else {
            self.displayName = ""
            self.location = ""
            self.mobileNumber = ""
            self.profileImage = nil
            self.currentProfileImageURL = nil
            return
        }

        self.displayName = user.displayName ?? ""
        self.location = user.location ?? ""
        self.mobileNumber = user.mobileNumber ?? ""

        if let customOrSocialPhotoURL = user.profilePictureAsURL {
            self.currentProfileImageURL = customOrSocialPhotoURL
            loadImageFromURL(customOrSocialPhotoURL)
        } else {
            self.profileImage = nil
            self.currentProfileImageURL = nil
        }

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
        db.collection("users").document(currentUID).getDocument { [weak self] document, error in
            guard let self = self else { return }
            self.isLoading = false
            if let document = document, document.exists {
                let data = document.data() ?? [:]

                self.displayName = data["displayName"] as? String ?? self.displayName
                self.location = data["location"] as? String ?? self.location
                self.mobileNumber = data["mobileNumber"] as? String ?? self.mobileNumber

                if let photoURLString = data["profilePictureURL"] as? String, let url = URL(string: photoURLString) {
                    self.currentProfileImageURL = url
                    self.loadImageFromURL(url)
                } else if let socialPhotoURL = Auth.auth().currentUser?.photoURL {
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
            "displayName": displayName,
            "location": location,
            "mobileNumber": mobileNumber
        ]

        var newPhotoURL: URL? = nil

        do {
            // Upload new profile image to Firebase Storage if selected
            if let image = profileImage, selectedPhotoItem != nil {
                newPhotoURL = try await uploadProfileImage(image, for: firebaseUser.uid)
                updatedFields["profilePictureURL"] = newPhotoURL?.absoluteString // Store the storage URL in Firestore
                print("New profile image uploaded and URL obtained: \(newPhotoURL?.absoluteString ?? "N/A")")
            } else if profileImage == nil && selectedPhotoItem == nil && currentProfileImageURL != nil {
                // If a custom image was previously set (currentProfileImageURL is not nil)
                // and the user has explicitly cleared the PhotosPicker selection (selectedPhotoItem is nil),
                // and profileImage is now nil (meaning it was not re-loaded from a URL or selected),
                // it implies the user wants to remove their custom profile picture.
                // We should remove it from Firestore and potentially Storage.
                // This requires a more explicit "clear photo" action to be safe,
                // but for now, we'll set it to nil in Firestore.
                updatedFields["profilePictureURL"] = FieldValue.delete() // Remove the field from Firestore
                newPhotoURL = nil // Ensure newPhotoURL is nil so Firebase Auth photoURL is also cleared or reverts to social.
                print("Custom profile image explicitly removed.")
            }


            // Update Firebase Auth display name
            let changeRequest = firebaseUser.createProfileChangeRequest()

            var authProfileChanged = false

            if firebaseUser.displayName != displayName {
                changeRequest.displayName = displayName
                authProfileChanged = true
                print("Firebase Auth display name set for update: \(displayName)")
            }

            // Update Firebase Auth photoURL if a new one was uploaded
            if let uploadedPhotoURL = newPhotoURL, firebaseUser.photoURL?.absoluteString != uploadedPhotoURL.absoluteString {
                changeRequest.photoURL = uploadedPhotoURL
                authProfileChanged = true
                print("Firebase Auth photoURL set for update to custom image.")
            } else if newPhotoURL == nil && firebaseUser.photoURL != nil && selectedPhotoItem == nil {
                // Scenario: No new photo uploaded, and current Firebase Auth photoURL is not nil.
                // If selectedPhotoItem is nil, it means the user explicitly deselected an image or didn't pick one.
                // This block handles clearing the Firebase Auth photoURL if it was previously set (custom or social)
                // and now no custom photo is chosen. We need to be careful not to clear social photos if that's the source.

                // To correctly handle social photoURLs, you might need to compare
                // `firebaseUser.photoURL` with the original social URL if available.
                // For simplicity, if newPhotoURL is nil and selectedPhotoItem is nil,
                // we assume if `currentProfileImageURL` (the source of truth from Firestore/Auth)
                // is also nil, then Auth photoURL should be cleared.
                if self.currentProfileImageURL == nil { // If no current image stored or selected
                    changeRequest.photoURL = nil
                    authProfileChanged = true
                    print("Firebase Auth photoURL set to nil (custom image removed or no image).")
                }
            }


            if authProfileChanged {
                try await changeRequest.commitChanges()
                print("Firebase Auth profile changes committed (display name and/or photoURL).")
            }

            try await db.collection("users").document(firebaseUser.uid).setData(updatedFields, merge: true)

            print("Profile updated successfully in Firestore.")

            // MARK: - Integration Point 2: Call updateReviewsProfilePicture
            // Only call this if the profile picture URL has actually changed or was explicitly cleared.
            let oldProfilePictureURL = signedInUserFromAuthVM?.profilePictureAsURL
            if newPhotoURL != oldProfilePictureURL {
                print("Profile picture URL changed. Updating reviews...")
                await reviewViewModel.updateReviewsProfilePicture(userId: firebaseUser.uid, newPictureURL: newPhotoURL)
            } else {
                print("Profile picture URL not changed, skipping review updates.")
            }

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
                DispatchQueue.main.async {
                    self.profileImage = nil
                }
            }
        }.resume()
    }

    private func loadSelectedImage() async {
        guard let selectedItem = selectedPhotoItem else {
            // If selectedPhotoItem becomes nil (e.g., user deselects), clear profileImage
            profileImage = nil
            currentProfileImageURL = nil // Also clear current URL to reflect no custom image
            return
        }
        do {
            if let data = try await selectedItem.loadTransferable(type: Data.self) {
                if let image = UIImage(data: data) {
                    profileImage = image
                    // When a new image is selected, the currentProfileImageURL should point to this potential new upload,
                    // but it will only be a concrete Firebase Storage URL after `uploadProfileImage` completes.
                    // For now, it's safer to let `updateProfile` set `currentProfileImageURL` after upload.
                    // Or, if you want to show the new image immediately, you could set `currentProfileImageURL`
                    // to a placeholder or wait for the actual upload URL.
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
            self.displayName = ""
            self.location = ""
            self.mobileNumber = ""
            self.profileImage = nil
            self.currentProfileImageURL = nil
            self.errorMessage = ""
            self.selectedPhotoItem = nil

            print("User signed out successfully from Firebase and social providers.")
        } catch {
            errorMessage = "Error signing out: \(error.localizedDescription)"
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
