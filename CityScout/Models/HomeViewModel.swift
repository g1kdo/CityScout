import Foundation
import Combine
import FirebaseFirestore
import GooglePlaces

@MainActor
class HomeViewModel: ObservableObject {
    @Published var showSearchView = false
    
    @Published var destinations: [Destination] = []
    @Published var categorizedDestinations: [String: [Destination]] = [:]
    
    @Published var userInterestScores: [String: Double] = [:]
    @Published var transcribedText: String = ""
    
    // A complete list of all 10 interest categories
    private let allInterests: [String] = [
            "Adventure", "Beaches", "Mountains", "City Breaks", "Foodie",
            "Cultural", "Historical", "Nature", "Relaxing", "Family"
        ]
    
    // MARK: - Search Properties
    @Published var searchText: String = ""
    @Published var searchResults: [AnyDestination] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isFetching = false
    
    @Published var currentSessionToken: GMSAutocompleteSessionToken?
    
    private var destinationsListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    
    private let speechRecognizer = SpeechRecognizer()
    @Published var isListeningToSpeech = false

    // Firestore instance
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    
    // Google Places client
    private var placesClient: GMSPlacesClient!

    init() {
        self.placesClient = GMSPlacesClient.shared()
        subscribeToDestinations()
        setupSearchSubscriber()
        
        speechRecognizer.$transcriptionText
                .dropFirst() // Ignore the initial empty value
                .sink { [weak self] newText in
                    guard let self = self else { return }
                    // 🆕 New: Update the transcribedText property
                    self.transcribedText = newText
                }
                .store(in: &cancellables)
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
    
    func performCombinedSearch(for searchText: String) {
        isLoading = true
        errorMessage = nil
        
        // ⚠️ Create a new session token for this search session
        self.currentSessionToken = GMSAutocompleteSessionToken()
        
        Task {
            let localResults = self.destinations.filter { destination in
                let combinedText = "\(destination.name) \(destination.location) \(destination.description ?? "")"
                return combinedText.localizedCaseInsensitiveContains(searchText)
            }.map { AnyDestination.local($0) }
            
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
    
    private func searchGooglePlaces(for query: String) async -> [AnyDestination] {
        let filter = GMSAutocompleteFilter()
        filter.type = .establishment
        guard let token = currentSessionToken else { return [] }

        return await withCheckedContinuation { continuation in
               placesClient.findAutocompletePredictions(fromQuery: query, filter: filter, sessionToken: token) { [weak self] (predictions, error) in
                   guard let self = self, let predictions = predictions, error == nil else {
                       print("Google Places autocomplete error: \(String(describing: error?.localizedDescription))")
                       continuation.resume(returning: [])
                       return
                   }

                // We will store the detailed results here
                var destinations = [AnyDestination]()
                let group = DispatchGroup()

                for prediction in predictions {
                    group.enter()
                    // Make a separate call for each place to get details
                    fetchDetailsByPlace(for: prediction.placeID, sessionToken: token) { place in
                        if let place = place {
                            
                            let ratingAsDouble = place.rating != nil ? Double(place.rating) : nil
                            
                            // Handle unspecified (negative) price levels
                            var priceLevelAsInt: Int? = nil
                            if place.priceLevel.rawValue >= 0 {
                                priceLevelAsInt = Int(place.priceLevel.rawValue)
                            }
                            
                            let googleDest = GoogleDestination(
                                placeID: place.placeID!,
                                name: place.name ?? prediction.attributedPrimaryText.string,
                                location: place.formattedAddress ?? prediction.attributedSecondaryText?.string ?? "",
                                photoMetadata: place.photos?.first,
                                websiteURL: place.website?.absoluteString,
                                rating: ratingAsDouble,
                                latitude: place.coordinate.latitude,
                                longitude: place.coordinate.longitude,
                                priceLevel: priceLevelAsInt,
                                galleryImageUrls: nil // You can implement a separate function to fetch these
                            )
                            destinations.append(AnyDestination.google(googleDest, sessionToken: token))
                        } else {
                            // Fallback to the autocomplete data if details can't be fetched
                            let googleDest = GoogleDestination(
                                placeID: prediction.placeID,
                                name: prediction.attributedPrimaryText.string,
                                location: prediction.attributedSecondaryText?.string ?? "",
                                photoMetadata: nil,
                                websiteURL: nil,
                                rating: nil,
                                latitude: nil,
                                longitude: nil,
                                priceLevel: nil,
                                galleryImageUrls: nil
                            )
                            destinations.append(AnyDestination.google(googleDest, sessionToken: token))
                        }
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    continuation.resume(returning: destinations)
                }
            }
        }
    }

    private func fetchDetailsByPlace(for placeID: String, sessionToken: GMSAutocompleteSessionToken, completion: @escaping (GMSPlace?) -> Void) {
        let fields: GMSPlaceField = [.placeID, .name, .formattedAddress, .photos, .rating, .website, .coordinate, .priceLevel]
        
        // Use the same session token to link the autocomplete and details requests
        placesClient.fetchPlace(fromPlaceID: placeID, placeFields: fields, sessionToken: sessionToken) { (place, error) in
            if let error = error {
                print("Place Details fetch error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            completion(place)
        }
    }



    func fetchPlaceDetails(for placeID: String, with sessionToken: GMSAutocompleteSessionToken) async -> GoogleDestination? {
        // ⚠️ Updated place fields to include all necessary data
        let placeFields: GMSPlaceField = [.name, .formattedAddress, .rating, .website, .photos, .coordinate, .priceLevel, .phoneNumber]


        return await withCheckedContinuation { continuation in
            placesClient.fetchPlace(fromPlaceID: placeID, placeFields: placeFields, sessionToken: sessionToken) { (place, error) in
                           guard let place = place, error == nil else {
                               print("Error fetching full place details for placeID \(placeID): \(String(describing: error?.localizedDescription))")

                               let result: GoogleDestination? = nil
                               continuation.resume(returning: result)
                               return
                           }
                
                let ratingAsDouble = place.rating != nil ? Double(place.rating) : nil
                
                // Handle unspecified (negative) price levels
                var priceLevelAsInt: Int? = nil
                if place.priceLevel.rawValue >= 0 {
                    priceLevelAsInt = Int(place.priceLevel.rawValue)
                }

                let fullGoogleDest = GoogleDestination(
                    placeID: place.placeID ?? "",
                    name: place.name ?? "",
                    location: place.formattedAddress ?? "",
                    photoMetadata: place.photos?.first,
                    websiteURL: place.website?.absoluteString,
                    rating: ratingAsDouble,
                    latitude: place.coordinate.latitude,
                    longitude: place.coordinate.longitude,
                    priceLevel: priceLevelAsInt,
                    galleryImageUrls: place.photos
                )
                continuation.resume(returning: fullGoogleDest)
            }
        }
    }
    
        func handleMicrophoneTapped() {
            if speechRecognizer.isListening {
                speechRecognizer.stop()
                isListeningToSpeech = false
            } else {
                // Request permissions and start
                let status = speechRecognizer.authorizationStatus
                switch status {
                case .authorized:
                    do {
                        try speechRecognizer.start()
                        isListeningToSpeech = true
                    } catch {
                        print("Error starting speech recognition: \(error.localizedDescription)")
                    }
                case .notDetermined, .denied, .restricted:
                    // Handle cases where permission is not granted
                    self.errorMessage = "Permission to use speech recognition is required."
                @unknown default:
                    self.errorMessage = "Unknown authorization status for speech recognition."
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
                let interestScores = document.data()?["interestScores"] as? [String: Double] ?? [:]
                
                await MainActor.run {
                    self.userInterestScores = interestScores
                }

                var newCategorizedDestinations: [String: [Destination]] = [:]
                
                await withTaskGroup(of: (String, [Destination]).self) { group in
                    // Now, we iterate over the complete list of all interests
                    for interest in self.allInterests {
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
