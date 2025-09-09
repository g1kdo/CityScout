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
                    // Wrap the content of the ForEach in an AnyView to resolve the generic type error
                    AnyView(
                        Group {
                            if let destinations = vm.categorizedDestinations[interest], !destinations.isEmpty {
                                // Section Header
                                HStack {
                                    Text("\(capitalizeFirstLetter(interest)) Destinations")
                                        .font(.headline).bold()
                                    Spacer()
                                }
                                .padding(.horizontal)

                                // Horizontal Scroll View for Destination Cards
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(destinations.prefix(5)) { dest in // Limit to 5 cards per section
                                            // FIX: Extract the card and its logic into a separate, reusable view.
                                            HomeDestinationCardWrapper(
                                                destination: dest,
                                                favoritesVM: favoritesVM,
                                                selectedDestination: $selectedDestination
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    )
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

// FIX: New helper view to handle the complex logic and break up the expression.
private struct HomeDestinationCardWrapper: View {
    let destination: Destination
    @ObservedObject var favoritesVM: FavoritesViewModel
    @EnvironmentObject var authVM: AuthenticationViewModel // Use @EnvironmentObject to get the VM
    @Binding var selectedDestination: Destination?
    
    var body: some View {
        HomeDestinationCard(
            destination: destination,
            // Wrap the Destination in AnyDestination for the FavoritesViewModel methods
            isFavorite: favoritesVM.isFavorite(destination: .local(destination))
        ) {
            Task {
                if let userId = authVM.signedInUser?.id {
                    // Pass the userId to the toggleFavorite method
                    await favoritesVM.toggleFavorite(destination: .local(destination), for: userId)
                }
            }
        }
        .onTapGesture {
            selectedDestination = destination
        }
    }
}
