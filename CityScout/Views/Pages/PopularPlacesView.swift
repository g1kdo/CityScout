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
    @EnvironmentObject var favoritesVM: FavoritesViewModel
    @Environment(\.dismiss) var dismiss
    
    // 1. Add the horizontalSizeClass environment variable
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    // 2. Convert 'columns' to a computed property to check the size class
    private var columns: [GridItem] {
        // Use a larger minimum width for iPad (regular) and a smaller one for iPhone (compact)
        let minWidth: CGFloat = (horizontalSizeClass == .regular) ? 240 : 160
        return [
            GridItem(.adaptive(minimum: minWidth))
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(title: "Popular Places")
                // 3. Increased padding for more space
                .padding(.bottom, 30)

            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 20)  {
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
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationBarHidden(true)
    }
}
