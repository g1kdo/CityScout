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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                GooglePlacesImageView(photoMetadata: googleDestination.photoMetadata)
                    .frame(height: 100)
                
                // The bookmark button
                Text("External")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(8)
                    .padding(6)
            }
            .cornerRadius(10)
            .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(googleDestination.name)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                HStack {
                    if let rating = googleDestination.rating {
                        HStack(spacing: 2) {
                            ForEach(0..<Int(rating.rounded())) { _ in
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(googleDestination.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .onTapGesture {
            if let urlString = googleDestination.websiteURL, let url = URL(string: urlString) {
                openURL(url)
            }
        }
    }
}
