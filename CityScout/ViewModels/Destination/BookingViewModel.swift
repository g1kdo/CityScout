import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseFunctions
import Combine

@MainActor
class BookingViewModel: ObservableObject {
    @Published var selectedDates: Set<Date> = []
    @Published var checkInTime: Date = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var checkOutTime: Date = Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var numberOfPeople: Int = 1
    @Published var isLoading = false
    @Published var bookingSuccess = false
    @Published var errorMessage: String?
    @Published var totalCost: Double = 0.0

    private var db = Firestore.firestore()
    private let usersCollection = "users"
    private let destinationsCollection = "destinations"
    private let functions = Functions.functions()
    private var cancellables = Set<AnyCancellable>()

    private let messageVM: MessageViewModel
        
    init(messageVM: MessageViewModel) {
            self.messageVM = messageVM
    }
    
    func calculateTripCost(destination: Destination?) {
        guard let destination = destination, !selectedDates.isEmpty else {
            totalCost = 0.0
            return
        }

        let sortedDates = selectedDates.sorted()
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
    
    // REMOVED: fetchPartnerData and sendBookingEmail (Moved to Cloud Function Trigger for security)

    func bookDestination(destination: Destination, userId: String) async {
        isLoading = true
        errorMessage = nil
        bookingSuccess = false

        guard let destinationId = destination.id, let partnerId = destination.partnerId else {
            errorMessage = "Destination or Partner ID is missing."
            isLoading = false
            return
        }
        
        let sortedDates = selectedDates.sorted()
        guard let firstDate = sortedDates.first else {
            errorMessage = "Please select a valid date range."
            isLoading = false
            return
        }
        
        let calendar = Calendar.current
        
        var startComponents = calendar.dateComponents([.year, .month, .day], from: firstDate)
        let checkInTimeComponents = calendar.dateComponents([.hour, .minute], from: checkInTime)
        startComponents.hour = checkInTimeComponents.hour
        startComponents.minute = checkInTimeComponents.minute
        
        guard let startDate = calendar.date(from: startComponents) else {
            errorMessage = "Invalid start date components."
            isLoading = false; return
        }
        
        var endDate: Date
        
        if sortedDates.count == 1 {
            var endComponents = calendar.dateComponents([.year, .month, .day], from: firstDate)
            let checkOutTimeComponents = calendar.dateComponents([.hour, .minute], from: checkOutTime)
            endComponents.hour = checkOutTimeComponents.hour
            endComponents.minute = checkOutTimeComponents.minute
            
            guard let calculatedEndDate = calendar.date(from: endComponents) else {
                errorMessage = "Invalid end date components."; isLoading = false; return
            }
            endDate = calculatedEndDate
            
            if endDate <= startDate {
                errorMessage = "For a single day booking, check-out time must be after check-in time."
                isLoading = false; return
            }
            
        } else {
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
            // 1. Save the Booking (Triggers the 'onBookingCreated' Cloud Function for email)
            let bookingRef = try await db.collection("bookings").addDocument(data: bookingData)
            
            // 2. Initiate Chat with Partner
            // Note: If this fails due to permissions, the email will still be sent by the backend.
            let chat = await messageVM.startNewChat(with: partnerId)
            
            if let newChat = chat {
                let initialMessageText = "Hi there! I just booked *\(destination.name)* for my trip! I'm arriving on **\(startDate.formatted())** and checking out on **\(endDate.formatted())**. I'll be traveling with \(numberOfPeople) person(s) in total. I'm really looking forward to it and wanted to say hello! Could you tell me a little about the check-in process?"
                
                await messageVM.sendMessage(
                    chatId: newChat.id!,
                    text: initialMessageText,
                    recipientId: partnerId
                )
            } else {
                print("Warning: Failed to initiate chat with partner. (Check 'getPartnerPublicInfo' in MessageViewModel)")
            }
            
            // 3. Send Notification to User (Local/Firestore)
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
            errorMessage = "Failed to complete booking: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
