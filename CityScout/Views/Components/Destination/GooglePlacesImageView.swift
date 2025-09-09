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
        // Corrected: Using photoMetadata directly as the ID, as it is Hashable.
        .task(id: photoMetadata) {
            guard let photoMetadata = photoMetadata else {
                image = nil
                return
            }
            
            isLoading = true
            error = nil
            
            GMSPlacesClient.shared().loadPlacePhoto(photoMetadata) { photo, loadError in
                DispatchQueue.main.async {
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
}
