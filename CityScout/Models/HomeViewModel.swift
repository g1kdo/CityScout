import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var destinations: [Destination] = []
    @Published var favorites: [Destination] = []

    // MARK: - Search Properties
    @Published var searchText: String = ""
    @Published var searchResults: [Destination] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        self.searchResults = destinations

        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.filterDestinations(for: searchText)
            }
            .store(in: &cancellables)
    }

    func loadDestinations() async {
        isLoading = true
        errorMessage = nil

        // Simulate network delay or data loading
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay

        destinations = [
            Destination(
                name: "Nyandungu Eco Park",
                imageName: "Nyandungu",
                rating: 4.8,
                location: "Kigali, Nyandungu",
                participantAvatars: ["LocalAvatarImage", "LocalAvatarImage", "LocalAvatarImage", "LocalAvatarImage"],
                description: "Experience the serene beauty of Nyandungu Eco-Park, a revitalized wetland ecosystem in Kigali. Perfect for nature walks, birdwatching, and relaxation."
            ),
            Destination(
                name: "Kigali Convention Center",
                imageName: "Convention",
                rating: 4.8,
                location: "Kigali, Gishushu",
                participantAvatars: ["LocalAvatarImage", "LocalAvatarImage"],
                description: "Kigali Convention Center is an iconic landmark in Kigali, serving as the city's primary venue for business meetings and events."
            ),
            Destination(
                name: "Kimironko Market",
                imageName: "KimironkoMarket",
                rating: 4.3,
                location: "Kigali, Kimironko",
                participantAvatars: ["LocalAvatarImage", "LocalAvatarImage", "LocalAvatarImage"],
                description: "Kimironko Market is Kigali's largest and busiest market, offering a vibrant array of local produce, crafts, and textiles."
            ),
            Destination(
                name: "Niyo Art Gallery",
                imageName: "Artgallery",
                rating: 4.5,
                location: "Kigali, Kacyiru",
                participantAvatars: ["LocalAvatarImage", "LocalAvatarImage", "LocalAvatarImage"],
                description: "Niyo Art Gallery showcases contemporary Rwandan art, providing a platform for local artists and cultural exchange."
            ),
            Destination(
                name: "Aonang Villa Resort",
                imageName: "AonangVillaResort",
                rating: 4.7,
                location: "Patras, Greece",
                participantAvatars: ["LocalAvatarImage", "LocalAvatarImage"],
                description: "A luxurious resort in Patras, Greece, offering stunning views and world-class amenities."
            ),
            Destination(
                name: "Serena Resort",
                imageName: "SerenaResort",
                rating: 4.6,
                location: "Rubavu",
                participantAvatars: ["LocalAvatarImage", "LocalAvatarImage"],
                description: "Serena Resort in Rubavu provides a beautiful lakeside escape with premium services and serene surroundings."
            ),
            Destination(
                name: "Kachura Resort",
                imageName: "KachuraResort",
                rating: 4.4,
                location: "NewPort, Rhode Island",
                participantAvatars: ["LocalAvatarImage"],
                description: "A charming resort located in NewPort, Rhode Island, perfect for a coastal getaway."
            ),
            Destination(
                name: "Shakarudu Resort",
                imageName: "ShakaruduResort",
                rating: 4.9,
                location: "Sharjah, Dubai",
                participantAvatars: ["LocalAvatarImage", "LocalAvatarImage", "LocalAvatarImage"],
                description: "An exquisite resort in Sharjah, Dubai, offering luxury and unique architectural beauty by the water."
            ),
            Destination(
                name: "Niladri Reservoir",
                imageName: "NiladriReservoir",
                rating: 4.1,
                location: "Tekergat, Sunamgnj",
                participantAvatars: ["LocalAvatarImage"],
                description: "A scenic reservoir known for its tranquil environment and natural beauty."
            ),
            Destination(
                name: "Casa Las Tirtugas",
                imageName: "CasaLasTirtugas",
                rating: 4.6,
                location: "Av Damero, Mexico",
                participantAvatars: ["LocalAvatarImage"],
                description: "A beautiful house or resort located in Av Damero, Mexico, offering a relaxing retreat."
            )
        ]

        // Initialize search results with all destinations
        self.searchResults = self.destinations

        if favorites.isEmpty {
            if let nyandungu = destinations.first(where: { $0.name == "Nyandungu Eco Park" }) {
                favorites.append(nyandungu)
            }
            if let aonang = destinations.first(where: { $0.name == "Aonang Villa Resort" }) {
                favorites.append(aonang)
            }
            if let shakarudu = destinations.first(where: { $0.name == "Shakarudu Resort" }) {
                favorites.append(shakarudu)
            }
        }
        
        isLoading = false
    }

    // MARK: - Search Logic
    private func filterDestinations(for searchText: String) {
        if searchText.isEmpty {
            searchResults = destinations
        } else {
            searchResults = destinations.filter { destination in
                destination.name.localizedCaseInsensitiveContains(searchText) ||
                destination.location.localizedCaseInsensitiveContains(searchText) ||
                destination.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // MARK: - Favorite Logic [NEW]
    func toggleFavorite(destination: Destination) {
        if let index = favorites.firstIndex(where: { $0.id == destination.id }) {
            // It's a favorite, remove it
            favorites.remove(at: index)
        } else {
            // Not a favorite, add it
            favorites.append(destination)
        }
    }

    func isFavorite(destination: Destination) -> Bool {
        favorites.contains(where: { $0.id == destination.id })
    }
}
