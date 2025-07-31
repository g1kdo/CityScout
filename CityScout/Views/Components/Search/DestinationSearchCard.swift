//
//   DestinationSearchCard.swift
//   CityScout
//
//   Created by Umuco Auca on 28/05/2025.
//


import SwiftUI
import Kingfisher

struct DestinationSearchCard: View {
    let destination: Destination
    var isFavorite: Bool
    let onFavoriteTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // Use the new helper view for the image logic
                SearchCardImageView(imageUrl: destination.imageUrl)
                    .frame(width: 150, height: 120) // Apply frame here for the helper view
                    .cornerRadius(10)
                    .clipped()
                    .contentShape(Rectangle()) // Keeps the tappable area

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
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundColor(.primary)

            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(destination.location)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Text("$\(destination.price)/Person")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "#FF7029"))
        }
        .frame(width: 150)
        .padding(.bottom, 5)
    }
}

private struct SearchCardImageView: View {
    let imageUrl: String?
    @State private var imageLoadFailed: Bool = false

    var body: some View {
        Group {
            if imageLoadFailed {
                // Display fallback image if loading explicitly failed
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80) // Adjust size for visibility
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Center fallback within its parent
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
                        ProgressView() // Show a loading indicator
                            .frame(maxWidth: .infinity, maxHeight: .infinity) // Make placeholder fill its container
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .resizable()
                    .scaledToFill()
            }
        }
        // Ensure the content of this view fills its parent's frame
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    // You'll need to define a sample Destination for this preview to work
    // Example:
    DestinationSearchCard(
        destination: Destination(
            id: UUID().uuidString,
            name: "Eiffel Tower",
            imageUrl: "[https://picsum.photos/id/237/150/120](https://picsum.photos/id/237/150/120)", // Placeholder URL
            rating: 4.8,
            location: "Paris, France",
            participantAvatars: [],
            description: "A beautiful landmark.",
            price: 894
        ),
        isFavorite: true,
        onFavoriteTapped: {}
    )
    .previewLayout(.sizeThatFits)
    .padding()
}
