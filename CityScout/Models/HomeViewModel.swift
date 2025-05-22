import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var destinations: [Destination] = []

    func loadDestinations() async {
        destinations = [
            Destination(
                name: "Nyandungu Eco Park",
                imageName: "Nyandungu",
                rating: 4.8,
                location: "Kigali, Nyandungu",
                participantAvatars: ["LocalAvatarImage", "LocalAvatarImage", "LocalAvatarImage", "LocalAvatarImage"]
            ),
            Destination(
                name: "Kigali Convention Center",
                imageName: "Convention",
                rating: 4.5,
                location: "Kigali, Nyandungu",
                participantAvatars: ["LocalAvatarImage", "LocalAvatarImage"]
            ),
            Destination(
                name: "Niyo Art Gallery",
                imageName: "Artgallery",
                rating: 4.0,
                location: "Kigali, Nyandungu",
                participantAvatars: ["LocalAvatarImage", "LocalAvatarImage", "LocalAvatarImage"]
            )
        ]
    }
}




