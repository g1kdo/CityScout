import Foundation
import FirebaseFirestore
import Combine

@MainActor
class ScheduleViewModel: ObservableObject {
    // This will hold ALL events, both past and future, for the main calendar view.
    @Published var scheduledEvents: [ScheduledEvent] = []
    
    // This will hold only events that are happening today or in the future.
    @Published var upcomingEvents: [ScheduledEvent] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?
    private var db = Firestore.firestore()

    // A private helper struct to decode the flat data from a 'booking' document.
    private struct BookingData: Codable {
        @DocumentID var id: String?
        var userId: String
        var destinationId: String
        var destinationName: String
        var destinationLocation: String
        var destinationImageUrl: String
        var date: Timestamp
        var numberOfPeople: Int
        var price: Double? // Make sure this is being saved with your booking
    }

    func subscribeToSchedule(for userId: String?) {
        listener?.remove()
        self.listener = nil

        guard let userId = userId else {
            self.scheduledEvents = []
            self.upcomingEvents = []
            return
        }

        isLoading = true
        errorMessage = nil

        listener = db.collection("bookings")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.errorMessage = "Error fetching schedule: \(error.localizedDescription)"
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    self.scheduledEvents = []
                    self.upcomingEvents = []
                    return
                }
                // This is the complete decoding logic
                let allEvents = documents.compactMap { doc -> ScheduledEvent? in
                    guard let booking = try? doc.data(as: BookingData.self) else {
                        print("Failed to decode booking data for document \(doc.documentID).")
                        return nil
                    }
                    
                    let destination = Destination(
                        id: booking.destinationId,
                        name: booking.destinationName,
                        imageUrl: booking.destinationImageUrl,
                        rating: 0.0,
                        location: booking.destinationLocation,
                        participantAvatars: nil,
                        description: nil,
                        price: booking.price ?? 0.0,
                        galleryImageUrls: [],
                        categories: []
                    )
                    
                    return ScheduledEvent(id: booking.id, date: booking.date.dateValue(), destination: destination)
                }
                
                self.scheduledEvents = allEvents
                
                // Filter the full list to create the list of upcoming events.
                self.upcomingEvents = allEvents.filter { $0.date >= Calendar.current.startOfDay(for: Date()) }
            }
    }
    
    /// Cancels a booking and deletes it from Firestore.
    func cancelBooking(event: ScheduledEvent) async {
        guard let bookingId = event.id else {
            errorMessage = "Booking ID is missing, cannot cancel."
            return
        }
        
        let feeDetails = cancellationFeeDetails(for: event)
        if feeDetails.hasFee {
            // In a real app, you would trigger your payment provider here
            // to process a refund minus the fee.
            print("Cancellation fee of $\(String(format: "%.2f", feeDetails.feeAmount)) applies.")
        } else {
            print("Full refund applies.")
        }

        // Delete the booking document from Firestore
        do {
            try await db.collection("bookings").document(bookingId).delete()
            print("Booking \(bookingId) successfully cancelled and deleted.")
        } catch {
            errorMessage = "Failed to cancel booking: \(error.localizedDescription)"
        }
    }
    
    /// Determines if a cancellation fee applies and calculates the amount.
    func cancellationFeeDetails(for event: ScheduledEvent) -> (hasFee: Bool, feeAmount: Double) {
        let hoursUntilBooking = Calendar.current.dateComponents([.hour], from: Date(), to: event.date).hour ?? Int.max
        
        if hoursUntilBooking < 1 {
            let fee = event.destination.price * 0.20 // 20% cancellation fee
            return (hasFee: true, feeAmount: fee)
        } else {
            return (hasFee: false, feeAmount: 0)
        }
    }
    
    deinit {
        listener?.remove()
    }
}
