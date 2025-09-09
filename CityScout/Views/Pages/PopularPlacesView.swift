//
//  PopularPlacesView.swift
//  CityScout
//
//  Created by Umuco Auca on 28/05/2025.
//


// PopularPlacesView.swift
import SwiftUI

struct PopularPlacesView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var favoritesVM: FavoritesViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(title: "Popular Places")
                .padding(.bottom, 20)

            

            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible())], spacing: 20)  {
                    ForEach(homeVM.destinations) { destination in
                        NavigationLink(destination: DestinationDetailView(destination: destination)) {
                            PopularFavoriteDestinationCard(
                                destination: destination,
                                isFavorite: favoritesVM.isFavorite(destination: .local(destination))
                            ) {
                                Task {
                                    await favoritesVM.toggleFavorite(destination: .local(destination))
                                    if let userId = authVM.signedInUser?.id {
                                        await homeVM.logUserAction(userId: userId, destinationId: destination.id, actionType: "bookmark")
                                        await homeVM.updateInterestScores(for: userId, categories: destination.categories, with: 3.0)
                                    }
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationBarHidden(true)
    }
}


