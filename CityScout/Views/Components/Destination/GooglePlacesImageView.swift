//
//  GooglePlacesImageView.swift
//  CityScout
//
//  Created by Umuco Auca on 03/09/2025.
//

import SwiftUI
import GooglePlaces

struct GooglePlacesImageView: View {
    let photoMetadata: GMSPlacePhotoMetadata?
    @State private var image: UIImage? = nil
    @State private var isLoading = false
    @State private var error: Error?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.secondary.opacity(0.1))
            } else if error != nil {
                // Display a placeholder or a simple image indicating an error
                Image(systemName: "photo.fill")
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.secondary.opacity(0.1))
            } else {
                Color.secondary.opacity(0.1)
            }
        }
        .task(id: photoMetadata) {
            guard let photoMetadata = photoMetadata else { return }
            
            isLoading = true
            error = nil
            
            // This is the older callback-based method.
            // It is needed for compatibility with your current SDK version.
            GMSPlacesClient.shared().loadPlacePhoto(photoMetadata) { (photo, error) in
                // Ensure we are on the main thread for UI updates
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.error = error
                        print("Error loading Google Places photo: \(error.localizedDescription)")
                        return
                    }
                    
                    self.image = photo
                }
            }
        }
    }
}

