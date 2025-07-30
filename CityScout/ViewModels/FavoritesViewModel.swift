//
//  FavoritesViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 30/07/2025.
//


import SwiftUI
import FirebaseFirestore

class FavoritesViewModel: ObservableObject {
    @Published var favorites: [Destination] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // A reference to the currently signed-in user's ID
    private var userId: String?

    // Use a Firestore listener to automatically update favorites
    private var favoritesListener: ListenerRegistration?

    func setup(with userId: String?) {
        guard self.userId != userId else { return } // Avoid re-setting up if user is the same
        self.userId = userId
        // Clean up old listener if a new user signs in
        if favoritesListener != nil {
            favoritesListener?.remove()
            favoritesListener = nil
        }
        
        if let userId = userId {
            fetchFavorites(for: userId)
        } else {
            // User signed out, clear favorites
            self.favorites = []
        }
    }

    private func fetchFavorites(for userId: String) {
        isLoading = true
        errorMessage = nil

        // Step 1: Fetch the user's document to get the array of favorite destination IDs
        let userRef = Firestore.firestore().collection("users").document(userId)

        userRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            guard let document = document, document.exists, let favoriteIds = document.data()?["favorites"] as? [String] else {
                self.isLoading = false
                self.favorites = []
                print("No favorites found for user or document does not exist.")
                return
            }
            
            // Step 2: Now fetch the full destination documents using the IDs
            self.favorites = [] // Clear old data
            self.fetchDestinations(for: favoriteIds)
        }
    }

    private func fetchDestinations(for ids: [String]) {
        guard !ids.isEmpty else {
            self.isLoading = false
            return
        }

        let destinationRef = Firestore.firestore().collection("destinations")
        
        // This query fetches all destinations whose ID is in the 'ids' array
        destinationRef.whereField(FieldPath.documentID(), in: ids).getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Error fetching favorite destinations: \(error.localizedDescription)"
                print(self.errorMessage!)
                return
            }

            guard let documents = snapshot?.documents else {
                self.errorMessage = "No matching destination documents found."
                print(self.errorMessage!)
                return
            }
            
            // Decode the fetched documents into Destination objects
            self.favorites = documents.compactMap { doc in
                try? doc.data(as: Destination.self)
            }
        }
    }
    
    // You'll also need a method to toggle a favorite, which will update Firestore
    func toggleFavorite(destination: Destination) {
        guard let userId = userId, let destinationId = destination.id else {
            self.errorMessage = "User or destination ID is missing."
            return
        }

        let userRef = Firestore.firestore().collection("users").document(userId)

        if self.isFavorite(destination: destination) {
            // Remove the favorite
            userRef.updateData(["favorites": FieldValue.arrayRemove([destinationId])]) { [weak self] error in
                if let error = error {
                    print("Error removing favorite: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to remove favorite."
                } else {
                    print("Successfully removed favorite.")
                    // Manually update the local array
                    self?.favorites.removeAll { $0.id == destination.id }
                }
            }
        } else {
            // Add the favorite
            userRef.updateData(["favorites": FieldValue.arrayUnion([destinationId])]) { [weak self] error in
                if let error = error {
                    print("Error adding favorite: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to add favorite."
                } else {
                    print("Successfully added favorite.")
                    // Manually update the local array
                    self?.favorites.append(destination)
                }
            }
        }
    }

    func isFavorite(destination: Destination) -> Bool {
        return favorites.contains(where: { $0.id == destination.id })
    }

    // Clean up the listener when the view is no longer needed
    deinit {
        favoritesListener?.remove()
    }
}