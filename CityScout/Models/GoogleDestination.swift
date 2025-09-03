//
//  GoogleDestination.swift
//  CityScout
//
//  Created by Umuco Auca on 03/09/2025.
//

import GooglePlaces
import Foundation

struct GoogleDestination: Identifiable {
    var id: String { placeID }
    let placeID: String
    let name: String
    let location: String
    let photoMetadata: GMSPlacePhotoMetadata?
    let websiteURL: String?
    let rating: Double?
    let latitude: Double?
    let longitude: Double?
    
}

enum AnyDestination: Identifiable {
    case local(Destination)
    case google(GoogleDestination)
    
    var id: String {
        switch self {
        case .local(let destination):
            return destination.id ?? "N/A"
        case .google(let destination):
            return destination.id
        }
    }
}
