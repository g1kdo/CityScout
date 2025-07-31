//
//  PopularFavoriteDestinationCard.swift
//  CityScout
//
//  Created by Umuco Auca on 28/05/2025.
//


//
//  PopularFavoriteDestinationCard.swift
//  CityScout
//
//  Created by Umuco Auca on 28/05/2025.
//

import SwiftUI
import Kingfisher // Import Kingfisher

struct PopularFavoriteDestinationCard: View {
    let destination: Destination
    var isFavorite: Bool
    let onFavoriteTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // Use the new helper view for the image logic
                DestinationImageView(imageUrl: destination.imageUrl)
                    .frame(height: 120) // Apply frame here for the helper view
                    .frame(maxWidth: .infinity)
                    .cornerRadius(10)
                    .clipped()

                Button(action: onFavoriteTapped) {
                    Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16))
                        .foregroundColor(isFavorite ? .red : .white)
                        .shadow(radius: 2)
                        .padding(6)
                }
                .padding(4)
            }

            Text(destination.name)
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(1)
                .foregroundColor(.primary)
                .padding(.horizontal, 8)

            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(destination.location)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                Text(String(format: "%.1f", destination.rating))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DestinationImageView: View {
    let imageUrl: String?
    @State private var imageLoadFailed: Bool = false

    var body: some View {
        Group {
            if imageLoadFailed {
                // Display fallback image if loading explicitly failed
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100) // Adjust size as needed
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Center fallback
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10) // Match the main image's corner radius
            } else {
                KFImage(URL(string: imageUrl ?? ""))
                    .onFailure { error in
                        print("Failed to load image: \(error.localizedDescription)")
                        self.imageLoadFailed = true // Set state to show fallback
                    }
                    .onSuccess { result in
                        self.imageLoadFailed = false // Reset state if load succeeds
                    }
                    .placeholder {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .resizable()
                    .scaledToFill()
            }
        }
        // Ensure the outer frame and clipping is applied to the content of this view
        // The parent view will typically set the explicit frame, but this ensures internal content fills
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    // You'll need to define a sample Destination for this preview to work
    // Example:
    PopularFavoriteDestinationCard(
        destination: Destination(
            id: UUID().uuidString,
            name: "Great Barrier Reef Adventure",
            imageUrl: "[https://picsum.photos/id/1047/300/200](https://picsum.photos/id/1047/300/200)", // Placeholder URL
            rating: 4.9,
            location: "Queensland, Australia",
            participantAvatars: [],
            description: "An incredible diving experience.",
            price: 1500
        ),
        isFavorite: false, // For preview
        onFavoriteTapped: { print("Popular/Favorite card favorite tapped!") }
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview {
    PopularFavoriteDestinationCard(
        destination: Destination(
            id: UUID().uuidString,
            name: "Mount Fuji Climbing Tour",
            imageUrl: "[https://picsum.photos/id/214/300/200](https://picsum.photos/id/214/300/200)", // Placeholder URL
            rating: 4.7,
            location: "Honshu, Japan",
            participantAvatars: [],
            description: "Experience the iconic climb.",
            price: 950
        ),
        isFavorite: true, // For preview
        onFavoriteTapped: { print("Popular/Favorite card favorite tapped!") }
    )
    .previewLayout(.sizeThatFits)
    .padding()
}
