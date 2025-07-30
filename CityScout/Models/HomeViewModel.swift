// ViewModels/HomeViewModel.swift
import Foundation
import Combine
import FirebaseFirestore

@MainActor
class HomeViewModel: ObservableObject {
    @Published var destinations: [Destination] = []
    
    // MARK: - Search Properties
    @Published var searchText: String = ""
    @Published var searchResults: [Destination] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var destinationsListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Automatically start fetching data when the ViewModel is created
        subscribeToDestinations()

        // Setup Combine pipeline for search
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .combineLatest($destinations) // Combine searchText with the live list of destinations
            .sink { [weak self] searchText, destinations in
                self?.filterDestinations(for: searchText, destinations: destinations)
            }
            .store(in: &cancellables)
    }

    /// Sets up a real-time listener to fetch all destinations from Firestore.
    private func subscribeToDestinations() {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        let destinationsCollection = "destinations"

        destinationsListener = db.collection(destinationsCollection)
            .order(by: "name")
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to fetch destinations: \(error.localizedDescription)"
                    print(self.errorMessage!)
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    self.destinations = []
                    return
                }
                
                self.destinations = documents.compactMap { doc -> Destination? in
                    try? doc.data(as: Destination.self)
                }
            }
    }

    /// Filters the list of destinations based on the search text.
    private func filterDestinations(for searchText: String, destinations: [Destination]) {
        if searchText.isEmpty {
            self.searchResults = destinations
        } else {
            self.searchResults = destinations.filter { destination in
                let combinedText = "\(destination.name) \(destination.location) \(destination.description ?? "")"
                return combinedText.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    deinit {
        // Clean up the Firestore listener when the ViewModel is deallocated.
        destinationsListener?.remove()
    }
}
