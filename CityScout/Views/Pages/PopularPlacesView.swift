import SwiftUI
import FirebaseFirestore

struct PopularPlacesView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var vm = PopularPlacesViewModel()

    // two columns
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top bar with back button and centered title
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("All Popular Places")
                        .font(.headline)
                    Spacer()
                    // Placeholder for alignment
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding()

                // Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(vm.places) { dest in
                            PopularPlaceCard(destination: dest)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                vm.fetchPlaces()
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class PopularPlacesViewModel: ObservableObject {
    @Published var places: [Destination] = []
    private let db = Firestore.firestore()

    func fetchPlaces() {
        Task {
            do {
                let snapshot = try await db.collection("destinations").getDocuments()
                places = snapshot.documents.compactMap { doc in
                    Destination(documentId: doc.documentID, data: doc.data())
                }
                print("Fetched \(places.count) destinations")
            } catch {
                print("Error fetching destinations: \(error)")
            }
        }
    }
}

// MARK: - Card

struct PopularPlaceCard: View {
    let destination: Destination
    private let cardHeight: CGFloat = 260

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image(destination.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(12)

                Image(systemName: "heart")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
                    .padding(6)
            }

            Text(destination.name)
                .font(.headline)
                .lineLimit(1)

            HStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse")
                Text(destination.location)
            }
            .font(.caption)
            .foregroundColor(.gray)

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text(String(format: "%.1f", destination.rating))
                    .font(.subheadline)
            }

            Text(destination.description)
                .font(.subheadline)
                .foregroundColor(Color(hex: "#FF7029"))
                .lineLimit(1)

            Spacer()
        }
        .padding()
        .frame(height: cardHeight)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

struct PopularPlacesView_Previews: PreviewProvider {
    static var previews: some View {
        PopularPlacesView()
            .preferredColorScheme(.light)
    }
}
