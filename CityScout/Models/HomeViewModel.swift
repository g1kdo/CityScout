import Foundation
import Combine
import FirebaseFirestore
import GooglePlaces

@MainActor
class HomeViewModel: ObservableObject {
    @Published var showSearchView = false
    
    @Published var destinations: [Destination] = []
    @Published var categorizedDestinations: [String: [Destination]] = [:]
    
    // MARK: - Search Properties
    @Published var searchText: String = ""
    @Published var searchResults: [AnyDestination] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isFetching = false
    
    private var destinationsListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()

    // Firestore instance
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    
    // Google Places client
    private var placesClient: GMSPlacesClient!

    init() {
        self.placesClient = GMSPlacesClient.shared()
        subscribeToDestinations()
        setupSearchSubscriber()
    }

    private func setupSearchSubscriber() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                guard let self = self else { return }
                if searchText.isEmpty {
                    self.searchResults = []
                    self.isLoading = false
                    self.errorMessage = nil
                } else {
                    self.performCombinedSearch(for: searchText)
                }
            }
            .store(in: &cancellables)
    }
    
    private func performCombinedSearch(for searchText: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            // Fetch local results
            let localResults = self.destinations.filter { destination in
                let combinedText = "\(destination.name) \(destination.location) \(destination.description ?? "")"
                return combinedText.localizedCaseInsensitiveContains(searchText)
            }.map { AnyDestination.local($0) }
            
            // Fetch Google results
            let googlePredictions = await self.searchGooglePlaces(for: searchText)
            
            await MainActor.run {
                self.isLoading = false
                self.searchResults = localResults + googlePredictions
                
                if self.searchResults.isEmpty {
                    self.errorMessage = "No results found for \"\(searchText)\""
                }
            }
        }
    }
    
    // MARK: - Refactored searchGooglePlaces function to only return predictions
    private func searchGooglePlaces(for query: String) async -> [AnyDestination] {
        let placesRequest = GMSAutocompleteFilter()
        placesRequest.types = ["establishment", "point_of_interest", "tourist_attraction"]
        let sessionToken = GMSAutocompleteSessionToken()

        return await withCheckedContinuation { continuation in
            placesClient.findAutocompletePredictions(fromQuery: query, filter: placesRequest, sessionToken: sessionToken) { (predictions, error) in
                guard let predictions = predictions, error == nil else {
                    print("Google Places autocomplete error: \(String(describing: error?.localizedDescription))")
                    continuation.resume(returning: [])
                    return
                }

                // Map predictions to a simpler model without fetching details here
                let results = predictions.map { prediction in
                    // This creates a GoogleDestination with only the info available from the prediction
                    // The full details will be fetched later when the user taps on it.
                    let googleDest = GoogleDestination(
                        placeID: prediction.placeID,
                        name: prediction.attributedPrimaryText.string,
                        location: prediction.attributedSecondaryText?.string ?? "",
                        photoMetadata: nil,
                        websiteURL: nil,
                        rating: nil,
                        latitude: nil,
                        longitude: nil
                    )
                    return AnyDestination.google(googleDest)
                }
                
                continuation.resume(returning: results)
            }
        }
    }

    // MARK: - New function to fetch full place details when a search result is selected
    func fetchPlaceDetails(for placeID: String) async -> GoogleDestination? {
        let placeFields: GMSPlaceField = [.name, .formattedAddress, .rating, .website, .photos, .coordinate]
        let sessionToken = GMSAutocompleteSessionToken()

        return await withCheckedContinuation { continuation in
            placesClient.fetchPlace(fromPlaceID: placeID, placeFields: placeFields, sessionToken: sessionToken) { (place, error) in
                guard let place = place, error == nil else {
                    print("Error fetching full place details for placeID \(placeID): \(String(describing: error?.localizedDescription))")
                    continuation.resume(returning: nil)
                    return
                }
                
                let ratingAsDouble = place.rating != nil ? Double(place.rating) : nil
                
                let fullGoogleDest = GoogleDestination(
                    placeID: place.placeID ?? "",
                    name: place.name ?? "",
                    location: place.formattedAddress ?? "",
                    photoMetadata: place.photos?.first,
                    websiteURL: place.website?.absoluteString,
                    rating: ratingAsDouble,
                    latitude: place.coordinate.latitude,
                    longitude: place.coordinate.longitude
                )
                
                continuation.resume(returning: fullGoogleDest)
            }
        }
    }

    // New: Update user's interest scores in Firestore
    func updateInterestScores(for userId: String, categories: [String], with weight: Double) async {
        guard !categories.isEmpty else { return }
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
