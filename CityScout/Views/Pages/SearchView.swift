import SwiftUI

struct SearchView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var favoritesVM: FavoritesViewModel

    // 1. ADD environment variable for screen size
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    // State to hold the fully-loaded GoogleDestination
    @State private var selectedGoogleDestination: GoogleDestination? = nil

    // Programmatic navigation link
    @State private var isShowingGoogleDetails = false
    
    // 2. Make columns adaptive and use private computed property
    private var columns: [GridItem] {
        let minWidth: CGFloat = (horizontalSizeClass == .regular) ? 260 : 160
        // Define adaptive column layout, setting horizontal spacing here
        return [GridItem(.adaptive(minimum: minWidth), spacing: 20)]
    }

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

                SearchBarView(searchText: $homeVM.searchText, isMicrophoneActive: homeVM.isListeningToSpeech) {
                    // Action on search tapped
                } onMicrophoneTapped: {
                    // Call the new function on your HomeViewModel
                    homeVM.handleMicrophoneTapped()
                }

                searchContent
            }
        }
        .navigationBarHidden(true)
        .onDisappear {
            homeVM.searchText = ""
        }
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
                // Using the adaptive 'columns' property
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(homeVM.searchResults, id: \.id) { anyDestination in
                        switch anyDestination {
                        case .local(let destination):
                            // ✅ Corrected: Wrap the card directly in a NavigationLink
                            // This works because the card's favorite button is not inside a NavigationLink
                            NavigationLink {
                                DestinationDetailView(destination: destination)
                            } label: {
                                PopularFavoriteDestinationCard(
                                    destination: destination,
                                    isFavorite: favoritesVM.isFavorite(destination: anyDestination),
                                    onFavoriteTapped: {
                                        Task {
                                            await favoritesVM.toggleFavorite(destination: anyDestination)
                                        }
                                    }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                        case .google(let googleDestination, let sessionToken):
                            // ✅ Corrected: The card itself is a Button that triggers programmatic navigation
                            // This ensures the favorite toggle button is the only other tappable element
                            GoogleDestinationCard(
                                googleDestination: googleDestination,
//                                onFavoriteTapped: {
//                                    Task {
//                                        await favoritesVM.toggleFavorite(destination: anyDestination)
//                                    }
//                                },
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
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
}
