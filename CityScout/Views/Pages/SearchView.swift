import SwiftUI

struct SearchView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var favoritesVM: FavoritesViewModel
    
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
                            NavigationLink(destination: DestinationDetailView(destination: destination)) {
                                PopularFavoriteDestinationCard(
                                    destination: destination,
                                    isFavorite: favoritesVM.isFavorite(destination: anyDestination)
                                ) {
                                    Task {
                                        await favoritesVM.toggleFavorite(destination: anyDestination)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        
                        case .google(let googleDestination):
                            // Change the NavigationLink to a simple Button
                            Button(action: {
                                Task {
                                    // Set isLoading to true to show the progress view
                                    await MainActor.run {
                                        homeVM.isLoading = true
                                        homeVM.searchResults = [] // Clear results to only show progress
                                    }
                                    
                                    // Fetch the full details
                                    if let fullDetails = await homeVM.fetchPlaceDetails(for: googleDestination.placeID) {
                                        // Set the state variables to trigger the programmatic navigation
                                        await MainActor.run {
                                            self.selectedGoogleDestination = fullDetails
                                            self.isShowingGoogleDetails = true
                                        }
                                    }
                                    
                                    // Reset isLoading after the task completes
                                    await MainActor.run {
                                        homeVM.isLoading = false
                                    }
                                }
                            }) {
                                GoogleDestinationCard(googleDestination: googleDestination)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
}
