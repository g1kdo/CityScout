//
//  PopularPlacesView.swift
//  CityScout
//
//  Created by Umuco Auca on 28/05/2025.
//


import SwiftUI

struct PopularPlacesView: View {
    @EnvironmentObject var homeVM: HomeViewModel
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
                            // Use PopularFavoriteDestinationCard for Popular Places
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
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

#Preview {
    let vm = HomeViewModel()
    Task { await vm.loadDestinations() }
    return PopularPlacesView()
        .environmentObject(vm)
}
