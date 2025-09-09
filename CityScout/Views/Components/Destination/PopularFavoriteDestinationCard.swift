import SwiftUI
import Kingfisher

struct PopularFavoriteDestinationCard: View {
    // Change the type to AnyDestination
    let destination: AnyDestination
    var isFavorite: Bool
    let onFavoriteTapped: () -> Void

    var body: some View {
        // Use a switch statement to handle different destination types
        switch destination {
        case .local(let localDest):
            cardContent(
                name: localDest.name,
                location: localDest.location,
                rating: localDest.rating,
                price: localDest.price,
                imageUrl: localDest.imageUrl
            )
        case .google(let googleDest, _):
            cardContent(
                name: googleDest.name,
                location: googleDest.location,
                rating: googleDest.rating,
                price: nil, // Google Places might not have this, so it's optional
                imageUrl: nil // You'll need a separate helper to get the image from GMSPlacePhotoMetadata
            )
        }
    }

    // Helper view to avoid code duplication for the card layout
    private func cardContent(name: String, location: String, rating: Double?, price: Double?, imageUrl: String?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                // The image part of the card
                DestinationImageView(imageUrl: imageUrl)
                    .frame(height: 100)

                // The bookmark button
                Button(action: onFavoriteTapped) {
                    Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16))
                        .foregroundColor(isFavorite ? .red : .primary)
                        .shadow(radius: 2)
                        .padding(8)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
                .padding(6)
            }
            .cornerRadius(10)
            .clipped()

            VStack(alignment: .leading, spacing: 8) {
                Text(name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if let rating = rating, rating > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let price = price {
                    HStack(spacing: 4) {
                        Text("$\(String(format: "%.2f", price))")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#FF7029"))
                        Text("per Person")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Helper view for the image
private struct DestinationImageView: View {
    let imageUrl: String?
    @State private var imageLoadFailed: Bool = false

    var body: some View {
        // KFImage requires a URL, but Google Places needs a separate fetch for the photo
        // For Google Destinations, this view will show a placeholder since `imageUrl` is nil
        KFImage(URL(string: imageUrl ?? ""))
            .onFailure { error in
                print("Failed to load image: \(error.localizedDescription)")
                self.imageLoadFailed = true
            }
            .onSuccess { result in
                self.imageLoadFailed = false
            }
            .placeholder {
                ZStack {
                    Color.secondary.opacity(0.1)
                    ProgressView()
                }
            }
            .resizable()
            .scaledToFill()
    }
}
