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
    let onCardTapped: () -> Void

    var body: some View {
        Button(action: onCardTapped) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    // This view will now handle its own loading and display
                    GooglePlacesImageView(photoMetadata: googleDestination.photoMetadata)
                        .frame(height: 100)
                        .clipped() // Ensure the image stays within its frame
                    
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
                    .buttonStyle(PlainButtonStyle())
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
                    
                    // Display rating and price level from the GoogleDestination object
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
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
