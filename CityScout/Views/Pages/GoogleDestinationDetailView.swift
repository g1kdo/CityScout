//
//  GoogleDestinationDetailView.swift
//  CityScout
//
//  Created by Umuco Auca on 03/09/2025.
//


import SwiftUI
import GooglePlaces

struct GoogleDestinationDetailView: View {
    let googleDestination: GoogleDestination
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // Display the photo using the helper view
            GooglePlacesImageView(photoMetadata: googleDestination.photoMetadata)
                .frame(height: 250)
                .cornerRadius(15)
                .shadow(radius: 5)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(googleDestination.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(googleDestination.location)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // You can add more details here, such as:
            if let rating = googleDestination.rating {
                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Rating: \(String(format: "%.1f", rating))")
                        .font(.body)
                }
            }
            
            if let websiteURL = googleDestination.websiteURL, let url = URL(string: websiteURL) {
                Link("Visit Website", destination: url)
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle(googleDestination.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
