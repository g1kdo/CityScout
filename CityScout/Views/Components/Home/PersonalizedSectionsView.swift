//
//  PersonalizedSectionsView.swift
//  CityScout
//
//  Created by Umuco Auca on 21/08/2025.
//

import SwiftUI

struct PersonalizedSectionsView: View {
    @ObservedObject var vm: HomeViewModel
    @ObservedObject var favoritesVM: FavoritesViewModel
    @Binding var selectedDestination: Destination?

    // The display order for interests
    private let interestOrder: [String] = [
        "Adventure", "Beaches", "Mountains", "City Breaks", "Foodie",
        "Cultural", "Historical", "Nature", "Relaxing", "Family"
    ]
    
    // Helper function to capitalize the first letter of a string
    private func capitalizeFirstLetter(_ string: String) -> String {
        return string.prefix(1).capitalized + string.dropFirst()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Check if there are any personalized destinations to show
            if !vm.categorizedDestinations.isEmpty {
                ForEach(interestOrder, id: \.self) { interest in
                    if let destinations = vm.categorizedDestinations[interest], !destinations.isEmpty {
                        // Section Header
                        HStack {
                            Text("\(capitalizeFirstLetter(interest)) Destinations")
                                .font(.headline).bold()
                            Spacer()
//                            // "View all" button, could navigate to a dedicated view
//                            Button("View all") {
//                                // Action to show all destinations for this category
//                                // You will need to implement this navigation logic.
//                                // For now, it's a placeholder.
//                            }
//                            .font(.subheadline)
//                            .foregroundColor(Color(hex: "#FF7029"))
                        }
                        .padding(.horizontal)

                        // Horizontal Scroll View for Destination Cards
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(destinations.prefix(5)) { dest in // Limit to 5 cards per section
                                    HomeDestinationCard(
                                        destination: dest,
                                        isFavorite: favoritesVM.isFavorite(destination: dest)
                                    ) {
                                        Task {
                                            await favoritesVM.toggleFavorite(destination: dest)
                                        }
                                    }
                                    .onTapGesture {
                                        selectedDestination = dest
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            } else if !vm.isFetching {
                // Display this message if no personalized destinations are found
                Text("We're tailoring recommendations for you!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 50)
            }
        }
    }
}
