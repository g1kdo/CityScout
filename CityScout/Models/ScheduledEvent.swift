

import SwiftUI
import Foundation
import FirebaseFirestore

struct ScheduledEvent: Identifiable, Codable {
    @DocumentID var id: String?
    let date: Date
    let destination: Destination

    // Add a Custom Initializer if needed for decoding from Firestore
    // For direct Firestore document decoding, ensure all properties are Codable.
    // However, if fetching from a 'bookings' collection, you might need to map fields.
}
