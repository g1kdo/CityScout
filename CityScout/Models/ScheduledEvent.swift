import SwiftUI
import Foundation
import FirebaseFirestore

struct ScheduledEvent: Identifiable, Codable {
    @DocumentID var id: String?
    let startDate: Date
    let endDate: Date
    let destination: Destination
    
    // This makes the number of people available for cancellation calculations.
    let numberOfPeople: Int
   
        let calendarEventID: String?
}
