//
//  GoogleDestinationCard.swift
//  CityScout
//
//  Created by Umuco Auca on 03/09/2025.
//

import SwiftUI
import Kingfisher
import GooglePlaces

struct GoogleDestinationCard: View {
    let googleDestination: GoogleDestination
    @Environment(\.openURL) var openURL
    
    @State private var isFavorite: Bool = false
    
    let onFavoriteTapped: () -> Void
    // 🆕 Add a new closure to handle the card tap for navigation
    let onCardTapped: () -> Void

    var body: some View {
        // Wrap the entire card in a Button to handle the tap action
        Button(action: onCardTapped) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    // The image part of the card
                    GooglePlacesImageView(photoMetadata: googleDestination.photoMetadata)
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
                    // ⚠️ IMPORTANT: Prevent this button's tap from triggering the parent Button's action
                    .buttonStyle(PlainButtonStyle())
                }
                .cornerRadius(10)
                .clipped()

                // A new VStack is added to hold only the text content.
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
                    }
                    
                    if let priceLevel = googleDestination.priceLevel {
                        HStack(spacing: 4) {
                            Text(String(repeating: "$", count: priceLevel))
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
        // 🆕 Use .buttonStyle(PlainButtonStyle()) to remove the button's default visual effects
        .buttonStyle(PlainButtonStyle())
    }
}
