//
//  PersonalizedSectionsView.swift
//  CityScout
//
//  Created by Umuco Auca on 21/08/2025.
//

import SwiftUI

struct PersonalizedSectionsView: View {
    @ObservedObject var vm: HomeViewModel
    @ObservedObject var favoritesVM: FavoritesViewModel
    @Binding var selectedDestination: Destination?
    
    // A complete list of all 10 interest categories
    private let allInterests: [String] = [
        "Adventure", "Beaches", "Mountains", "City Breaks", "Foodie",
        "Cultural", "Historical", "Nature", "Relaxing", "Family"
    ]
    
    // Updated: Computed property to get the sorted keys
    private var sortedInterests: [String] {
        // Step 1: Filter interests with a score > 0 and sort them in descending order
        let interestsWithScores = allInterests.filter { key in
            return (vm.userInterestScores[key] ?? 0) > 0
        }.sorted { (key1, key2) -> Bool in
            let score1 = vm.userInterestScores[key1] ?? 0
            let score2 = vm.userInterestScores[key2] ?? 0
            return score1 > score2
        }
        
        // Step 2: Get interests with a score of 0 or those not in the interestScores dictionary.
        let interestsWithoutScores = allInterests.filter { key in
            return (vm.userInterestScores[key] ?? 0) <= 0
        }
        
        // Step 3: Combine the sorted high-score interests with the zero-score interests
        return interestsWithScores + interestsWithoutScores.sorted()
    }
    
    private func capitalizeFirstLetter(_ string: String) -> String {
        return string.prefix(1).capitalized + string.dropFirst()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // We now loop through `sortedInterests`
            ForEach(sortedInterests, id: \.self) { interest in
                // And check if there are destinations for that interest
                if let destinations = vm.categorizedDestinations[interest], !destinations.isEmpty {
                    // Section Header
                    HStack {
                        Text("\(capitalizeFirstLetter(interest)) Destinations")
                            .font(.headline).bold()
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Horizontal Scroll View
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(destinations.prefix(5)) { dest in
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
        }
    }
}
//else if !vm.isFetching {
//                Text("We're tailoring recommendations for you!")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                    .frame(maxWidth: .infinity)
//                    .padding(.top, 50)
//            }
//        }
//    }
//}

// FIX: New helper view to handle the complex logic and break up the expression.
private struct HomeDestinationCardWrapper: View {
    let destination: Destination
    @ObservedObject var favoritesVM: FavoritesViewModel
    @Binding var selectedDestination: Destination?
    
    var body: some View {
        HomeDestinationCard(
            destination: destination,
            // Wrap the Destination in AnyDestination for the FavoritesViewModel methods
            isFavorite: favoritesVM.isFavorite(destination: .local(destination))
        ) {
            Task {
                // Wrap the Destination in AnyDestination for the FavoritesViewModel method
                await favoritesVM.toggleFavorite(destination: .local(destination))
            }
        }
        .onTapGesture {
            selectedDestination = destination
        }
    }
}
