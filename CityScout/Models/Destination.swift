// Models/Destination.swift
import Foundation
import FirebaseFirestore

struct Destination: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    let name: String
    let imageUrl: String // Changed from imageName
    let rating: Double
    let location: String
    let participantAvatars: [String]? // Changed to optional, assuming these are URLs
    let description: String? // Changed to optional
    let price: Double
    let galleryImageUrls: [String]?
    
    // Codable automatically handles the DocumentID and JSON decoding
    // The custom initializers are no longer necessary
    
    // A simple initializer for creating new instances if needed
    init(id: String? = nil, name: String, imageUrl: String, rating: Double, location: String, participantAvatars: [String]?, description: String?, price: Double, galleryImageUrls: [String]?) {
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
        self.rating = rating
        self.location = location
        self.participantAvatars = participantAvatars
        self.description = description
        self.price = price
        self.galleryImageUrls = galleryImageUrls
    }
    
    func hash(into hasher: inout Hasher) {
           hasher.combine(id)
       }
}

