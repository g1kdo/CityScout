import Foundation
import FirebaseFirestore

struct Destination: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let imageName: String
    let rating: Double
    let location: String
    let participantAvatars: [String]
    let description: String

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

    init(id: String = UUID().uuidString, name: String, imageName: String, rating: Double, location: String, participantAvatars: [String], description: String) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.rating = rating
        self.location = location
        self.participantAvatars = participantAvatars
        self.description = description
    }

    // Static sample data (updated to match HomeViewModel's data more closely, for consistency)
    static let sampleDestinations: [Destination] = [
        Destination(id: "nyandungu", name: "Nyandungu Eco Park", imageName: "Nyandungu", rating: 4.8, location: "Kigali, Nyandungu", participantAvatars: ["LocalAvatarImage"], description: "A beautiful eco-tourism park."),
        Destination(id: "convention", name: "Kigali Convention Center", imageName: "Convention", rating: 4.8, location: "Kigali, Bugesera", participantAvatars: ["LocalAvatarImage"], description: "The logo of Rwanda."),
        Destination(id: "kimironko", name: "Kimironko Market", imageName: "KimironkoMarket", rating: 4.3, location: "Kigali, Kimironko", participantAvatars: ["LocalAvatarImage"], description: "A vibrant local market."),
        Destination(id: "niyoart", name: "Niyo Art Gallery", imageName: "Artgallery", rating: 4.5, location: "Kigali, Kacyiru", participantAvatars: ["LocalAvatarImage"], description: "Showcases contemporary Rwandan art."),
        Destination(id: "aonang", name: "Aonang Villa Resort", imageName: "AonangVillaResort", rating: 4.7, location: "Patras, Greece", participantAvatars: ["LocalAvatarImage"], description: "Luxurious resort in Greece."),
        Destination(id: "serena", name: "Serena Resort", imageName: "SerenaResort", rating: 4.6, location: "Rubavu", participantAvatars: ["LocalAvatarImage"], description: "Lakeside escape in Rubavu."),
        Destination(id: "kachura", name: "Kachura Resort", imageName: "KachuraResort", rating: 4.4, location: "NewPort, Rhode Island", participantAvatars: ["LocalAvatarImage"], description: "Charming coastal resort."),
        Destination(id: "shakarudu", name: "Shakarudu Resort", imageName: "ShakaruduResort", rating: 4.9, location: "Sharjah, Dubai", participantAvatars: ["LocalAvatarImage"], description: "Exquisite resort in Dubai."),
        Destination(id: "niladri", name: "Niladri Reservoir", imageName: "NiladriReservoir", rating: 4.1, location: "Tekergat, Sunamgnj", participantAvatars: ["LocalAvatarImage"], description: "A scenic reservoir."),
        Destination(id: "casa", name: "Casa Las Tirtugas", imageName: "CasaLasTirtugas", rating: 4.6, location: "Av Damero, Mexico", participantAvatars: ["LocalAvatarImage"], description: "A beautiful retreat in Mexico.")
    ]
}
