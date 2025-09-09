import SwiftUI
import GooglePlaces

struct FavoritePlacesView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel

    @StateObject private var viewModel = FavoritesViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
                viewModel.subscribeToFavorites(for: authVM.signedInUser?.id)
            }
            .onChange(of: authVM.signedInUser?.id) { _, newId in
                viewModel.subscribeToFavorites(for: newId)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }

    @ViewBuilder
    private var favoritesContent: some View {
        if viewModel.isLoading {
            Spacer()
            ProgressView("Loading favorites...")
            Spacer()
        } else if viewModel.favorites.isEmpty {
            Spacer()
            Text("No favorite places yet. Bookmark your favorites!")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible())], spacing: 20) {
                    ForEach(viewModel.favorites) { favorite in
                        if let destination = favorite.anyDestination {
                            NavigationLink(destination: DestinationDetailViewWrapper(destination: destination)) {
                                PopularFavoriteDestinationCard(
                                    destination: destination,
                                    isFavorite: viewModel.isFavorite(destination: destination)
                                ) {
                                    Task {
                                        // Pass the userId here from the environment object
                                        if let userId = authVM.signedInUser?.id {
                                            await viewModel.toggleFavorite(destination: destination, for: userId)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct DestinationDetailViewWrapper: View {
    let destination: AnyDestination
    @EnvironmentObject var homeVM: HomeViewModel
    @State private var fullGoogleDestination: GoogleDestination?
    @State private var isLoadingDetails = false
    @State private var isError = false
    
    var body: some View {
        VStack {
            switch destination {
            case .local(let localDest):
                DestinationDetailView(destination: localDest)
            case .google(let googleDest, let sessionToken):
                GoogleDestinationDetailView(googleDestination: googleDest)
            }
        }
    }
}

extension GoogleDestination {
    func toDestination() -> Destination {
        return Destination(
            id: placeID,
            name: name,
            // Provide a default image URL since Google Places metadata isn't a direct URL
            imageUrl: "",
            // Use nil-coalescing to handle optional rating
            rating: rating ?? 0.0,
            location: location,
            // Provide an empty array for participantAvatars
            participantAvatars: [],
            description: description,
            // Convert optional Int? to Double. Use 0.0 as default if nil.
            price: Double(priceLevel ?? 0),
            // Provide an empty array for galleryImageUrls
            galleryImageUrls: [],
            categories: [], // Google Places API does not provide this
            latitude: latitude,
            longitude: longitude,
            partnerId: nil
        )
    }
}
