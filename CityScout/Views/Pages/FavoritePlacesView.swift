// FavoritePlacesView.swift
// CityScout
//
// Created by Umuco Auca on 28/05/2025.
//

import SwiftUI

struct FavoritePlacesView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel // Still need authVM for the user ID

    // Use a @StateObject to create a new instance of the FavoritesViewModel for this view
    @StateObject private var viewModel = FavoritesViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView("Loading favorites...")
                        .padding()
                } else if viewModel.favorites.isEmpty {
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
                            ForEach(viewModel.favorites) { destination in
                                NavigationLink(destination: DestinationDetailView(destination: destination)) {
                                    // Use the local viewModel to check favorite status and toggle
                                    PopularFavoriteDestinationCard(destination: destination, isFavorite: viewModel.isFavorite(destination: destination)) {
                                        viewModel.toggleFavorite(destination: destination)
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
            .navigationTitle("Bookmarked Places")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                // When the view appears, tell the viewModel to fetch the favorites
                viewModel.setup(with: authVM.signedInUser?.id)
            }
            // Listen for changes in the user's ID (e.g., sign out/in)
            .onChange(of: authVM.signedInUser?.id) { _, newId in
                viewModel.setup(with: newId)
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
