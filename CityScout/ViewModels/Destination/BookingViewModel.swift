import Foundation
import SwiftUI
import FirebaseFirestore
import Combine

@MainActor
class BookingViewModel: ObservableObject {
    @Published var selectedDates: Set<DateComponents> = []
    @Published var checkInTime: Date = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var checkOutTime: Date = Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var numberOfPeople: Int = 1
    @Published var isLoading = false
    // FIX: Changed this to a simple Bool for the alert modifier.
    @Published var bookingSuccess = false
    @Published var errorMessage: String?
    @Published var totalCost: Double = 0.0

    private var db = Firestore.firestore()
    private let usersCollection = "users"
    private let destinationsCollection = "destinations"
    private var cancellables = Set<AnyCancellable>()

    init() {}
    
    func calculateTripCost(destination: Destination?) {
        guard let destination = destination, !selectedDates.isEmpty else {
            totalCost = 0.0
            return
        }

        let sortedDates = selectedDates.compactMap { Calendar.current.date(from: $0) }.sorted()
        guard let firstDate = sortedDates.first, let lastDate = sortedDates.last else {
            totalCost = 0.0
            return
        }

        let numberOfNights = sortedDates.count == 1 ? 1 : (Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0) + 1
        
        totalCost = (destination.price) * Double(numberOfPeople) * Double(numberOfNights)
    }

    private func isDateRangeAvailable(destinationId: String, startDate: Date, endDate: Date) async -> Bool {
        let bookingsRef = db.collection("bookings")
        let query = bookingsRef
            .whereField("destinationId", isEqualTo: destinationId)
            .whereField("startDate", isLessThan: endDate)

        do {
            let querySnapshot = try await query.getDocuments()
            for document in querySnapshot.documents {
                if let bookingEndDate = (document.data()["endDate"] as? Timestamp)?.dateValue() {
                    if bookingEndDate > startDate {
                        return false
                    }
                }
            }
            return true
        } catch {
            errorMessage = "Error checking availability: \(error.localizedDescription)"
            return false
        }
    }

    func bookDestination(destination: Destination, userId: String) async {
        isLoading = true
        errorMessage = nil
        bookingSuccess = false

        guard let destinationId = destination.id else {
            errorMessage = "Destination ID is missing."
            isLoading = false
            return
        }
        
        let sortedDates = selectedDates.compactMap { Calendar.current.date(from: $0) }.sorted()
        guard let firstDate = sortedDates.first else {
            errorMessage = "Please select a valid date range."
            isLoading = false
            return
        }
        
        let calendar = Calendar.current
        
        // --- CORRECTED LOGIC FOR SINGLE AND MULTI-DAY BOOKINGS ---
        
        // Combine start date with check-in time
        var startComponents = calendar.dateComponents([.year, .month, .day], from: firstDate)
        let checkInTimeComponents = calendar.dateComponents([.hour, .minute], from: checkInTime)
        startComponents.hour = checkInTimeComponents.hour
        startComponents.minute = checkInTimeComponents.minute
        
        guard let startDate = calendar.date(from: startComponents) else {
            errorMessage = "Invalid start date components."
            isLoading = false; return
        }
        
        var endDate: Date
        
        // If it's a single-day booking (e.g., a few hours)
        if sortedDates.count == 1 {
            var endComponents = calendar.dateComponents([.year, .month, .day], from: firstDate) // Use the same day
            let checkOutTimeComponents = calendar.dateComponents([.hour, .minute], from: checkOutTime)
            endComponents.hour = checkOutTimeComponents.hour
            endComponents.minute = checkOutTimeComponents.minute
            
            guard let calculatedEndDate = calendar.date(from: endComponents) else {
                errorMessage = "Invalid end date components."; isLoading = false; return
            }
            endDate = calculatedEndDate
            
            // Ensure check-out is after check-in for same-day bookings
            if endDate <= startDate {
                errorMessage = "For a single day booking, check-out time must be after check-in time."
                isLoading = false; return
            }
            
        } else { // If it's a multi-day (overnight) booking
            let lastDate = sortedDates.last!
            var endComponents = calendar.dateComponents([.year, .month, .day], from: lastDate)
            let checkOutTimeComponents = calendar.dateComponents([.hour, .minute], from: checkOutTime)
            endComponents.hour = checkOutTimeComponents.hour
            endComponents.minute = checkOutTimeComponents.minute
            
            guard let calculatedEndDate = calendar.date(from: endComponents) else {
                errorMessage = "Invalid end date components."; isLoading = false; return
            }
            endDate = calculatedEndDate
        }
        
        guard startDate >= Date().addingTimeInterval(-60) else {
             errorMessage = "You cannot select a date or time in the past."
             isLoading = false; return
        }

        if await !isDateRangeAvailable(destinationId: destinationId, startDate: startDate, endDate: endDate) {
            errorMessage = "Sorry, some of these dates are already booked."
            isLoading = false; return
        }

        let bookingData: [String: Any] = [
            "userId": userId, "destinationId": destinationId, "destinationName": destination.name,
            "destinationLocation": destination.location, "destinationImageUrl": destination.imageUrl,
            "startDate": startDate, "endDate": endDate, "numberOfPeople": numberOfPeople,
            "price": destination.price, "timestamp": FieldValue.serverTimestamp()
        ]

        do {
            _ = try await db.collection("bookings").addDocument(data: bookingData)
            let notificationData: [String: Any] = [
                "title": "Booking Confirmed",
                "message": "Your booking for \(destination.name) has been confirmed!",
                "timestamp": FieldValue.serverTimestamp(), "isRead": false, "isArchived": false,
                "destinationId": destination.id ?? ""
            ]
            let notificationRef = db.collection(usersCollection).document(userId).collection("notifications")
            _ = try await notificationRef.addDocument(data: notificationData)
            bookingSuccess = true
        } catch {
            errorMessage = "Failed to book destination: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
