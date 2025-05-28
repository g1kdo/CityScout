import SwiftUI

struct SearchView: View {
    @EnvironmentObject var homeVM: HomeViewModel
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
            } else if let errorMessage = homeVM.errorMessage { // Correct
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else if homeVM.searchText.isEmpty && homeVM.searchResults.isEmpty {
                // This condition might need adjustment if you always want to show something when searchResults is empty,
                // even if searchText is also empty (e.g., initial state or no results loaded yet).
                Spacer()
                Text("Start typing to find places...")
                    .foregroundColor(.gray)
                Spacer()
            } else if homeVM.searchResults.isEmpty {
                Spacer()
                Text("No results found for \"\(homeVM.searchText)\"")
                    .foregroundColor(.gray)
                Spacer()
            } else {
                // Section for "Search Places" or similar
//                Text("Search Places")
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(.horizontal)
//                    .padding(.top, 10)

                // Grid of search results
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(homeVM.searchResults) { destination in
                            NavigationLink(destination: DestinationDetailView(destination: destination)) {
                                DestinationSearchCard(destination: destination)
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
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            // homeVM.isSearching = true // If 'isSearching' isn't needed or is managed differently, remove it
            // Ensure search results are loaded or updated on appear if necessary
            // For now, loadDestinations in HomeView handles initial population
            // You might want to call homeVM.filterDestinations(for: homeVM.searchText) here
            // if you want to re-run the filter when the search view appears again with existing text.
        }
        .onDisappear {
            homeVM.searchText = ""
        }
    }
}

#Preview {
    let vm = HomeViewModel()
    Task { await vm.loadDestinations() }
    return SearchView()
        .environmentObject(vm)
}
