// ViewModels/ReviewViewModel.swift
import Foundation
import SwiftUI
import FirebaseFirestore

@MainActor
class ReviewViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Firestore collection reference
    private let db = Firestore.firestore()
    private let reviewsCollection = "reviews"

    // New struct for the Review data model
    // Conforms to Codable for easy Firestore interaction
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

    // Function to fetch reviews from Firestore
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

                // Convert Firestore documents to Review objects
                self.reviews = documents.compactMap { doc -> Review? in
                    try? doc.data(as: Review.self)
                }
            }
    }

    // Function to add a new review to Firestore
    func addReview(destinationId: String, destinationName: String, rating: Int, comment: String, authorId: String, authorDisplayName: String, authorProfilePictureURL: URL?) async -> Bool {
        isLoading = true
        errorMessage = nil

        let newReview = Review(
            destinationId: destinationId,
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

    // Function to delete a review
    func deleteReview(review: Review) async {
        guard let reviewId = review.id else { return }
        do {
            try await db.collection(reviewsCollection).document(reviewId).delete()
        } catch {
            print("Error deleting review: \(error.localizedDescription)")
            errorMessage = "Failed to delete review."
        }
    }
    
    // Function to edit a review
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
    
    // Function to add a reaction (agree/disagree)
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
}
