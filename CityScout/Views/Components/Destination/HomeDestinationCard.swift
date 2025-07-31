//
//  HomeDestinationCard.swift
//  CityScout
//
//  Created by Umuco Auca on 28/05/2025.
//



import SwiftUI
import Kingfisher

struct HomeDestinationCard: View {
    let destination: Destination
    var isFavorite: Bool
    let onFavoriteTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // --- Image (Now dynamic with KFImage for caching) ---
            ZStack(alignment: .topTrailing) {
                // Use the new helper view for the main destination image
                HomeDestinationImageView(imageUrl: destination.imageUrl)
                    .frame(width: 260, height: 300) // Apply frame to the helper view
                    .cornerRadius(16)
                    .clipped()
                
                Button(action: onFavoriteTapped) {
                    Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 20))
                        .foregroundColor(isFavorite ? .red : .primary)
                        .padding(12)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                }
                .padding(10)
            }
            
            // --- Title & Rating ---
            HStack {
                Text(destination.name)
                    .font(.headline)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", destination.rating))
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 12)
            
            // --- Location & Avatars ---
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .frame(width: 16, height: 16)
                    Text(destination.location)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                HStack(spacing: -12) {
                    if let avatars = destination.participantAvatars {
                        ForEach(avatars.prefix(3), id: \.self) { imageUrl in
                            // Use a separate helper for avatar images as well
                            AvatarImageView(imageUrl: imageUrl)
                                .frame(width: 32, height: 32) // Apply frame to the helper view
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        }
                        if avatars.count > 3 {
                            Text("+\(avatars.count - 3)")
                                .font(.caption)
                                .frame(width: 32, height: 32)
                                .background(Color.gray.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: 260)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// ---
// MARK: - Helper View for Main Destination Image
// ---
private struct HomeDestinationImageView: View {
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
                    .cornerRadius(16) // Match the main card's corner radius
            } else {
                KFImage(URL(string: imageUrl ?? ""))
                    .onFailure { error in
                        print("Failed to load main image: \(error.localizedDescription)")
                        self.imageLoadFailed = true // Set state to show fallback
                    }
                    .onSuccess { result in
                        self.imageLoadFailed = false // Reset state if load succeeds
                    }
                    .placeholder {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity) // Make placeholder fill its container
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(16)
                    }
                    .resizable()
                    .scaledToFill()
            }
        }
        // Ensure the content of this view fills its parent's frame
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// ---
// MARK: - Helper View for Avatar Images
// ---
private struct AvatarImageView: View {
    let imageUrl: String?
    @State private var imageLoadFailed: Bool = false

    var body: some View {
        Group {
            if imageLoadFailed {
                Image(systemName: "person.circle.fill") // Fallback for failed avatar
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.gray)
                    // No need for background/cornerRadius if parent handles clipShape(Circle())
            } else {
                KFImage(URL(string: imageUrl ?? ""))
                    .onFailure { error in
                        print("Failed to load avatar image: \(error.localizedDescription)")
                        self.imageLoadFailed = true
                    }
                    .onSuccess { result in
                        self.imageLoadFailed = false
                    }
                    .placeholder {
                        Image(systemName: "person.circle.fill") // Placeholder for avatar while loading
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.gray)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        // Ensure the content fills the frame set by the parent
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


// MARK: - Previews
#Preview {
    HomeDestinationCard(
        destination: Destination(
            id: UUID().uuidString,
            name: "Santorini Island",
            imageUrl: "https://picsum.photos/id/1015/260/300", // Example URL
            rating: 4.9,
            location: "Greece",
            participantAvatars: [
                "https://randomuser.me/api/portraits/women/1.jpg",
                "https://randomuser.me/api/portraits/men/2.jpg",
                "https://randomuser.me/api/portraits/women/3.jpg",
                "https://randomuser.me/api/portraits/men/4.jpg" // More than 3 for testing
            ],
            description: "Beautiful island with stunning sunsets.",
            price: 1200
        ),
        isFavorite: false, // For preview
        onFavoriteTapped: { print("Home card favorite tapped!") }
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview {
    HomeDestinationCard(
        destination: Destination(
            id: UUID().uuidString,
            name: "Kyoto Temples",
            imageUrl: "https://picsum.photos/id/10/260/300", // Example URL
            rating: 4.7,
            location: "Japan",
            participantAvatars: [
                "https://randomuser.me/api/portraits/men/5.jpg",
                "https://randomuser.me/api/portraits/women/6.jpg"
            ],
            description: "Historic temples and traditional gardens.",
            price: 950
        ),
        isFavorite: true, // For preview
        onFavoriteTapped: { print("Home card favorite tapped!") }
    )
    .previewLayout(.sizeThatFits)
    .padding()
}
