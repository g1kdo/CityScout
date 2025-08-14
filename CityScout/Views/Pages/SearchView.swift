import SwiftUI

struct SearchView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var favoritesVM: FavoritesViewModel
    // The dismiss environment variable is no longer needed

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 20) {
                // --- CHANGE IS HERE ---
                // The header's action now directly modifies the shared ViewModel's state.
                SearchHeaderView(title: "Search") {
                    homeVM.searchText = ""
                    withAnimation {
                        homeVM.showSearchView = false
                    }
                }
                .padding(.top, 10)

                SearchBarView(searchText: $homeVM.searchText) {
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
                    ForEach(homeVM.searchResults) { destination in
                        NavigationLink(destination: DestinationDetailView(destination: destination)) {
                            PopularFavoriteDestinationCard(
                                destination: destination,
                                isFavorite: favoritesVM.isFavorite(destination: destination)
                            ) {
                                Task {
                                    await favoritesVM.toggleFavorite(destination: destination)
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
    }
}
