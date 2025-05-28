//
//  HomeDestinationCard.swift
//  CityScout
//
//  Created by Umuco Auca on 28/05/2025.
//


import SwiftUI

struct HomeDestinationCard: View {
    let destination: Destination
    var isFavorite: Bool
    let onFavoriteTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // --- Image ---
            ZStack(alignment: .topTrailing) {
                Image(destination.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 260, height: 300)
                    .clipped()
                    .cornerRadius(16)

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
                    ForEach(destination.participantAvatars.prefix(3), id: \.self) { imageName in
                        AvatarViewLocal(imageName: imageName, size: 32)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                    if destination.participantAvatars.count > 3 {
                        Text("+\(destination.participantAvatars.count - 3)")
                            .font(.caption)
                            .frame(width: 32, height: 32)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(Circle())
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

#Preview {
    HomeDestinationCard(
        destination: Destination.sampleDestinations[0],
        isFavorite: false, // For preview
        onFavoriteTapped: { print("Home card favorite tapped!") }
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview {
    HomeDestinationCard(
        destination: Destination.sampleDestinations[1],
        isFavorite: true, // For preview
        onFavoriteTapped: { print("Home card favorite tapped!") }
    )
    .previewLayout(.sizeThatFits)
    .padding()
}
