// Models/SignedInUser.swift
import Foundation
import FirebaseFirestore

struct SignedInUser: Identifiable, Codable, Equatable {
    @DocumentID var id: String? // Firestore document ID, should match Firebase Auth UID
    var displayName: String? // This will hold the combined display name
    var email: String
    var firstName: String?
    var lastName: String?
    var location: String?
    var mobileNumber: String?
    var profilePictureURL: String? // Stored as String for Firestore compatibility

    // Initializer for creating from Firebase Auth.User or when initially setting up
    init(id: String, displayName: String?, email: String, firstName: String? = nil, lastName: String? = nil, location: String? = nil, mobileNumber: String? = nil, profilePictureURL: URL? = nil) {
        self.id = id
        self.displayName = displayName // Initialize with Firebase Auth's display name
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.location = location
        self.mobileNumber = mobileNumber
        // Convert URL to String for storage
        self.profilePictureURL = profilePictureURL?.absoluteString
    }

    // Method to update this SignedInUser instance with data fetched from Firestore
    mutating func updateWithProfileData(_ data: [String: Any]) {
        // Update fields only if they exist in the provided data
        self.firstName = data["firstName"] as? String ?? self.firstName
        self.lastName = data["lastName"] as? String ?? self.lastName
        self.location = data["location"] as? String ?? self.location
        self.mobileNumber = data["mobileNumber"] as? String ?? self.mobileNumber

        // Update profilePictureURL from Firestore string
        if let urlString = data["profilePictureURL"] as? String {
            self.profilePictureURL = urlString
        }

        // --- CRITICAL CHANGE FOR DISPLAY NAME LOGIC ---
        let combinedFirstName = self.firstName ?? ""
        let combinedLastName = self.lastName ?? ""

        if !combinedFirstName.isEmpty || !combinedLastName.isEmpty {
            // If either first or last name is provided in Firestore, use them to form the display name.
            // This prioritizes user-set names over social display names.
            self.displayName = "\(combinedFirstName) \(combinedLastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // ELSE: If both firstName and lastName are empty (i.e., not set in Firestore),
        // we implicitly keep the `displayName` that was set during initialization
        // (which would be from the Firebase Auth `displayName`, e.g., Google's).
        // No 'else' block is needed here for displayName, as it retains its initial value if not explicitly overridden.
    }

    // Helper to get the profile picture URL as a URL object for UI display (e.g., Kingfisher)
    var profilePictureAsURL: URL? {
        if let urlString = profilePictureURL {
            return URL(string: urlString)
        }
        return nil
    }
}
