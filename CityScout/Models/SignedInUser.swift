// Models/SignedInUser.swift
import Foundation
import FirebaseFirestore
import FirebaseMessaging

struct SignedInUser: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var displayName: String?
    var email: String
    var location: String?
    var mobileNumber: String?
    var profilePictureURL: String?
    
    // NEW: Property to store the Firebase Cloud Messaging token for push notifications
    var fcmToken: String?
    
    // MARK: - New Properties for Recommendation
    var selectedInterests: [String]? = []
    var interestScores: [String: Int]? = [:]
    var hasSetInterests: Bool? = false
    
    init(id: String, displayName: String?, email: String, location: String? = nil, mobileNumber: String? = nil, profilePictureURL: URL? = nil, fcmToken: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.location = location
        self.mobileNumber = mobileNumber
        self.profilePictureURL = profilePictureURL?.absoluteString
        self.fcmToken = fcmToken
        self.selectedInterests = [] // Initialize as empty
        self.interestScores = [:] // Initialize as empty
    }
    
    mutating func updateWithProfileData(_ data: [String: Any]) {
        self.displayName = data["displayName"] as? String ?? self.displayName
        self.location = data["location"] as? String ?? self.location
        self.mobileNumber = data["mobileNumber"] as? String ?? self.mobileNumber
        
        if let urlString = data["profilePictureURL"] as? String {
            self.profilePictureURL = urlString
        }
        
        // NEW: Update the FCM token from Firestore
        self.fcmToken = data["fcmToken"] as? String ?? self.fcmToken
        
        // MARK: - Update new properties from Firestore
        self.selectedInterests = data["selectedInterests"] as? [String] ?? self.selectedInterests
        self.interestScores = data["interestScores"] as? [String: Int] ?? self.interestScores
        self.hasSetInterests = data["hasSetInterests"] as? Bool ?? self.hasSetInterests
    }
    
    var profilePictureAsURL: URL? {
        if let urlString = profilePictureURL {
            return URL(string: urlString)
        }
        return nil
    }
}
