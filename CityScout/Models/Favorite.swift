//
//  Favorite.swift
//  CityScout
//
//  Created by Umuco Auca on 09/09/2025.
//

import Foundation
import FirebaseFirestore
import GooglePlaces

// This is the new model to store favorite destinations.
struct Favorite: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let destinationType: String // "local" or "google"
    let localDestination: Destination?
    let googlePlaceID: String?
    let googlePlaceName: String?
    let googlePlaceLocation: String?
}

extension Favorite {
    // This computed property returns the destination in a consistent format
    // for use in your views.
    var anyDestination: AnyDestination? {
        if destinationType == "local", let local = localDestination {
            return .local(local)
        } else if destinationType == "google", let id = googlePlaceID, let name = googlePlaceName, let location = googlePlaceLocation {
            // Note: This GoogleDestination is a simplified version.
            // You will need to fetch full details if a user taps on it.
            return .google(GoogleDestination(
                placeID: id,
                name: name,
                location: location,
                photoMetadata: nil,
                websiteURL: nil,
                rating: nil,
                latitude: nil,
                longitude: nil,
                priceLevel: nil,
                description: nil,
                galleryImageUrls: nil
            ), sessionToken: nil) // Session token is not needed for a saved favorite.
        }
        return nil
    }
}
