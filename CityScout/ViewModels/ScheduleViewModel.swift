import Foundation
import FirebaseFirestore
import Combine

@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var scheduledEvents: [ScheduledEvent] = []
    @Published var pastEvents: [ScheduledEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?
    private var db = Firestore.firestore()
    
    // The ViewModel now owns the CalendarSyncManager
    let calendarSyncManager = CalendarSyncManager()

    // The internal data structure now includes the optional calendarEventID
    private struct BookingData: Codable {
        @DocumentID var id: String?
        var userId: String
        var destinationId: String
        var destinationName: String
        var destinationLocation: String
        var destinationImageUrl: String
        var startDate: Timestamp
        var endDate: Timestamp
        var numberOfPeople: Int
        var price: Double?
        var calendarEventID: String? // New property
    }

    func subscribeToSchedule(for userId: String?) {
        listener?.remove()
        self.listener = nil

        guard let userId = userId else {
            self.scheduledEvents = []
            self.pastEvents = []
            return
        }

        isLoading = true
        errorMessage = nil

        listener = db.collection("bookings")
            .whereField("userId", isEqualTo: userId)
            .order(by: "endDate", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.errorMessage = "Error fetching schedule: \(error.localizedDescription)"
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    self.scheduledEvents = []
                    self.pastEvents = []
                    return
                }
                
                let allEvents = documents.compactMap { doc -> ScheduledEvent? in
                    guard let booking = try? doc.data(as: BookingData.self) else { return nil }
                    let destination = Destination(
                        id: booking.destinationId, name: booking.destinationName, imageUrl: booking.destinationImageUrl,
                        rating: 0.0, location: booking.destinationLocation, participantAvatars: nil,
                        description: nil, price: booking.price ?? 0.0, galleryImageUrls: [], categories: []
                    )
                    // Map the new property from the booking data to the event model
                    return ScheduledEvent(
                        id: booking.id, startDate: booking.startDate.dateValue(), endDate: booking.endDate.dateValue(),
                        destination: destination, numberOfPeople: booking.numberOfPeople,
                        calendarEventID: booking.calendarEventID
                    )
                }
                
                let now = Date()
                self.scheduledEvents = allEvents.filter { $0.endDate >= now }.sorted(by: { $0.startDate < $1.startDate })
                self.pastEvents = allEvents.filter { $0.endDate < now }
            }
    }
    
    // New function to coordinate adding to calendar and saving the ID
    func syncEventToCalendar(event: ScheduledEvent) async -> Bool {
        guard let bookingId = event.id else {
            errorMessage = "Event ID is missing."
            return false
        }
        
        if let calendarEventID = await calendarSyncManager.addEventToCalendar(event: event) {
            do {
                try await db.collection("bookings").document(bookingId).updateData([
                    "calendarEventID": calendarEventID
                ])
                return true
            } catch {
                errorMessage = "Failed to save calendar event ID: \(error.localizedDescription)"
                return false
            }
        }
        // This handles cases where the event already exists or permission was denied
        errorMessage = calendarSyncManager.lastSyncError
        return false
    }
    
    // Updated to also remove the event from the calendar
    func cancelBooking(event: ScheduledEvent) async {
        guard let bookingId = event.id else {
            errorMessage = "Booking ID is missing, cannot cancel."
            return
        }
        
        // If an ID exists, tell the manager to remove the event from the calendar
        if let calendarEventID = event.calendarEventID {
            calendarSyncManager.removeEventFromCalendar(withIdentifier: calendarEventID)
        }
        
        // Delete the booking from Firestore
        do {
            try await db.collection("bookings").document(bookingId).delete()
        } catch {
            errorMessage = "Failed to cancel booking: \(error.localizedDescription)"
        }
    }
    
    func cancellationFeeDetails(for event: ScheduledEvent) -> (hasFee: Bool, feeAmount: Double) {
        let hoursUntilBooking = Calendar.current.dateComponents([.hour], from: Date(), to: event.startDate).hour ?? Int.max
        
        if hoursUntilBooking < 24 {
            let totalTripPrice = event.destination.price * Double(event.numberOfPeople)
            let fee = totalTripPrice * 0.20
            return (hasFee: true, feeAmount: fee)
        } else {
            return (hasFee: false, feeAmount: 0)
        }
    }
    
    deinit {
        listener?.remove()
    }
}
