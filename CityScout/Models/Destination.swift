import Foundation
import FirebaseFirestore

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
    
    // MARK: - New Property for Booking Confirmation
    // This is the ID of the partner who manages this destination.
    let partnerId: String?

    // MARK: - New Property for Recommendation
    let categories: [String] // e.g., ["Adventure", "Beaches"]
    
    init(id: String? = nil, name: String, imageUrl: String, rating: Double, location: String, participantAvatars: [String]?, description: String?, price: Double, galleryImageUrls: [String]?, categories: [String], latitude: Double? = nil, longitude: Double? = nil, partnerId: String? = nil) {
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
        self.rating = rating
        self.location = location
        self.participantAvatars = participantAvatars
        self.description = description
        self.price = price
        self.galleryImageUrls = galleryImageUrls
        self.latitude = latitude
        self.longitude = longitude
        self.categories = categories
        self.partnerId = partnerId
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
