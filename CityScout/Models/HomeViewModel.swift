import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var destinations: [Destination] = []

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


        destinations = [
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

        self.searchResults = self.destinations
        
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
}
