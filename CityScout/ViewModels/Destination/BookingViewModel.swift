//
//  BookingViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 30/07/2025.
//


// ViewModels/BookingViewModel.swift
import Foundation
import SwiftUI
import FirebaseFirestore
import Combine

@MainActor
class BookingViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var selectedTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var numberOfPeople: Int = 1
    @Published var isLoading = false
    @Published var bookingSuccess = false
    @Published var errorMessage: String?

    private var db = Firestore.firestore()

    func bookDestination(destination: Destination, userId: String) async {
        isLoading = true
        errorMessage = nil
        bookingSuccess = false

        guard let destinationId = destination.id else {
            errorMessage = "Destination ID is missing."
            isLoading = false
            return
        }

        // Combine selected date and time
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        guard let scheduledDateTime = calendar.date(from: components) else {
            errorMessage = "Failed to combine date and time for booking."
            isLoading = false
            return
        }

        let bookingData: [String: Any] = [
            "userId": userId,
            "destinationId": destinationId,
            "destinationName": destination.name,
            "destinationLocation": destination.location,
            "destinationImageUrl": destination.imageUrl,
            "date": scheduledDateTime,
            "numberOfPeople": numberOfPeople,
            "timestamp": FieldValue.serverTimestamp() // To record when the booking was made
        ]

        do {
            // Add a new document to a "bookings" collection
            _ = try await db.collection("bookings").addDocument(data: bookingData)
            bookingSuccess = true
            print("Booking successful for \(destination.name) on \(scheduledDateTime)")
        } catch {
            errorMessage = "Failed to book destination: \(error.localizedDescription)"
            print("Error booking destination: \(error.localizedDescription)")
        }
        isLoading = false
    }
}
