//
//  FavoritesViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 30/07/2025.
//

import SwiftUI
import FirebaseFirestore

@MainActor
class FavoritesViewModel: ObservableObject {
    @Published var favorites: [Destination] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var userId: String?
    private var userFavoritesListener: ListenerRegistration?
    
    // THE FIX: Add a reference to HomeViewModel
    private let homeViewModel: HomeViewModel

    init(homeViewModel: HomeViewModel) {
        self.homeViewModel = homeViewModel
    }
    
    func subscribeToFavorites(for userId: String?) {
        // Only set up a listener if the user ID has changed.
        guard self.userId != userId else { return }
        
        // Clean up the old listener if it exists.
        userFavoritesListener?.remove()
        self.userFavoritesListener = nil
        self.userId = userId
        
        guard let userId = userId else {
            // User logged out, clear data.
            self.favorites = []
            return
        }

        isLoading = true
        errorMessage = nil
        
        let userRef = Firestore.firestore().collection("users").document(userId)

        // Set up the listener on the user's document.
        userFavoritesListener = userRef.addSnapshotListener { [weak self] documentSnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = "Failed to listen for user favorites: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            
            // Get the array of favorite destination IDs.
            guard let favoriteIds = documentSnapshot?.data()?["favorites"] as? [String], !favoriteIds.isEmpty else {
                self.favorites = []
                self.isLoading = false
                return
            }
            
            // Fetch the full destination documents based on the new list of IDs.
            self.fetchDestinations(for: favoriteIds)
        }
    }

    /// Fetches the full destination documents for a given array of IDs.
    private func fetchDestinations(for ids: [String]) {
        guard !ids.isEmpty else {
            self.favorites = []
            return
        }

        let destinationRef = Firestore.firestore().collection("destinations")
        destinationRef.whereField(FieldPath.documentID(), in: ids).getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Error fetching favorite destinations: \(error.localizedDescription)"
                return
            }

            guard let documents = snapshot?.documents else {
                self.errorMessage = "No matching destination documents found."
                return
            }
            
            // Decode the fetched documents into Destination objects.
            self.favorites = documents.compactMap { try? $0.data(as: Destination.self) }
        }
    }
    
    // MARK: - New and Corrected Methods
    
    /// Toggles a destination's favorite status.
    func toggleFavorite(destination: AnyDestination) async {
        switch destination {
        case .local(let localDestination):
            await toggleLocalFavorite(destination: localDestination)
        case .google(let googleDestination, _):
            // This is a new method you'll need to create.
            // It will handle saving Google destinations to a separate Firestore collection or in a different structure.
            await toggleGoogleFavorite(destination: googleDestination)
        }
    }
    
    /// Checks if an AnyDestination is in the favorites.
    func isFavorite(destination: AnyDestination) -> Bool {
        switch destination {
        case .local(let localDestination):
            return favorites.contains(where: { $0.id == localDestination.id })
        case .google(let googleDestination):
            // Assuming you have a way to check if a Google destination is favorited.
            // For now, this will always return false unless you implement a way to store them.
            // The `favorites` array only holds `Destination` objects.
            // This needs a more sophisticated check, e.g., querying Firestore directly.
            return false
        }
    }
    
    private func toggleLocalFavorite(destination: Destination) async {
        guard let userId = userId, let destinationId = destination.id else {
            self.errorMessage = "User or destination ID is missing."
            return
        }

        let userRef = Firestore.firestore().collection("users").document(userId)
        
        let isCurrentlyFavorite = self.isFavorite(destination: .local(destination))
        
        do {
            if isCurrentlyFavorite {
                try await userRef.updateData(["favorites": FieldValue.arrayRemove([destinationId])])
                // THE FIX: Decrease interest score and log user action
                Task {
                    await homeViewModel.updateInterestScores(for: userId, categories: destination.categories, with: -1.0)
                    await homeViewModel.logUserAction(userId: userId, destinationId: destinationId, actionType: "unfavorite")
                }
            } else {
                try await userRef.updateData(["favorites": FieldValue.arrayUnion([destinationId])])
                // THE FIX: Increase interest score and log user action
                Task {
                    await homeViewModel.updateInterestScores(for: userId, categories: destination.categories, with: 1.0)
                    await homeViewModel.logUserAction(userId: userId, destinationId: destinationId, actionType: "favorite")
                }
            }
        } catch {
            self.errorMessage = "Failed to toggle favorite: \(error.localizedDescription)"
            print("Failed to toggle favorite: \(error.localizedDescription)")
        }
    }
    
    private func toggleGoogleFavorite(destination: GoogleDestination) async {
        // Implementation for Google Places favorites goes here.
        // Since your `favorites` array only holds `Destination` objects, you'll need to decide
        // how to store and retrieve Google destinations.
        // For example:
        // 1. Create a `userFavorites` collection.
        // 2. Each document could have a `type` field ("local" or "google").
        // 3. Or, you could have a separate `googleFavorites` array in the user document.
        
        // This is a complex logic that depends on your backend structure.
        // For now, let's just log a message.
        print("Toggling a Google Place favorite. Implementation required.")
    }

    // Clean up the listener when the view model is deallocated.
    deinit {
        userFavoritesListener?.remove()
    }
}
