import Foundation

struct SignedInUser: Identifiable, Equatable {
    let id: String          // Firebase UID
    var displayName: String? // Full name (made optional as it might be composed from first/last)
    var email: String
    var firstName: String?
    var lastName: String?
    var location: String?
    var mobileNumber: String?
    var profilePictureURL: URL?

    // Initializer to create a new SignedInUser, typically from Firebase Auth data
    init(id: String, displayName: String?, email: String, firstName: String? = nil, lastName: String? = nil, location: String? = nil, mobileNumber: String? = nil, profilePictureURL: URL? = nil) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.location = location
        self.mobileNumber = mobileNumber
        self.profilePictureURL = profilePictureURL
    }

    // Function to update the user's properties from a dictionary (e.g., from Firestore)
    mutating func updateWithProfileData(_ data: [String: Any]) {
        self.firstName = data["firstName"] as? String ?? self.firstName
        self.lastName = data["lastName"] as? String ?? self.lastName
        self.location = data["location"] as? String ?? self.location
        self.mobileNumber = data["mobileNumber"] as? String ?? self.mobileNumber
        if let urlString = data["profilePictureURL"] as? String {
            self.profilePictureURL = URL(string: urlString) ?? self.profilePictureURL
        }
        // Update displayName if firstName and lastName are available
        if let first = self.firstName, let last = self.lastName {
            self.displayName = "\(first) \(last)"
        } else if let first = self.firstName {
            self.displayName = first
        }
    }
}
