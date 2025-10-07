import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseFunctions
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
    private let functions = Functions.functions()
    private var cancellables = Set<AnyCancellable>()

    private let messageVM: MessageViewModel
        
    // 🎯 Update initializer to accept MessageViewModel
    init(messageVM: MessageViewModel) {
            self.messageVM = messageVM
        }
    
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

    func bookDestination(destination: Destination, partner: Partner?, userId: String) async {
        isLoading = true
        errorMessage = nil
        bookingSuccess = false

        guard let destinationId = destination.id, let partnerId = destination.partnerId else {
                    errorMessage = "Destination or Partner ID is missing."
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
            // 1. Save the Booking
            let bookingRef = try await db.collection("bookings").addDocument(data: bookingData)
                    
            // 2. Initiate Chat with Partner
            let partnerEmail = partner?.contactEmail // Assuming 'partnerEmail' is available on the Destination model
            let partnerName = partner?.partnerDisplayName // Assuming 'partnerDisplayName' is available

            let chat = await messageVM.startNewChat(with: partnerId)
                    
                    if let newChat = chat {
                        // Send an automatic initial message about the booking
                        let initialMessageText = "A new booking for **\(destination.name)** has been confirmed from \(startDate.formatted()) to \(endDate.formatted()). Booking ID: \(bookingRef.documentID). Please reach out to the customer for coordination."
                        
                        await messageVM.sendMessage(
                            chatId: newChat.id!,
                            text: initialMessageText,
                            recipientId: partnerId
                        )
                    } else {
                        print("Warning: Failed to initiate chat with partner.")
                    }
                    
                    // 3. Send Email Notification to Partner
                    if let email = partnerEmail {
                        await sendBookingEmail(
                            recipientEmail: email,
                            bookingData: bookingData,
                            destinationName: destination.name,
                            partnerName: partnerName ?? "Partner"
                        )
                    }
                    
                    // 4. Send Notification to User (Existing Logic)
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
            
            // --- 🎯 NEW FUNCTION FOR EMAIL NOTIFICATION ---
            private func sendBookingEmail(recipientEmail: String, bookingData: [String: Any], destinationName: String, partnerName: String) async {

                let emailPayload: [String: Any] = [
                    "to": recipientEmail,
                    "subject": "✅ New Booking Confirmation for \(destinationName)",
                    "template": "booking_confirmation", // Or pass the full HTML body
                    "data": [
                        "partnerName": partnerName,
                        "destinationName": destinationName,
                        "startDate": (bookingData["startDate"] as? Date)?.formatted() ?? "N/A",
                        "endDate": (bookingData["endDate"] as? Date)?.formatted() ?? "N/A",
                        "numberOfPeople": bookingData["numberOfPeople"] as? Int ?? 1,
                        "totalCost": totalCost // Use the calculated totalCost
                    ]
                ]
                
                do {
                    // Call the Firebase Cloud Function
                    // Note: This function call is synchronous on the client side but asynchronous on the server side.
                    let result = try await functions.httpsCallable("sendBookingEmail").call(emailPayload)
                    print("Email function result: \(result.data)")
                } catch {
                    // Log the error but don't fail the booking, as the core booking is saved.
                    print("Warning: Failed to send booking email via Cloud Function: \(error.localizedDescription)")
                }
            }
        }
