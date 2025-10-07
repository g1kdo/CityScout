//
//  HomeContentView.swift
//  CityScout
//
//  Created by Umuco Auca on 21/08/2025.
//

import SwiftUI

struct HomeContentView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var vm: HomeViewModel
    @ObservedObject var favoritesVM: FavoritesViewModel
    @Binding var selectedDestination: Destination?
    @Binding var showPopularPlacesView: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headlineSection
                    .padding(.bottom, 25)

                if vm.isLoading {
                    ProgressView("Loading Destinations...")
                        .frame(height: 300)
                } else if let errorMessage = vm.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else {
                    BestDestinationsCarousel(
                        vm: vm,
                        favoritesVM: favoritesVM,
                        selectedDestination: $selectedDestination
                    )
                    .padding(.bottom, 35)
                    .environmentObject(authVM) // Pass the environment object down
                    
                    PersonalizedSectionsView(
                        vm: vm,
                        favoritesVM: favoritesVM,
                        selectedDestination: $selectedDestination
                    )
                    .environmentObject(authVM) // Pass the environment object down
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
