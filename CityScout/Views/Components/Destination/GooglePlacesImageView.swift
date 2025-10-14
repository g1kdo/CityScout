import SwiftUI
import GooglePlaces

struct GooglePlacesImageView: View {
    let photoMetadata: GMSPlacePhotoMetadata?
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    private let kHeaderHeightFactor: CGFloat = 0.5
    
    @StateObject private var loader: GooglePlacesImageLoader
    
    init(photoMetadata: GMSPlacePhotoMetadata?) {
        self.photoMetadata = photoMetadata
        // Initialize the StateObject with the photo metadata
        _loader = StateObject(wrappedValue: GooglePlacesImageLoader(photoMetadata: photoMetadata))
    }

    var body: some View {
        // Use GeometryReader to force the image/content to fill the size defined by the outer .frame
        GeometryReader { geometry in
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
            // Ensure the content inside the GeometryReader takes up the full space
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .onAppear {
                loader.fetchImage()
            }
        }
        // Apply responsive height constraint outside the GeometryReader
        // Small screen (iPhone/iPad Portrait): kHeaderHeightFactor (e.g., 65% of screen height)
        // Large screen (iPad Landscape): nil, allowing the parent HStack/frame to dictate the size (full height)
        .frame(height: horizontalSizeClass != .regular ? UIScreen.main.bounds.height * kHeaderHeightFactor : nil)
    }
}
