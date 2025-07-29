//
//  Review.swift
//  CityScout
//
//  Created by Umuco Auca on 29/07/2025.
//

import Foundation

struct Review: Identifiable, Codable {
    let id: String
    let destinationName: String
    var rating: Int // 1-5 stars
    var comment: String // Made mutable for editing
    let authorId: String
    let authorName: String // Author's display name
    let timestamp: Date

    // Initializer for creating new Review instances.
    // Provides default values for `id` and `timestamp`.
    init(id: String = UUID().uuidString, destinationName: String, rating: Int, comment: String, authorId: String, authorName: String, timestamp: Date = Date()) {
        self.id = id
        self.destinationName = destinationName
        self.rating = rating
        self.comment = comment
        self.authorId = authorId
        self.authorName = authorName
        self.timestamp = timestamp
    }
}
