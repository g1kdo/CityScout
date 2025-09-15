//
//  HomeContentView.swift
//  CityScout
//
//  Created by Umuco Auca on 21/08/2025.
//

import SwiftUI

struct HomeContentView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var homeVM: HomeViewModel
    @ObservedObject var favoritesVM: FavoritesViewModel
    @Binding var selectedDestination: Destination?
    @Binding var showPopularPlacesView: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headlineSection
                    .padding(.bottom, 25)

                if homeVM.isLoading {
                    ProgressView("Loading Destinations...")
                        .frame(height: 300)
                } else if let errorMessage = homeVM.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else {
                    BestDestinationsCarousel(
                        homeVM: homeVM,
                        favoritesVM: favoritesVM,
                        selectedDestination: $selectedDestination
                    )
                    .padding(.bottom, 35)
                    .environmentObject(authVM)
                    
                    PersonalizedSectionsView(
                        homeVM: homeVM,
                        favoritesVM: favoritesVM,
                        selectedDestination: $selectedDestination
                    )
                    .environmentObject(authVM)
                    .environmentObject(homeVM)
                }
            }
        }
    }
    
    private var headlineSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Explore the")
                .font(.largeTitle)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("Beautiful ")
                    .font(.largeTitle).bold()
                VStack(alignment: .leading, spacing: 2) {
                    Text("world!")
                        .font(.largeTitle).bold()
                        .foregroundColor(Color(hex: "#FF7029"))
                    Image("Line")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 15)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
    }
}
