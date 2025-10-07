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
    
    private func fetchPartnerData(partnerId: String) async -> (email: String?, name: String?) {
        do {
            let partnerDoc = try await db.collection("partners").document(partnerId).getDocument()

            if partnerDoc.exists {
                let email = partnerDoc.data()?["partnerEmail"] as? String 
                let name = partnerDoc.data()?["name"] as? String 
                return (email, name)
            }
        } catch {
            print("Error fetching partner data for email: \(error.localizedDescription)")
        }
        return (nil, nil)
    }

    func bookDestination(destination: Destination, userId: String) async {
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
            
            let (fetchedPartnerEmail, fetchedPartnerName) = await fetchPartnerData(partnerId: partnerId)
                    
            // 2. Initiate Chat with Partner

            let chat = await messageVM.startNewChat(with: partnerId)
                    
                    if let newChat = chat {
                        // Send an automatic initial message about the booking
                        let initialMessageText = "Hi there! I just booked *\(destination.name)* for my trip! I'm arriving on **\(startDate.formatted())** and checking out on **\(endDate.formatted())**. I'll be traveling with \(numberOfPeople) person(s) in total. I'm really looking forward to it and wanted to say hello! Could you tell me a little about the check-in process?"
                        
                        await messageVM.sendMessage(
                            chatId: newChat.id!,
                            text: initialMessageText,
                            recipientId: partnerId
                        )
                    } else {
                        print("Warning: Failed to initiate chat with partner.")
                    }
                    
                    // 3. Send Email Notification to Partner
                    if let email = fetchedPartnerEmail, !email.isEmpty {
                            await sendBookingEmail(
                                recipientEmail: email,
                                bookingData: bookingData,
                                destinationName: destination.name,
                                partnerName: fetchedPartnerName ?? "Partner"
                            )
                        } else {
                            // This block executes if partnerEmail is nil or empty.
                            print("WARNING: Email notification skipped. Partner's contactEmail is missing or empty on the Partner object.")
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
            
    private func sendBookingEmail(recipientEmail: String, bookingData: [String: Any], destinationName: String, partnerName: String) async {

                // Get safe, numeric timestamps for reliable serialization
                let startTimestamp = (bookingData["startDate"] as? Date)?.timeIntervalSince1970 ?? 0
                let endTimestamp = (bookingData["endDate"] as? Date)?.timeIntervalSince1970 ?? 0
        
        print("Attempting to send email to: \(recipientEmail)")
                
                // Convert timestamps back to formatted strings for the email template data
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                
                let startDateString = (bookingData["startDate"] as? Date)?.formatted() ?? "N/A"
                let endDateString = (bookingData["endDate"] as? Date)?.formatted() ?? "N/A"

                let emailPayload: [String: Any] = [
                    "to": recipientEmail,
                    "subject": "✅ New Booking Confirmation for \(destinationName)",
                    "template": "booking_confirmation", // Or pass the full HTML body
                    "data": [
                        "partnerName": partnerName,
                        "destinationName": destinationName,
                        // Sending string dates for display in the email template
                        "startDate": startDateString,
                        "endDate": endDateString,
                        "numberOfPeople": bookingData["numberOfPeople"] as? Int ?? 1,
                        "totalCost": totalCost
                    ]
                ]
                
                do {
                    // Call the Firebase Cloud Function
                    let result = try await functions.httpsCallable("sendBookingEmail").call(emailPayload)
                    print("Email function result: \(result.data)")
                } catch {
                    // Log the error but don't fail the booking, as the core booking is saved.
                    print("Warning: Failed to send booking email via Cloud Function: \(error.localizedDescription)")
                }
            }
        }
