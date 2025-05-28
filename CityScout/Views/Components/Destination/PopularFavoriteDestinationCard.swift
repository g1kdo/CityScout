//
//  PopularFavoriteDestinationCard.swift
//  CityScout
//
//  Created by Umuco Auca on 28/05/2025.
//


import SwiftUI

struct PopularFavoriteDestinationCard: View { // New card type
    let destination: Destination
    var isFavorite: Bool
    let onFavoriteTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image(destination.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
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

#Preview {
    PopularFavoriteDestinationCard(
        destination: Destination.sampleDestinations[0],
        isFavorite: false, // For preview
        onFavoriteTapped: { print("Popular/Favorite card favorite tapped!") }
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview {
    PopularFavoriteDestinationCard(
        destination: Destination.sampleDestinations[1],
        isFavorite: true, // For preview
        onFavoriteTapped: { print("Popular/Favorite card favorite tapped!") }
    )
    .previewLayout(.sizeThatFits)
    .padding()
}
