//
//  PersonalizedSectionsView.swift
//  CityScout
//
//  Created by Umuco Auca on 21/08/2025.
//

import SwiftUI

struct PersonalizedSectionsView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var homeVM: HomeViewModel
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
            return (homeVM.userInterestScores[key] ?? 0) > 0
        }.sorted { (key1, key2) -> Bool in
            let score1 = homeVM.userInterestScores[key1] ?? 0
            let score2 = homeVM.userInterestScores[key2] ?? 0
            return score1 > score2
        }
        
        // Step 2: Get interests with a score of 0 or those not in the interestScores dictionary.
        let interestsWithoutScores = allInterests.filter { key in
            return (homeVM.userInterestScores[key] ?? 0) <= 0
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
                if let destinations = homeVM.categorizedDestinations[interest], !destinations.isEmpty {
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
                                .environmentObject(authVM)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}
//else if !homeVM.isFetching {
//                Text("We're tailoring recommendations for you!")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                    .frame(maxWidth: .infinity)
//                    .padding(.top, 50)
//            }
//        }
//    }
//}

private struct HomeDestinationCardWrapper: View {
    let destination: Destination
    @ObservedObject var favoritesVM: FavoritesViewModel
    @Binding var selectedDestination: Destination?
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var homeVM: HomeViewModel

    var body: some View {
        HomeDestinationCard(
            destination: destination
        )
        .onTapGesture {
            selectedDestination = destination
            // Log and update score on tap
            if let userId = authVM.signedInUser?.id {
                Task {
                    await homeVM.logUserAction(userId: userId, destinationId: destination.id, actionType: "card_click")
                    // Increase score on click
                    await homeVM.updateInterestScores(for: userId, categories: destination.categories, with: 1.0)
                }
            }
        }
    }
}
