//
//  FavoritesViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 20/09/2025.
//

import SwiftUI
import FirebaseFirestore
import GooglePlaces

@MainActor
class FavoritesViewModel: ObservableObject {
    @Published var favorites: [Favorite] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var favoritesListener: ListenerRegistration?
    private let db = Firestore.firestore()

    func subscribeToFavorites(for userId: String?) {
        favoritesListener?.remove()

        guard let userId = userId else {
            favorites = []
            return
        }

        isLoading = true
        let favoritesCollection = db.collection("favorites")

        favoritesListener = favoritesCollection
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    print("Error fetching favorites: \(error.localizedDescription)")
                    self.errorMessage = "Failed to load favorites. Please try again later."
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    self.favorites = []
                    return
                }

                self.favorites = documents.compactMap { doc -> Favorite? in
                    try? doc.data(as: Favorite.self)
                }
            }
    }

    // Pass the userId as an explicit parameter here
    func toggleFavorite(destination: AnyDestination, for userId: String) async {
        let favoritesCollection = db.collection("favorites")
        
        switch destination {
        case .local(let localDestination):
            guard let destinationId = localDestination.id else { return }

            if isFavorite(destination: destination) {
                // Remove local favorite
                await removeFavorite(userId: userId, type: "local", id: destinationId)
            } else {
                // Add local favorite
                let favorite = Favorite(
                    userId: userId,
                    destinationType: "local",
                    localDestination: localDestination,
                    googlePlaceID: nil,
                    googlePlaceName: nil,
                    googlePlaceLocation: nil
                )
                await addFavorite(favorite)
            }
        case .google(let googleDestination, _):
            if isFavorite(destination: destination) {
                // Remove Google favorite
                await removeFavorite(userId: userId, type: "google", id: googleDestination.placeID)
            } else {
                // Add Google favorite
                let favorite = Favorite(
                    userId: userId,
                    destinationType: "google",
                    localDestination: nil,
                    googlePlaceID: googleDestination.placeID,
                    googlePlaceName: googleDestination.name,
                    googlePlaceLocation: googleDestination.location
                )
                await addFavorite(favorite)
            }
        }
    }

    private func addFavorite(_ favorite: Favorite) async {
        let favoritesCollection = db.collection("favorites")
        do {
            try favoritesCollection.addDocument(from: favorite)
            print("Successfully added a new favorite.")
        } catch {
            print("Error adding favorite: \(error.localizedDescription)")
        }
    }

    private func removeFavorite(userId: String, type: String, id: String) async {
        let favoritesCollection = db.collection("favorites")
        do {
            let snapshot = try await favoritesCollection
                .whereField("userId", isEqualTo: userId)
                .whereField("destinationType", isEqualTo: type)
                .getDocuments()

            for doc in snapshot.documents {
                if type == "local", let fav = try? doc.data(as: Favorite.self), fav.localDestination?.id == id {
                    try await doc.reference.delete()
                    print("Successfully removed local favorite.")
                } else if type == "google", let fav = try? doc.data(as: Favorite.self), fav.googlePlaceID == id {
                    try await doc.reference.delete()
                    print("Successfully removed Google favorite.")
                }
            }
        } catch {
            print("Error removing favorite: \(error.localizedDescription)")
        }
    }

    func isFavorite(destination: AnyDestination) -> Bool {
        switch destination {
        case .local(let localDestination):
            return favorites.contains { fav in
                fav.destinationType == "local" && fav.localDestination?.id == localDestination.id
            }
        case .google(let googleDestination, _):
            return favorites.contains { fav in
                fav.destinationType == "google" && fav.googlePlaceID == googleDestination.placeID
            }
        }
    }

    deinit {
        favoritesListener?.remove()
    }
}
