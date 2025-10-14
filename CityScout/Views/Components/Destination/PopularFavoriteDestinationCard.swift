import SwiftUI
import Kingfisher

struct PopularFavoriteDestinationCard: View {
    let destination: Destination
    var isFavorite: Bool
    let onFavoriteTapped: () -> Void
    
    @EnvironmentObject var messageVM : MessageViewModel

    var body: some View {
        // The main VStack no longer has padding. Spacing is set to 0.
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                // The image part of the card
                DestinationImageView(imageUrl: destination.imageUrl)
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
            // --- FIX IS HERE ---
            // By applying cornerRadius and clipping directly to the image container (the ZStack),
            // we ensure the image itself has rounded corners, just like in your Search Card.
            .cornerRadius(10)
            .clipped()

            // A new VStack is added to hold only the text content.
            // Padding is now applied here, so it doesn't affect the image.
            VStack(alignment: .leading, spacing: 8) {
                Text(destination.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(destination.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", destination.rating))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                }
                HStack(spacing: 4) {
                    Text("$\(String(format: "%.2f", destination.price))")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#FF7029"))
                    Text("per Person")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .padding(8) // Padding is now correctly applied only to the text content
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10) // This corner radius now correctly clips all four corners of the card.
        .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Helper view for the image
private struct DestinationImageView: View {
    let imageUrl: String?
    @State private var imageLoadFailed: Bool = false

    var body: some View {
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
