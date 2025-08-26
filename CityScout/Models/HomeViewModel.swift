// ViewModels/HomeViewModel.swift
import Foundation
import Combine
import FirebaseFirestore

@MainActor
class HomeViewModel: ObservableObject {
    @Published var showSearchView = false
    
    @Published var destinations: [Destination] = []
    @Published var categorizedDestinations: [String: [Destination]] = [:]
    
    // MARK: - Search Properties
    @Published var searchText: String = ""
    @Published var searchResults: [Destination] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isFetching = false
    
    private var destinationsListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()

    // Firestore instance
    private let db = Firestore.firestore()
    private let usersCollection = "users"

    init() {
        subscribeToDestinations()
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .combineLatest($destinations)
            .sink { [weak self] searchText, destinations in
                self?.filterDestinations(for: searchText, destinations: destinations)
            }
            .store(in: &cancellables)
    }

    // New: Update user's interest scores in Firestore
    func updateInterestScores(for userId: String, categories: [String], with weight: Double) async {
        guard !categories.isEmpty else { return }
        
        // This dictionary will hold the category names and their corresponding increment values.
        let updates = categories.reduce(into: [String: Any]()) { dict, category in
            dict["interestScores.\(category)"] = FieldValue.increment(weight)
        }

        let userRef = db.collection(usersCollection).document(userId)

        do {
            try await userRef.updateData(updates)
            print("Successfully updated interest scores for user \(userId) with weight \(weight) for categories \(categories).")
        } catch {
            print("Error updating interest scores: \(error.localizedDescription)")
        }
    }
    
    // New: Log a user's action to Firestore
    func logUserAction(userId: String, destinationId: String?, actionType: String, metadata: [String: Any]? = nil) async {
        let actionRef = db.collection("userActivities").document()
        var data: [String: Any] = [
            "userId": userId,
            "actionType": actionType,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        if let destinationId = destinationId {
            data["destinationId"] = destinationId
        }
        if let metadata = metadata {
            data["metadata"] = metadata
        }
        
        do {
            try await actionRef.setData(data)
            print("Successfully logged user action: \(actionType)")
        } catch {
            print("Error logging user action: \(error.localizedDescription)")
        }
    }

    private func subscribeToDestinations() {
        isLoading = true
        errorMessage = nil
        
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
    
    func fetchPersonalizedDestinations(for userId: String) async {
        guard !isFetching else { return }
        isFetching = true
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        do {
            let document = try await userRef.getDocument()
            guard document.exists, let interestScores = document.data()?["interestScores"] as? [String: Double] else {
                print("No interest scores found for user.")
                isFetching = false
                return
            }
            
            let topInterests = interestScores.sorted { $0.value > $1.value }.map { $0.key }.prefix(3)
            
            var newCategorizedDestinations: [String: [Destination]] = [:]
            
            await withTaskGroup(of: (String, [Destination]).self) { group in
                for interest in topInterests {
                    group.addTask {
                        do {
                            let snapshot = try await db.collection("destinations")
                                .whereField("categories", arrayContains: interest)
                                .getDocuments()
                            let destinations = snapshot.documents.compactMap { doc -> Destination? in
                                try? doc.data(as: Destination.self)
                            }
                            return (interest, destinations)
                        } catch {
                            print("Error fetching destinations for \(interest): \(error)")
                            return (interest, [])
                        }
                    }
                }
                
                for await (interest, destinations) in group {
                    newCategorizedDestinations[interest] = destinations
                }
            }
            
            await MainActor.run {
                self.categorizedDestinations = newCategorizedDestinations
            }
            
        } catch {
            print("Error fetching user interests: \(error)")
        }
        
        isFetching = false
    }

    deinit {
        destinationsListener?.remove()
    }
}
