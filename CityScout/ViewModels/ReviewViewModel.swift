import Foundation
import SwiftUI
import FirebaseFirestore

@MainActor
class ReviewViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    @Published var destinationSuggestions: [Destination] = []
    @Published var isSearchingDestinations: Bool = false
    @Published var destinationSearchError: String?

    private let db = Firestore.firestore()
    private let reviewsCollection = "reviews"
    private let destinationsCollection = "destinations"
    private let usersCollection = "users"
    
    @Published var isPerformingInitialFetch = true
    
    // New property to hold a reference to HomeViewModel
    private let homeViewModel: HomeViewModel
    
    struct Review: Identifiable, Codable, Equatable {
        @DocumentID var id: String?
        let destinationId: String
        let destinationName: String
        let rating: Int
        let comment: String
        let authorId: String
        let authorDisplayName: String
        var authorProfilePictureURL: URL?
        var timestamp: Date
        var agrees: Int = 0
        var disagrees: Int = 0
        var reactedUsers: [String: String] = [:]
            
        static func == (lhs: Review, rhs: Review) -> Bool {
            lhs.id == rhs.id
        }
    }

    struct Destination: Identifiable, Codable, Equatable, Hashable {
        @DocumentID var id: String?
        let name: String
        let imageUrl: String
        let rating: Double
        let location: String
        let participantAvatars: [String]?
        let description: String?
        let price: Double
        let galleryImageUrls: [String]?
        let latitude: Double?
        let longitude: Double?
        
        let partnerId: String?
        let categories: [String]
    }

    // Update init to accept HomeViewModel
    init(homeViewModel: HomeViewModel) {
        self.homeViewModel = homeViewModel
        fetchReviews()
    }
    
    func fetchDestinationSuggestions(query: String) {
        self.destinationSuggestions = []
        self.destinationSearchError = nil
        self.isSearchingDestinations = true
        
        guard !query.isEmpty else {
            self.isSearchingDestinations = false
            return
        }

        let capitalizedQuery = query.capitalized
        
        db.collection(destinationsCollection)
            .whereField("name", isGreaterThanOrEqualTo: capitalizedQuery)
            .whereField("name", isLessThanOrEqualTo: capitalizedQuery + "\u{f8ff}")
            .limit(to: 5)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isSearchingDestinations = false
                
                if let error = error {
                    self.destinationSearchError = "Error searching destinations: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.destinationSuggestions = []
                    return
                }
                
                self.destinationSuggestions = documents.compactMap { doc -> Destination? in
                    try? doc.data(as: Destination.self)
                }
            }
    }

    func fetchReviews() {
        db.collection(reviewsCollection)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                defer { self.isPerformingInitialFetch = false }

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
            _ = try await db.collection(reviewsCollection).addDocument(from: newReview)
            
            await updateDestinationRatingAndAvatars(for: destinationId)

            let notificationData: [String: Any] = [
                "title": "Review Submitted",
                "message": "Your review for \(destinationName) was submitted successfully!",
                "timestamp": FieldValue.serverTimestamp(),
                "isRead": false,
                "isArchived": false,
                "destinationId": destinationId
            ]
            let notificationRef = db.collection(usersCollection).document(authorId).collection("notifications")
            _ = try await notificationRef.addDocument(data: notificationData)
            print("Confirmation notification created for user \(authorId)")

            Task {
                if let destination = try? await db.collection("destinations").document(destinationId).getDocument(as: Destination.self) {
                    var weight: Double = 0.0
                    if rating >= 3 {
                        weight = 5.0
                    } else if rating <= 2 {
                        weight = -3.0
                    }
                    
                    if weight != 0.0 {
                        await homeViewModel.updateInterestScores(for: authorId, categories: destination.categories, with: weight)
                    }
                    
                    await homeViewModel.logUserAction(userId: authorId, destinationId: destinationId, actionType: "review", metadata: ["rating": rating])
                }
            }
            
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to submit review or create notification: \(error.localizedDescription)"
            isLoading = false
            print("Error: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - New Function to react to a review
    func reactToReview(review: Review, userId: String, reaction: String) async {
        guard let reviewId = review.id else { return }
        
        let reviewRef = db.collection(reviewsCollection).document(reviewId)
        
        do {
            // Use a transaction to safely update the counts
            try await db.runTransaction { (transaction, errorPointer) -> Any? in
                let reviewDoc: DocumentSnapshot
                do {
                    reviewDoc = try transaction.getDocument(reviewRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                
                guard let reviewData = reviewDoc.data(),
                      var currentAgrees = reviewData["agrees"] as? Int,
                      var currentDisagrees = reviewData["disagrees"] as? Int,
                      var reactedUsers = reviewData["reactedUsers"] as? [String: String] else {
                    return nil
                }
                
                let existingReaction = reactedUsers[userId]
                
                // Logic to update counts based on new and existing reactions
                if existingReaction == reaction {
                    // User is un-reacting
                    if reaction == "agree" {
                        currentAgrees -= 1
                    } else {
                        currentDisagrees -= 1
                    }
                    reactedUsers.removeValue(forKey: userId)
                } else {
                    // User is changing reaction or adding a new one
                    if existingReaction == "agree" {
                        currentAgrees -= 1
                    } else if existingReaction == "disagree" {
                        currentDisagrees -= 1
                    }
                    if reaction == "agree" {
                        currentAgrees += 1
                    } else {
                        currentDisagrees += 1
                    }
                    reactedUsers[userId] = reaction
                }
                
                // Update the document in the transaction
                transaction.updateData([
                    "agrees": currentAgrees,
                    "disagrees": currentDisagrees,
                    "reactedUsers": reactedUsers
                ], forDocument: reviewRef)
                
                return nil
            }
        } catch {
            print("Error reacting to review: \(error.localizedDescription)")
            self.errorMessage = "Failed to update review reaction."
        }
    }

    func deleteReview(review: Review) async {
        guard let reviewId = review.id else { return }
        do {
            try await db.collection(reviewsCollection).document(reviewId).delete()
            await updateDestinationRatingAndAvatars(for: review.destinationId)
        } catch {
            print("Error deleting review: \(error.localizedDescription)")
            errorMessage = "Failed to delete review."
        }
    }
    
    func editReview(review: Review, newComment: String, newRating: Int) async -> Bool {
        guard let reviewId = review.id else { return false }
        do {
            let data: [String: Any] = [
                "comment": newComment,
                "rating": newRating,
                "timestamp": Timestamp(date: Date())
            ]
            try await db.collection(reviewsCollection).document(reviewId).updateData(data)
            await updateDestinationRatingAndAvatars(for: review.destinationId)
            return true
        } catch {
            print("Error editing review: \(error.localizedDescription)")
            errorMessage = "Failed to edit review."
            return false
        }
    }
    
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
    
    func updateDestinationRatingAndAvatars(for destinationId: String) async {
        do {
            let reviewsSnapshot = try await db.collection(reviewsCollection)
                .whereField("destinationId", isEqualTo: destinationId)
                .getDocuments()

            let reviews = reviewsSnapshot.documents.compactMap { try? $0.data(as: Review.self) }
            
            let totalRating = reviews.reduce(0.0) { $0 + Double($1.rating) }
            let reviewCount = Double(reviews.count)
            let averageRating = reviewCount > 0 ? totalRating / reviewCount : 0.0

            var uniqueAvatars = Set<String>()
            for review in reviews {
                if let url = review.authorProfilePictureURL?.absoluteString {
                    uniqueAvatars.insert(url)
                }
            }
            let participantAvatars = Array(uniqueAvatars)

            let destinationRef = db.collection(destinationsCollection).document(destinationId)
            try await db.runTransaction { (transaction, errorPointer) -> Any? in
                let destinationDoc: DocumentSnapshot
                do {
                    destinationDoc = try transaction.getDocument(destinationRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }

                guard destinationDoc.exists else {
                    let error = NSError(domain: "AppError", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "Destination document does not exist."
                    ])
                    errorPointer?.pointee = error
                    return nil
                }
                
                transaction.updateData([
                    "rating": averageRating,
                    "participantAvatars": participantAvatars
                ], forDocument: destinationRef)
                
                return nil
            }
            
        } catch {
            print("Error updating destination rating and avatars: \(error.localizedDescription)")
        }
    }
    
    enum SortOption: String, CaseIterable {
        case newest = "Newest"
        case highestRating = "Highest Rating"
        case lowestRating = "Lowest Rating"
    }

    @Published var sortOption: SortOption = .newest

    var sortedReviews: [Review] {
        switch sortOption {
        case .newest:
            return reviews.sorted { $0.timestamp > $1.timestamp }
        case .highestRating:
            return reviews.sorted { $0.rating > $1.rating }
        case .lowestRating:
            return reviews.sorted { $0.rating < $1.rating }
        }
    }
}
