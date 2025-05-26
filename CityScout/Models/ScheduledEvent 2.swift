import Foundation

struct ScheduledEvent: Identifiable {
    let id = UUID()
    let date: Date
    let destination: Destination // This will now use your updated Destination model
}