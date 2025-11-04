import SwiftUI
import Kingfisher
import GooglePlaces

struct GoogleDestinationCard: View {
    let googleDestination: GoogleDestination
    @Environment(\.openURL) var openURL
    
    // 1. ADD environment variable for screen size adaptation
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State private var isFavorite: Bool = false
    
    let onCardTapped: () -> Void

    var body: some View {
        // 2. Calculate adaptive image height
        let imageHeight: CGFloat = (horizontalSizeClass == .regular) ? 180 : 100

        Button(action: onCardTapped) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    GooglePlacesImageView(photoMetadata: googleDestination.photoMetadata)
                        // 3. APPLY adaptive height
                        .frame(height: imageHeight)
                        .clipped()
                }
                .cornerRadius(10)
                .clipped()

                VStack(alignment: .leading, spacing: 8) {
                    Text(googleDestination.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(googleDestination.location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if let rating = googleDestination.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            // Corrected to display N/A properly if rating is missing
                            Text("N/A")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // ⚠️ Corrected logic for price level
                    if let priceLevel = googleDestination.priceLevel {
                        HStack(spacing: 4) {
                            if priceLevel == 0 {
                                Text("Free")
                                    .font(.footnote)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            } else {
                                Text(String(repeating: "$", count: priceLevel))
                                    .font(.footnote)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(hex: "#FF7029"))
                                Text("per Person")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        HStack(spacing: 4) {
                            Text("$")
                                .font(.footnote)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#FF7029"))
                            Text("N/A")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(8)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
