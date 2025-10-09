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
                        // Update the searchText with the new transcription
                        self.searchText = newText
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
            //placesRequest.types = ["establishment", "point_of_interest", "tourist_attraction"]
            filter.type = .establishment
            guard let token = currentSessionToken else { return [] }

            return await withCheckedContinuation { continuation in
                placesClient.findAutocompletePredictions(fromQuery: query, filter: filter, sessionToken: token) { (predictions, error) in
                    guard let predictions = predictions, error == nil else {
                        print("Google Places autocomplete error: \(String(describing: error?.localizedDescription))")
                        continuation.resume(returning: [])
                        return
                    }
                    
                    if let error = error as NSError? {
                       print("Autocomplete error: \(error.localizedDescription)")
                       print("Error domain: \(error.domain), code: \(error.code), userInfo: \(error.userInfo)")
                    }

                    let results = predictions.map { prediction in
                        let googleDest = GoogleDestination(
                            placeID: prediction.placeID,
                            name: prediction.attributedPrimaryText.string,
                            location: prediction.attributedSecondaryText?.string ?? "",
                            photoMetadata: prediction.self  as? GMSPlacePhotoMetadata,
                            websiteURL: nil,
                            rating: nil,
                            latitude: nil,
                            longitude: nil,
                            priceLevel: nil,
                            galleryImageUrls: nil
                        )
                        

                        return AnyDestination.google(googleDest, sessionToken: token)
                    }

                    continuation.resume(returning: results)
                }
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
