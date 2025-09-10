import SwiftUI

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
            // --- FIX IS HERE ---
            // Replaced Color.white with an adaptive system background color.
            // This is the change that will make the view adapt to dark mode.
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
                .foregroundColor(.secondary) // Use adaptive color
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible())], spacing: 20) {
                    ForEach(viewModel.favorites) { destination in
                        NavigationLink(destination: DestinationDetailView(destination: destination)) {
                            PopularFavoriteDestinationCard(
                                destination: destination,
                                isFavorite: viewModel.isFavorite(destination: .local(destination))
                            ) {
                                Task {
                                    await viewModel.toggleFavorite(destination: .local(destination))
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
    }
}
