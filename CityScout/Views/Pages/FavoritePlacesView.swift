//
//  FavoritePlacesView.swift
//  CityScout
//
//  Created by Umuco Auca on 28/05/2025.
//


import SwiftUI

struct FavoritePlacesView: View {
    @EnvironmentObject var homeVM: HomeViewModel

    var body: some View {
        VStack(spacing: 0) {
            
            if homeVM.favorites.isEmpty {
                Spacer()
                Text("No favorite places yet. Bookmark your favorites!")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(homeVM.favorites) { destination in
                            NavigationLink(destination: DestinationDetailView(destination: destination)) {
                                PopularFavoriteDestinationCard(destination: destination, isFavorite: homeVM.isFavorite(destination: destination)) {
                                    homeVM.toggleFavorite(destination: destination)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}

#Preview {
    let vm = HomeViewModel()
    Task { await vm.loadDestinations() }
    vm.toggleFavorite(destination: Destination.sampleDestinations[0])
    vm.toggleFavorite(destination: Destination.sampleDestinations[2])
    return FavoritePlacesView()
        .environmentObject(vm)
}
