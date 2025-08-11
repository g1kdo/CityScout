// FavoritePlacesView.swift
// CityScout
//
// Created by Umuco Auca on 28/05/2025.
//

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
            VStack(spacing: 20) {
                // MODIFIED: Calling the new computed property to simplify the body
                favoritesContent
            }
            .navigationTitle("Bookmarked Places")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Circle().fill(Color(.systemGray6)).frame(width: 44, height: 44))
                    }
                }
            }
            .onAppear {
                // MODIFIED: Use the new subscribeToFavorites method
                viewModel.subscribeToFavorites(for: authVM.signedInUser?.id)
            }
            // MODIFIED: Use the new subscribeToFavorites method
            .onChange(of: authVM.signedInUser?.id) { _, newId in
                viewModel.subscribeToFavorites(for: newId)
            }
            .background(Color.white.ignoresSafeArea())
        }
    }

    // NEW: Break down the complex conditional view logic into a computed property
    @ViewBuilder
    private var favoritesContent: some View {
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
                            PopularFavoriteDestinationCard(
                                destination: destination,
                                isFavorite: viewModel.isFavorite(destination: destination)
                            ) {
                                // MODIFIED: Wrap the async function call in a Task
                                Task {
                                    await viewModel.toggleFavorite(destination: destination)
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
    }
}

#Preview {
    // You can now create a more accurate preview with mock data
    // Assuming you have a way to create a mock FavoritesViewModel with sample data
    let mockFavoritesVM = FavoritesViewModel()
    // To see the view with data, you would manually set favorites like so:
    // mockFavoritesVM.favorites = [Destination.sampleDestinations[0], Destination.sampleDestinations[2]]
    
    return FavoritePlacesView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(mockFavoritesVM)
}
