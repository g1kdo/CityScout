import SwiftUI
import Kingfisher

struct HomeDestinationCard: View {
    let destination: Destination
    var isFavorite: Bool
    let onFavoriteTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // --- Image ---
            ZStack(alignment: .topTrailing) {
                HomeDestinationImageView(imageUrl: destination.imageUrl)
                    .frame(width: 260, height: 300)
                    .cornerRadius(16)
                    .clipped()
            
                Button(action: onFavoriteTapped) {
                    Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 20))
                        .foregroundColor(isFavorite ? .red : .primary)
                        .padding(12)
                        // Replaced white background with a semi-transparent material for a modern look
                        .background(.thinMaterial)
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
                        .foregroundColor(.secondary) // Replaced .gray
                        .lineLimit(1)
                }
            
                Spacer()
            
                HStack(spacing: -12) {
                    if let avatars = destination.participantAvatars {
                        ForEach(avatars.prefix(3), id: \.self) { imageUrl in
                            AvatarImageView(imageUrl: imageUrl)
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2)) // Use adaptive background for stroke
                        }
                        if avatars.count > 3 {
                            Text("+\(avatars.count - 3)")
                                .font(.caption)
                                .frame(width: 32, height: 32)
                                .background(Color.secondary.opacity(0.3)) // Replaced .gray
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: 260)
        // Replaced Color.white with an adaptive background
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.08), radius: 8, x: 0, y: 4) // Use adaptive shadow
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
                    .frame(width: 100, height: 100)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(16)
            } else {
                KFImage(URL(string: imageUrl ?? ""))
                    .onFailure { error in
                        print("Failed to load main image: \(error.localizedDescription)")
                        self.imageLoadFailed = true
                    }
                    .onSuccess { result in
                        self.imageLoadFailed = false
                    }
                    .placeholder {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(16)
                    }
                    .resizable()
                    .scaledToFill()
            }
        }
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
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.secondary)
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
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.secondary)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
