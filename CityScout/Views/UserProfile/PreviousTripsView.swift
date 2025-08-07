import SwiftUI
import Kingfisher

struct PreviousTripsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var viewModel = PreviousTripsViewModel()

    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading Trips...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if viewModel.trips.isEmpty {
                    VStack {
                        Image(systemName: "globe.desk")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                        Text("You have no previous trips.")
                            .foregroundColor(.secondary)
                        Text("Trips you've reviewed will appear here.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.trips) { trip in
                                DestinationGridCard(destination: trip)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Previous Trips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchPreviousTrips(for: authVM.user?.uid)
                }
            }
        }
    }
}

// A placeholder for your destination card.
struct DestinationGridCard: View {
    let destination: Destination
    var body: some View {
        // --- FIX IS HERE ---
        // We now correctly use `destination.imageUrl` to match your Destination model.
        KFImage(URL(string: destination.imageUrl))
            .resizable()
            .scaledToFill()
            .aspectRatio(1, contentMode: .fill)
            .frame(minWidth: 0, maxWidth: .infinity)
            .clipped()
            .cornerRadius(12)
            .overlay(
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.6)]), startPoint: .top, endPoint: .bottom)
                        .cornerRadius(12)
                    Text(destination.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(8)
                }
            )
    }
}
