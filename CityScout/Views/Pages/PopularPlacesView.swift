//
//  PopularPlacesView.swift
//  CityScout
//
//  Created by Umuco Auca on 28/05/2025.
//


// PopularPlacesView.swift
import SwiftUI

struct PopularPlacesView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var favoritesVM: FavoritesViewModel // NEW: Add the Favorites ViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(title: "Popular Places")
                .padding(.bottom, 20)

            Text("All Popular Places")
                .font(.headline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 10)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(homeVM.destinations) { destination in
                        NavigationLink(destination: DestinationDetailView(destination: destination)) {
                            PopularFavoriteDestinationCard(
                                destination: destination,
                                isFavorite: favoritesVM.isFavorite(destination: destination) // MODIFIED: Use favoritesVM
                            ) {
                                Task {
                                    await favoritesVM.toggleFavorite(destination: destination) // MODIFIED: Use favoritesVM
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
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

#Preview {
    // You can now create a more accurate preview with both view models
    let homeVM = HomeViewModel()
    let favoritesVM = FavoritesViewModel()
    return PopularPlacesView()
        .environmentObject(homeVM)
        .environmentObject(favoritesVM)
}
