import SwiftUI
import GooglePlaces

struct GooglePlacesImageView: View {
    let photoMetadata: GMSPlacePhotoMetadata?
    
    // Use @StateObject to create and manage the lifecycle of the loader object
    @StateObject private var loader: GooglePlacesImageLoader
    
    init(photoMetadata: GMSPlacePhotoMetadata?) {
        self.photoMetadata = photoMetadata
        // Initialize the StateObject with the photo metadata
        _loader = StateObject(wrappedValue: GooglePlacesImageLoader(photoMetadata: photoMetadata))
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if loader.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.secondary.opacity(0.1))
            } else if loader.error != nil {
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
        .onAppear {
            loader.fetchImage()
        }
    }
}
