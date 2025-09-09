import SwiftUI

struct SearchView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var favoritesVM: FavoritesViewModel
    @EnvironmentObject var authVM: AuthenticationViewModel
    
    // State to hold the fully-loaded GoogleDestination
    @State private var selectedGoogleDestination: GoogleDestination? = nil
    
    // Programmatic navigation link
    @State private var isShowingGoogleDetails = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 20) {
                SearchHeaderView(title: "Search") {
                    homeVM.searchText = ""
                    withAnimation {
                        homeVM.showSearchView = false
                    }
                }
                .padding(.top, 10)
                
                SearchBarView(searchText: $homeVM.searchText) {
                    // Action on search tapped
                } onMicrophoneTapped: {
                    print("Microphone tapped!")
                }
                
                searchContent
            }
        }
        .navigationBarHidden(true)
        .onDisappear {
            homeVM.searchText = ""
        }
        // This is the new programmatic navigation link
        .navigationDestination(isPresented: $isShowingGoogleDetails) {
            if let destination = selectedGoogleDestination {
                GoogleDestinationDetailView(googleDestination: destination)
            }
        }
    }
    
    @ViewBuilder
    private var searchContent: some View {
        if homeVM.isLoading {
            Spacer()
            ProgressView("Searching...")
            Spacer()
        } else if let errorMessage = homeVM.errorMessage {
            Spacer()
            Text(errorMessage)
                .foregroundColor(.red)
                .padding()
            Spacer()
        } else if homeVM.searchText.isEmpty && homeVM.searchResults.isEmpty {
            Spacer()
            Text("Start typing to find places...")
                .foregroundColor(.secondary)
            Spacer()
        } else if homeVM.searchResults.isEmpty {
            Spacer()
            Text("No results found for \"\(homeVM.searchText)\"")
                .foregroundColor(.secondary)
            Spacer()
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible())], spacing: 20) {
                    ForEach(homeVM.searchResults, id: \.id) { anyDestination in
                        switch anyDestination {
                        case .local(let destination):
                            AnyView(
                                NavigationLink {
                                    // Your DestinationDetailView expects a Destination, which is fine here
                                    DestinationDetailView(destination: destination)
                                } label: {
                                    PopularFavoriteDestinationCard(
                                        // Fix 1: Pass the destination as AnyDestination.local
                                        destination: AnyDestination.local(destination),
                                        // Pass the AnyDestination enum case to isFavorite
                                        isFavorite: favoritesVM.isFavorite(destination: AnyDestination.local(destination)),
                                        onFavoriteTapped: {
                                            Task {
                                                // Fix 2: Add the userId from authVM to the toggleFavorite call
                                                if let userId = authVM.signedInUser?.id {
                                                    await favoritesVM.toggleFavorite(destination: AnyDestination.local(destination), for: userId)
                                                }
                                            }
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            )
                        case .google(let googleDestination, let sessionToken):
                            AnyView(
                                // ✅ Corrected: The card itself is a Button that triggers programmatic navigation
                                // This ensures the favorite toggle button is the only other tappable element
                                GoogleDestinationCard(
                                    googleDestination: googleDestination,
                                    onFavoriteTapped: {
                                        Task {
                                            // Fix 2: Add the userId from authVM to the toggleFavorite call
                                            if let userId = authVM.signedInUser?.id {
                                                await favoritesVM.toggleFavorite(destination: anyDestination, for: userId)
                                            }
                                        }
                                    },
                                    onCardTapped: {
                                        guard let sessionToken = sessionToken else { return }

                                        Task {
                                            await MainActor.run {
                                                homeVM.isLoading = true
                                            }

                                            if let fullDetails = await homeVM.fetchPlaceDetails(for: googleDestination.placeID, with: sessionToken) {
                                                await MainActor.run {
                                                    self.selectedGoogleDestination = fullDetails
                                                    self.isShowingGoogleDetails = true
                                                    homeVM.searchText = ""
                                                    homeVM.searchResults = []
                                                }
                                            }
                                            await MainActor.run {
                                                homeVM.isLoading = false
                                            }
                                        }
                                    }
                                )
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
}
