import SwiftUI

struct PopularPlacesView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var favoritesVM: FavoritesViewModel
    @Environment(\.dismiss) var dismiss
    
    // 1. ADD environment variable
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // 2. Make columns adaptive
    private var columns: [GridItem] {
        let minWidth: CGFloat = (horizontalSizeClass == .regular) ? 260 : 160
        // Add grid spacing here instead of on the grid itself
        return [GridItem(.adaptive(minimum: minWidth), spacing: 20)]
    }

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(title: "Popular Places")
                .padding(.bottom, 20)
                .padding(.top, 10)

            // 3. REMOVED GeometryReader, VStack, and Spacer
            // The ScrollView will now correctly fill the remaining space.
            ScrollView(.vertical, showsIndicators: false) {
                
                // 4. Place LazyVGrid directly inside the ScrollView
                LazyVGrid(columns: columns, spacing: 20) { // Add vertical spacing for rows
                    ForEach(homeVM.destinations) { destination in
                        NavigationLink(destination: DestinationDetailView(destination: destination)) {
                            PopularFavoriteDestinationCard(
                                destination: destination,
                                isFavorite: favoritesVM.isFavorite(destination: .local(destination))
                            ) {
                                Task {
                                    await favoritesVM.toggleFavorite(destination: .local(destination))
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal) // Padding for the grid's left/right edges
                .padding(.bottom, 20) // Padding at the end of all content
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationBarHidden(true)
    }
}
