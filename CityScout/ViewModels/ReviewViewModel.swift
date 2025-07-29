//
//  ReviewViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 29/07/2025.
//


// ViewModels/ReviewViewModel.swift
import Foundation
import SwiftUI // For @Published

@MainActor // Ensure updates happen on the main thread
class ReviewViewModel: ObservableObject {
    @Published var reviews: [Review] = [] // Example: An array to hold reviews
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // You might have a struct for your Review data, e.g.:
    struct Review: Identifiable, Codable {
        let id: String
        let destinationName: String
        let rating: Int // 1-5 stars
        let comment: String
        let authorId: String
        let timestamp: Date

        // Example initializer for placeholder data
        init(id: String = UUID().uuidString, destinationName: String, rating: Int, comment: String, authorId: String, timestamp: Date = Date()) {
            self.id = id
            self.destinationName = destinationName
            self.rating = rating
            self.comment = comment
            self.authorId = authorId
            self.timestamp = timestamp
        }
    }

    init() {
        // Load placeholder reviews for demonstration
        loadPlaceholderReviews()
    }

    func loadPlaceholderReviews() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            self.reviews = [
                Review(destinationName: "Volcanoes National Park", rating: 5, comment: "Absolutely breathtaking! The gorilla trekking was an unforgettable experience. Highly recommend!", authorId: "user123"),
                Review(destinationName: "Lake Kivu", rating: 4, comment: "Beautiful lake, great for a relaxing getaway. The boat ride was lovely, but the food options were limited.", authorId: "user123"),
                Review(destinationName: "Kigali Genocide Memorial", rating: 5, comment: "A deeply moving and important place. Essential for understanding Rwanda's history. Very well presented.", authorId: "user123")
            ]
            self.isLoading = false
        }
    }

    // You would add functions here to actually fetch reviews from Firestore,
    // submit new reviews, etc.
    func submitReview(destinationId: String, destinationName: String, rating: Int, comment: String) async -> Bool {
        // Placeholder for actual submission logic
        isLoading = true
        errorMessage = nil
        do {
            // Simulate network call
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            let newReview = Review(destinationName: destinationName, rating: rating, comment: comment, authorId: "currentUser", timestamp: Date())
            reviews.insert(newReview, at: 0) // Add to the top
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to submit review: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
}
