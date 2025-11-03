//
//  BestDestinationsCarousel.swift
//  CityScout
//
//  Created by Umuco Auca on 21/08/2025.
//

import SwiftUI

struct BestDestinationsCarousel: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var homeVM: HomeViewModel
    @ObservedObject var favoritesVM: FavoritesViewModel
    @Binding var selectedDestination: Destination?
    
    @State private var showPopularPlacesView: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader
            carouselSection
        }
        .navigationDestination(isPresented: $showPopularPlacesView) {
                            PopularPlacesView()
                                .environmentObject(homeVM)
                                .environmentObject(favoritesVM)
                        }
    }
    

    private var sectionHeader: some View {
        HStack {
            Text("Best Destinations")
                .font(.headline).bold()
            Spacer()
            Button("View all") {
                showPopularPlacesView = true
            }
            .font(.subheadline)
            .foregroundColor(Color(hex: "#FF7029"))
        }
        .padding(.horizontal)
    }

    private var carouselSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(homeVM.destinations) { dest in
                    HomeDestinationCard(
                        destination: dest
                    )
                    .onTapGesture {
                        selectedDestination = dest
                        if let userId = authVM.signedInUser?.id {
                            Task {
                                await homeVM.logUserAction(userId: userId, destinationId: dest.id, actionType: "card_click")
                                await homeVM.updateInterestScores(for: userId, categories: dest.categories, with: 1.0)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
