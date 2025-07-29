// FavoritePlacesView.swift
// CityScout
//
// Created by Umuco Auca on 28/05/2025.
//

import SwiftUI

struct FavoritePlacesView: View {
    @Environment(\.dismiss) var dismiss // To dismiss the view
    @EnvironmentObject var homeVM: HomeViewModel // Ensure HomeViewModel is available in the environment

    var body: some View {
        NavigationStack { // Wrap with NavigationStack for a proper navigation bar
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
            .navigationTitle("Bookmarked Places") // Set the title for the navigation bar
            .navigationBarTitleDisplayMode(.inline) // Make the title inline
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss() // Dismiss the current view (go back)
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
                }
            }
            .background(Color.white.ignoresSafeArea())
        }
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
