import SwiftUI

struct FavoritePlacesView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel

    // 1. ADD environment variable for screen size
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @StateObject private var viewModel = FavoritesViewModel(homeViewModel: HomeViewModel())
    
    // 2. Make columns adaptive and use private computed property
    private var columns: [GridItem] {
        let minWidth: CGFloat = (horizontalSizeClass == .regular) ? 260 : 160
        // Define adaptive column layout, setting horizontal spacing here
        return [GridItem(.adaptive(minimum: minWidth), spacing: 20)]
    }

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
            .background(Color(.systemBackground).ignoresSafeArea())
        }
        .padding(.top, 10)
        .padding(.bottom, 20)
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
            // 3. Place LazyVGrid directly inside the ScrollView using adaptive columns
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 20) { // Add vertical spacing for rows
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
                .padding(.horizontal) // Apply horizontal padding to the grid
                .padding(.bottom, 20) // Padding at the end of all content
            }
        }
    }
}
