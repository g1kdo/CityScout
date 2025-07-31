// ViewModels/ReviewViewModel.swift
import Foundation
import SwiftUI
import FirebaseFirestore

@MainActor
class ReviewViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // New properties for destination search
    @Published var destinationSuggestions: [Destination] = []
    @Published var isSearchingDestinations: Bool = false
    @Published var destinationSearchError: String?

    // Firestore collection references
    private let db = Firestore.firestore()
    private let reviewsCollection = "reviews"
    private let destinationsCollection = "destinations" // Assuming your destinations are in a collection named "destinations"
    
    struct Review: Identifiable, Codable, Equatable {
            @DocumentID var id: String? // Firestore document ID
            let destinationId: String
            let destinationName: String
            let rating: Int
            let comment: String
            let authorId: String
            let authorDisplayName: String // Add display name
            var authorProfilePictureURL: URL? // Add profile picture URL
            var timestamp: Date
            var agrees: Int = 0 // Count of "agree" reactions
            var disagrees: Int = 0 // Count of "disagree" reactions
            var reactedUsers: [String: String] = [:] // Tracks which user reacted
            
            static func == (lhs: Review, rhs: Review) -> Bool {
                lhs.id == rhs.id // Only compare IDs for equality
            }
        }


    func fetchReviews() {
        isLoading = true
        db.collection(reviewsCollection)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.errorMessage = "Error fetching reviews: \(error.localizedDescription)"
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    self.reviews = []
                    return
                }

                self.reviews = documents.compactMap { doc -> Review? in
                    try? doc.data(as: Review.self)
                }
            }
    }

    // Function to add a new review to Firestore (modify to accept destinationId from selected suggestion)
    func addReview(destinationId: String, destinationName: String, rating: Int, comment: String, authorId: String, authorDisplayName: String, authorProfilePictureURL: URL?) async -> Bool {
        isLoading = true
        errorMessage = nil

        let newReview = Review(
            destinationId: destinationId, // Use the provided destinationId
            destinationName: destinationName,
            rating: rating,
            comment: comment,
            authorId: authorId,
            authorDisplayName: authorDisplayName,
            authorProfilePictureURL: authorProfilePictureURL,
            timestamp: Date()
        )

        do {
            _ = try db.collection(reviewsCollection).addDocument(from: newReview)
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to submit review: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // Function to delete a review (keep as is)
    func deleteReview(review: Review) async {
        guard let reviewId = review.id else { return }
        do {
            try await db.collection(reviewsCollection).document(reviewId).delete()
        } catch {
            print("Error deleting review: \(error.localizedDescription)")
            errorMessage = "Failed to delete review."
        }
    }
    
    // Function to edit a review (keep as is)
    func editReview(review: Review, newComment: String, newRating: Int) async -> Bool {
        guard let reviewId = review.id else { return false }
        do {
            let data: [String: Any] = [
                "comment": newComment,
                "rating": newRating,
                "timestamp": Timestamp(date: Date()) // Update timestamp on edit
            ]
            try await db.collection(reviewsCollection).document(reviewId).updateData(data)
            return true
        } catch {
            print("Error editing review: \(error.localizedDescription)")
            errorMessage = "Failed to edit review."
            return false
        }
    }
    
    // Function to add a reaction (agree/disagree) (keep as is)
    func reactToReview(review: Review, userId: String, reaction: String) async {
        guard let reviewId = review.id else { return }
        let docRef = db.collection(reviewsCollection).document(reviewId)

        do {
            try await db.runTransaction({ (transaction, errorPointer) -> Any? in
                let document: DocumentSnapshot
                do {
                    document = try transaction.getDocument(docRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }

                guard let oldReview = try? document.data(as: Review.self) else {
                    let error = NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve review data from snapshot."])
                    errorPointer?.pointee = error
                    return nil
                }
                
                var newAgrees = oldReview.agrees
                var newDisagrees = oldReview.disagrees
                var newReactedUsers = oldReview.reactedUsers

                let oldReaction = newReactedUsers[userId]

                if oldReaction == reaction {
                    // User is toggling off their reaction
                    if reaction == "agree" {
                        newAgrees -= 1
                    } else if reaction == "disagree" {
                        newDisagrees -= 1
                    }
                    newReactedUsers.removeValue(forKey: userId)
                } else {
                    // User is adding a new reaction or changing it
                    if oldReaction == "agree" {
                        newAgrees -= 1
                    } else if oldReaction == "disagree" {
                        newDisagrees -= 1
                    }
                    
                    if reaction == "agree" {
                        newAgrees += 1
                    } else if reaction == "disagree" {
                        newDisagrees += 1
                    }
                    newReactedUsers[userId] = reaction
                }
                
                transaction.updateData(["agrees": newAgrees, "disagrees": newDisagrees, "reactedUsers": newReactedUsers], forDocument: docRef)
                return nil
            })
        } catch {
            print("Transaction failed: \(error)")
        }
    }

    // New function to fetch destination suggestions
    func fetchDestinationSuggestions(query: String) {
        if query.isEmpty {
            destinationSuggestions = []
            isSearchingDestinations = false
            return
        }

        isSearchingDestinations = true
        destinationSearchError = nil

        let lowercasedQuery = query.lowercased()

        // Fetch all destinations and filter client-side for "contains" search
        // Firestore doesn't directly support "contains" for arbitrary strings efficiently.
        // For production, if you have thousands of destinations, consider:
        // 1. Algolia/Elasticsearch for rich text search.
        // 2. Maintaining a searchable denormalized field (e.g., lowercase, remove spaces)
        // 3. Using a "starts-with" query if that fits your needs:
        //    .whereField("name", isGreaterThanOrEqualTo: lowercasedQuery)
        //    .whereField("name", isLessThanOrEqualTo: lowercasedQuery + "~") // '~' is a character after all other characters

        db.collection(destinationsCollection)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isSearchingDestinations = false

                if let error = error {
                    self.destinationSearchError = "Error fetching destinations: \(error.localizedDescription)"
                    self.destinationSuggestions = []
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.destinationSuggestions = []
                    return
                }

                let allDestinations = documents.compactMap { doc -> Destination? in
                    try? doc.data(as: Destination.self)
                }

                // Filter destinations whose name contains the query (case-insensitive)
                self.destinationSuggestions = allDestinations.filter {
                    $0.name.lowercased().contains(lowercasedQuery)
                }
            }
    }

    // New function to update a user's profile picture across all their reviews
    func updateReviewsProfilePicture(userId: String, newPictureURL: URL?) async {
        isLoading = true
        errorMessage = nil
        do {
            let querySnapshot = try await db.collection(reviewsCollection)
                .whereField("authorId", isEqualTo: userId)
                .getDocuments()

            for document in querySnapshot.documents {
                let docRef = db.collection(reviewsCollection).document(document.documentID)
                try await docRef.updateData(["authorProfilePictureURL": newPictureURL?.absoluteString as Any])
            }
            isLoading = false
            print("Successfully updated profile pictures for reviews by user: \(userId)")
        } catch {
            errorMessage = "Failed to update profile pictures for reviews: \(error.localizedDescription)"
            isLoading = false
            print("Error updating profile pictures for reviews: \(error.localizedDescription)")
        }
    }
}
