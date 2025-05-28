import Foundation
import FirebaseFirestore // Keep this if you're using Firestore in other parts of your app

struct Destination: Identifiable, Codable { // Added Codable for consistency, useful for persistence or network
    let id: String // Changed to String to better accommodate Firestore document IDs
    let name: String
    let imageName: String
    let rating: Double
    let location: String
    let participantAvatars: [String] // these will be local asset names too
    let description: String

    // Initializer to create a Destination from Firestore data
    init?(documentId: String, data: [String: Any]) {
        guard let name = data["name"] as? String,
              let imageName = data["imageName"] as? String,
              let rating = data["rating"] as? Double,
              let location = data["location"] as? String,
              let participantAvatars = data["participantAvatars"] as? [String],
              let description = data["description"] as? String else {
            return nil
        }
        self.id = documentId
        self.name = name
        self.imageName = imageName
        self.rating = rating
        self.location = location
        self.participantAvatars = participantAvatars
        self.description = description
    }

    // Default initializer for creating local instances or samples
    init(id: String = UUID().uuidString, name: String, imageName: String, rating: Double, location: String, participantAvatars: [String], description: String) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.rating = rating
        self.location = location
        self.participantAvatars = participantAvatars
        self.description = description
    }

    // Static sample data using your new structure
    static let sampleDestinations: [Destination] = [
        Destination(name: "Nyandungu Eco Park", imageName: "nyandungu_eco_park", rating: 4.5, location: "Kigali, Nyandungu", participantAvatars: ["avatar1", "avatar2"], description: "A beautiful eco-tourism park with wetlands and walking trails."),
        Destination(name: "Kigali Genocide Memorial", imageName: "kigali_genocide_memorial", rating: 4.8, location: "Kigali, Gisozi", participantAvatars: ["avatar3", "avatar4"], description: "A poignant memorial honoring the victims of the 1994 Rwandan Genocide."),
        Destination(name: "Kimironko Market", imageName: "kimironko_market", rating: 4.2, location: "Kigali, Kimironko", participantAvatars: ["avatar5", "avatar6"], description: "A vibrant and bustling local market offering a wide array of goods.")
    ]
}
