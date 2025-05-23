import Foundation
import FirebaseFirestore

class DestinationService {
    func fetchBestDestinations() async throws -> [Destination] {
        return [
            Destination(
                name: "Nyandungu Eco Park",
                imageName: "Nyandungu",
                rating: 4.8,
                location: "Kigali, Nyandungu",
                participantAvatars: ["LocalAvatarImage", "LocalAvatarImage", "LocalAvatarImage", "LocalAvatarImage"],
                description: "You will get a complete travel package on the beaches. Packages in the form of airline tickets, recommended Hotel rooms, Transportation, Have you ever been on holiday to the Greek ETC..."
            ),
            Destination(
                name: "Kigali Convention Center",
                imageName: "Convention",
                rating: 4.5,
                location: "Kigali, Nyandungu",
                participantAvatars: ["LocalAvatarImage", "LocalAvatarImage"],
                description: "You will get a complete travel package on the beaches. Packages in the form of airline tickets, recommended Hotel rooms, Transportation, Have you ever been on holiday to the Greek ETC..."
            ),
            Destination(
                name: "Niyo Art Gallery",
                imageName: "Artgallery",
                rating: 4.0,
                location: "Kigali, Nyandungu",
                participantAvatars: ["LocalAvatarImage", "LocalAvatarImage", "LocalAvatarImage"],
                description: "You will get a complete travel package on the beaches. Packages in the form of airline tickets, recommended Hotel rooms, Transportation, Have you ever been on holiday to the Greek ETC..."
            )
        ]
    }
}


