//
//  HomeView.swift
//  CityScout
//
//  Created by Umuco Auca on 14/08/2025.
//

import SwiftUI
import FirebaseFirestore

struct HomeView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var homeVM = HomeViewModel()
    @StateObject private var favoritesVM = FavoritesViewModel(homeViewModel: HomeViewModel())
    @StateObject private var reviewVM = ReviewViewModel(homeViewModel: HomeViewModel())

    @State private var navigateToProfile = false
    @State private var selectedTab: FooterTab = .home
    @State private var selectedDestination: Destination?
    @State private var showPopularPlacesView: Bool = false
    @State private var isShowingMessagesView: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Layer 1: The main content and navigation bars
                VStack(spacing: 0) {
                    TopBarView(isShowingMessagesView: $isShowingMessagesView)
                        .environmentObject(authVM)
                        .padding(.bottom, 25)

                    // This is where the content for the selected tab goes.
                    // It is now a direct child of the main VStack.
                    currentTabView

                    Spacer()

                    FooterView(selected: $selectedTab)
                }
                .padding(.top, safeAreaTop())
                .background(Color(.systemBackground)).ignoresSafeArea()

                // Layer 2 (Conditional): The Search View Overlay
                if homeVM.showSearchView {
                    SearchView()
                        .environmentObject(homeVM)
                        .environmentObject(favoritesVM)
                        .transition(.move(edge: .bottom))
                }
            }
            .navigationBarHidden(true)
            .onChange(of: selectedTab) { _, newTab in
                if newTab == .profile {
                    navigateToProfile = true
                } else if newTab == .search {
                    withAnimation {
                        homeVM.showSearchView = true
                    }
                }
            }
            .onChange(of: navigateToProfile) { _, isActive in
                if !isActive { selectedTab = .home }
            }
            .onChange(of: homeVM.showSearchView) { _, isPresented in
                if !isPresented { selectedTab = .home }
            }
            .onChange(of: showPopularPlacesView) { _, isPresented in
                if !isPresented { selectedTab = .home }
            }
            .onChange(of: isShowingMessagesView) { _, isPresented in
                          if !isPresented {
                              selectedTab = .home
                          }
                      }
            .onAppear {
                favoritesVM.subscribeToFavorites(for: authVM.user?.uid)
                if let userId = authVM.signedInUser?.id {
                    Task {
                        await homeVM.fetchPersonalizedDestinations(for: userId)
                    }
                }
            }
            .onChange(of: authVM.user?.uid) { _, newUserId in
                favoritesVM.subscribeToFavorites(for: newUserId)
            }
            .navigationDestination(isPresented: $navigateToProfile) {
                ProfileView(viewModel: ProfileViewModel(reviewViewModel: reviewVM))
                    .environmentObject(authVM)
            }
            .navigationDestination(isPresented: Binding<Bool>(
                get: { selectedDestination != nil },
                set: { if !$0 { selectedDestination = nil } }
            )) {
                if let dest = selectedDestination {
                    DestinationDetailView(destination: dest)
                }
            }
            .navigationDestination(isPresented: $showPopularPlacesView) {
                PopularPlacesView()
                    .environmentObject(homeVM)
                    .environmentObject(favoritesVM)
            }
            .navigationDestination(isPresented: $isShowingMessagesView) {
                           MessagesView()
                               .environmentObject(authVM)
                               .environmentObject(homeVM)
                       }
        }
    }

    @ViewBuilder
    private var currentTabView: some View {
        switch selectedTab {
        case .home:
            HomeContentView(
                homeVM: homeVM,
                favoritesVM: favoritesVM,
                selectedDestination: $selectedDestination,
                showPopularPlacesView: $showPopularPlacesView
            )
        case .calendar:
            ScheduleView()
        case .search:
            Color.clear
        case .review:
            ReviewView()
                .environmentObject(reviewVM)
        case .profile:
            Color.clear
        }
    }

    private func safeAreaTop() -> CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows.first?
            .safeAreaInsets.top ?? 0
    }
}
