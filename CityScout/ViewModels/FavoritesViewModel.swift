//
//  FavoritesViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 30/07/2025.
//


// ViewModels/FavoritesViewModel.swift
import SwiftUI
import FirebaseFirestore

@MainActor
class FavoritesViewModel: ObservableObject {
    @Published var favorites: [Destination] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var userId: String?
    private var userFavoritesListener: ListenerRegistration?

    /// Sets up a real-time listener for the user's favorites.
    /// Call this when the user's authentication state changes.
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
    
    /// Toggles a destination's favorite status.
    /// This is an async function to handle the Firestore write operation.
    func toggleFavorite(destination: Destination) async {
        guard let userId = userId, let destinationId = destination.id else {
            self.errorMessage = "User or destination ID is missing."
            return
        }

        let userRef = Firestore.firestore().collection("users").document(userId)
        
        do {
            if self.isFavorite(destination: destination) {
                try await userRef.updateData(["favorites": FieldValue.arrayRemove([destinationId])])
            } else {
                try await userRef.updateData(["favorites": FieldValue.arrayUnion([destinationId])])
            }
        } catch {
            self.errorMessage = "Failed to toggle favorite: \(error.localizedDescription)"
            print("Failed to toggle favorite: \(error.localizedDescription)")
        }
        
        // The real-time listener will automatically update the `favorites` array.
        // No need to manually append or remove here.
    }

    func isFavorite(destination: Destination) -> Bool {
        return favorites.contains(where: { $0.id == destination.id })
    }

    // Clean up the listener when the view model is deallocated.
    deinit {
        userFavoritesListener?.remove()
    }
}
