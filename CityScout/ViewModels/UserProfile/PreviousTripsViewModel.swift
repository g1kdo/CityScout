import Foundation
import FirebaseFirestore


@MainActor
class PreviousTripsViewModel: ObservableObject {
    @Published var trips: [Destination] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    // --- NEW HELPER STRUCT ---
    // This private struct lives only inside this ViewModel. It's used to decode
    // the booking documents from Firestore without needing a new, separate file.
    private struct Booking: Codable {
        let destinationId: String
        let date: Timestamp
        let userId: String
    }

    func fetchPreviousTrips(for userId: String?) async {
        guard let userId = userId, !userId.isEmpty else {
            errorMessage = "User not found."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // --- Step 1: Fetch destination IDs from past bookings ---
            let bookingsSnapshot = try await db.collection("bookings")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isLessThan: Date())
                .getDocuments()

            let bookedDestinationIds = bookingsSnapshot.documents.compactMap {
                // Use the new private Booking struct to decode the data
                try? $0.data(as: Booking.self).destinationId
            }

            // --- Step 2: Fetch destination IDs from reviews ---
            let reviewsSnapshot = try await db.collection("reviews")
                .whereField("authorId", isEqualTo: userId)
                .getDocuments()

            let reviewedDestinationIds = reviewsSnapshot.documents.compactMap {
                try? $0.data(as: ReviewViewModel.Review.self).destinationId
            }
            
            // --- Step 3: Combine and deduplicate the IDs ---
            let allTripIds = Array(Set(bookedDestinationIds + reviewedDestinationIds))
            
            if allTripIds.isEmpty {
                self.trips = []
                self.isLoading = false
                return
            }

            // --- Step 4: Fetch the full Destination objects for those IDs ---
            let destinationSnapshot = try await db.collection("destinations")
                .whereField(FieldPath.documentID(), in: allTripIds)
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
