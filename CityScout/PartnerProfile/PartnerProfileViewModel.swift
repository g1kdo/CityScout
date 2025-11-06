//
//  PartnerProfileViewModel.swift
//  CityScout
//  (Place in a folder like CityScout/ViewModels/PartnerProfile)
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine
import PhotosUI
import UIKit
import _PhotosUI_SwiftUI

@MainActor
class PartnerProfileViewModel: ObservableObject {
    @Published var partnerDisplayName: String = ""
    @Published var location: String = ""
    @Published var phoneNumber: String = ""
    
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
    
    // This VM is simpler and doesn't need the ReviewViewModel dependency
    init() {}
    
    /// Configures the ViewModel with data from the currently signed-in partner
    func setup(with partner: CityScoutPartner?) {
        guard let partner = partner else {
            self.partnerDisplayName = ""
            self.location = ""
            self.phoneNumber = ""
            self.profileImage = nil
            self.currentProfileImageURL = nil
            return
        }

        self.partnerDisplayName = partner.partnerDisplayName ?? ""
        self.location = partner.location ?? ""
        self.phoneNumber = partner.phoneNumber ?? ""

        if let photoURL = partner.profilePictureURL {
            self.currentProfileImageURL = photoURL
            loadImageFromURL(photoURL)
        } else {
            self.profileImage = nil
            self.currentProfileImageURL = nil
        }
    }

    /// Updates the partner's profile in the "partners" Firestore collection
    func updateProfile() async -> Bool {
        guard let firebaseUser = Auth.auth().currentUser else {
            errorMessage = "No authenticated partner to update profile for."
            return false
        }

        isLoading = true
        errorMessage = ""

        var updatedFields: [String: Any] = [
            "partnerDisplayName": partnerDisplayName,
            "location": location,
            "phoneNumber": phoneNumber
        ]

        var newPhotoURL: URL? = nil

        do {
            // 1. Upload new profile image if one was selected
            if let image = profileImage, selectedPhotoItem != nil {
                newPhotoURL = try await uploadProfileImage(image, for: firebaseUser.uid)
                updatedFields["profilePictureURL"] = newPhotoURL?.absoluteString
            } else if profileImage == nil && selectedPhotoItem == nil && currentProfileImageURL != nil {
                // User cleared the image
                updatedFields["profilePictureURL"] = FieldValue.delete()
                newPhotoURL = nil
            }

            // 2. Update the "partners" collection in Firestore
            // Unlike the user profile, we don't update the Firebase Auth profile itself,
            // as the partner's profile data lives exclusively in the "partners" collection.
            try await db.collection("partners").document(firebaseUser.uid).setData(updatedFields, merge: true)

            print("Partner profile updated successfully in Firestore.")
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Failed to update partner profile: \(error.localizedDescription)"
            print("Error updating partner profile: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }

    // MARK: - Image Handling

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
            profileImage = nil
            currentProfileImageURL = nil
            return
        }
        do {
            if let data = try await selectedItem.loadTransferable(type: Data.self) {
                if let image = UIImage(data: data) {
                    profileImage = image
                }
            }
        } catch {
            errorMessage = "Failed to load selected image: \(error.localizedDescription)"
        }
    }

    /// Uploads the profile image to the partner-specific storage path
    private func uploadProfileImage(_ image: UIImage, for userID: String) async throws -> URL {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "PartnerProfileViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to JPEG data."])
        }

        // Use the same path as in PartnerAuthenticationViewModel
        let storageRef = storage.reference().child("partner_profiles/\(userID)/profile.jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        return try await withCheckedThrowingContinuation { continuation in
            storageRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                storageRef.downloadURL { url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let downloadURL = url else {
                        let noURLError = NSError(domain: "PartnerProfileViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Download URL not found."])
                        continuation.resume(throwing: noURLError)
                        return
                    }
                    continuation.resume(returning: downloadURL)
                }
            }
        }
    }
}
