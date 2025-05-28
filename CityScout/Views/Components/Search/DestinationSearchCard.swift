//
//   DestinationSearchCard.swift
//   CityScout
//
//   Created by Umuco Auca on 28/05/2025.
//

import SwiftUI

struct DestinationSearchCard: View {
    let destination: Destination
    var isFavorite: Bool
    let onFavoriteTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                
                Image(destination.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 120)
                    .cornerRadius(10)
                    .clipped()
                    .contentShape(Rectangle())
                    .drawingGroup()

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

            Text("$\(894)/Person")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "#FF7029"))
        }
        .frame(width: 150)
        .padding(.bottom, 5)
    }
}

#Preview {
    DestinationSearchCard(
        destination: Destination.sampleDestinations[0],
        isFavorite: true, // For preview
        onFavoriteTapped: { print("Search card favorite tapped!") }
    )
    .previewLayout(.sizeThatFits)
    .padding()
}
