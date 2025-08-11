import Foundation
import FirebaseFirestore


@MainActor
class PreviousTripsViewModel: ObservableObject {
    @Published var trips: [Destination] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func fetchPreviousTrips(for userId: String?) async {
        guard let userId = userId, !userId.isEmpty else {
            errorMessage = "User not found."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Step 1: Find all reviews written by the current user.
            let reviewsSnapshot = try await db.collection("reviews")
                .whereField("authorId", isEqualTo: userId)
                .getDocuments()

            // Use your existing Review model to decode the documents.
            let userReviews = reviewsSnapshot.documents.compactMap {
                try? $0.data(as: ReviewViewModel.Review.self)
            }
            
            // Step 2: Get the unique destination IDs from these reviews.
            let destinationIds = Array(Set(userReviews.map { $0.destinationId }))
            
            if destinationIds.isEmpty {
                // If the user has no reviews, they have no trips.
                self.trips = []
                self.isLoading = false
                return
            }

            // Step 3: Fetch the full Destination objects for those IDs.
            // Firestore's 'in' query is limited to 30 items. For more, you'd batch requests.
            let destinationSnapshot = try await db.collection("destinations")
                .whereField(FieldPath.documentID(), in: destinationIds)
                .getDocuments()
                
            self.trips = destinationSnapshot.documents.compactMap {
                try? $0.data(as: Destination.self)
            }
            
        } catch {
            self.errorMessage = "Failed to fetch previous trips: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
