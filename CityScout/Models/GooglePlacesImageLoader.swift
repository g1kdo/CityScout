//
//  GooglePlacesImageLoader.swift
//  CityScout
//
//  Created by Umuco Auca on 09/09/2025.
//


import Foundation
import SwiftUI
import GooglePlaces

class GooglePlacesImageLoader: ObservableObject {
    @Published var image: UIImage? = nil
    @Published var isLoading = false
    @Published var error: Error?

    private var photoMetadata: GMSPlacePhotoMetadata?

    init(photoMetadata: GMSPlacePhotoMetadata?) {
        self.photoMetadata = photoMetadata
    }

    func fetchImage() {
        guard let photoMetadata = photoMetadata, !isLoading else { return }

        self.isLoading = true
        self.error = nil

        GMSPlacesClient.shared().loadPlacePhoto(photoMetadata) { [weak self] photo, loadError in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let loadError = loadError {
                    self.error = loadError
                    print("Error loading Google Places photo: \(loadError.localizedDescription)")
                    return
                }
                
                self.image = photo
            }
        }
    }
}