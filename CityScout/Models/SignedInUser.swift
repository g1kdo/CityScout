// Models/SignedInUser.swift
import Foundation
import FirebaseFirestore

struct SignedInUser: Identifiable, Codable, Equatable {
    @DocumentID var id: String? // Firestore document ID, should match Firebase Auth UID
    var displayName: String? // This will hold the combined display name or full name
    var email: String
    var location: String?
    var mobileNumber: String?
    var profilePictureURL: String? // Stored as String for Firestore compatibility

    // Initializer for creating from Firebase Auth.User or when initially setting up
    init(id: String, displayName: String?, email: String, location: String? = nil, mobileNumber: String? = nil, profilePictureURL: URL? = nil) {
        self.id = id
        self.displayName = displayName // Initialize with Firebase Auth's display name or a provided display name
        self.email = email
        self.location = location
        self.mobileNumber = mobileNumber
        // Convert URL to String for storage
        self.profilePictureURL = profilePictureURL?.absoluteString
    }

    // Method to update this SignedInUser instance with data fetched from Firestore
    mutating func updateWithProfileData(_ data: [String: Any]) {
        // Update fields only if they exist in the provided data
        self.displayName = data["displayName"] as? String ?? self.displayName // Update displayName from Firestore
        self.location = data["location"] as? String ?? self.location
        self.mobileNumber = data["mobileNumber"] as? String ?? self.mobileNumber

        // Update profilePictureURL from Firestore string
        if let urlString = data["profilePictureURL"] as? String {
            self.profilePictureURL = urlString
        }
    }

    // Helper to get the profile picture URL as a URL object for UI display (e.g., Kingfisher)
    var profilePictureAsURL: URL? {
        if let urlString = profilePictureURL {
            return URL(string: urlString)
        }
        return nil
    }
}
