import SwiftUI

struct SearchView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var favoritesVM: FavoritesViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            SearchHeaderView(title: "Search") {
                homeVM.searchText = ""
                dismiss()
            }
            .padding(.top, 10)

            SearchBarView(searchText: $homeVM.searchText) {
            } onMicrophoneTapped: {
                print("Microphone tapped!")
            }

            if homeVM.isLoading {
                ProgressView("Searching...")
            } else if let errorMessage = homeVM.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else if homeVM.searchText.isEmpty && homeVM.searchResults.isEmpty {
                Spacer()
                Text("Start typing to find places...")
                    // --- CHANGE IS HERE ---
                    .foregroundColor(.secondary) // Replaced .gray
                Spacer()
            } else if homeVM.searchResults.isEmpty {
                Spacer()
                Text("No results found for \"\(homeVM.searchText)\"")
                    // --- CHANGE IS HERE ---
                    .foregroundColor(.secondary) // Replaced .gray
                Spacer()
            } else {
                // Grid of search results
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(homeVM.searchResults) { destination in
                            NavigationLink(destination: DestinationDetailView(destination: destination)) {
                                DestinationSearchCard(
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

            Spacer()
        }
        // --- CHANGE IS HERE ---
        // Replaced Color.white with an adaptive system background
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .onDisappear {
            homeVM.searchText = ""
        }
    }
}
