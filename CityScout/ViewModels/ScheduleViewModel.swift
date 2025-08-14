//
//  ScheduleViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 30/07/2025.
//


// ViewModels/ScheduleViewModel.swift
import Foundation
import FirebaseFirestore
import Combine // Don't forget to import Combine for @Published

@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var scheduledEvents: [ScheduledEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?
    private var db = Firestore.firestore()

    func subscribeToSchedule(for userId: String?) {
        // Remove existing listener if user changes or logs out
        listener?.remove()
        self.listener = nil

        guard let userId = userId else {
            self.scheduledEvents = [] // Clear events if no user ID
            return
        }

        isLoading = true
        errorMessage = nil

        // Listen for bookings belonging to the current user
        listener = db.collection("bookings")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: false) // Order by booking date
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }

                self.isLoading = false

                if let error = error {
                    self.errorMessage = "Error fetching schedule: \(error.localizedDescription)"
                    print("Error fetching schedule: \(error.localizedDescription)")
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    self.scheduledEvents = []
                    return
                }

                // Map Firestore documents to ScheduledEvent objects
                self.scheduledEvents = documents.compactMap { doc -> ScheduledEvent? in
                    do {
                        // Decode directly from the document
                        let bookingData = doc.data()
                        
                        // Manually extract properties if direct decoding of ScheduledEvent fails
                        // due to it not being directly decodable from a flat "booking" document.
                        guard
                            let destinationId = bookingData["destinationId"] as? String,
                            let destinationName = bookingData["destinationName"] as? String,
                            let destinationLocation = bookingData["destinationLocation"] as? String,
                            let destinationImageUrl = bookingData["destinationImageUrl"] as? String,
                            let dateTimestamp = bookingData["date"] as? Timestamp
                        else {
                            print("Failed to parse booking data from document: \(bookingData)")
                            return nil
                        }

                        // Create a dummy Destination from booking details for ScheduledEvent
                        let dummyDestination = Destination(
                            id: destinationId, // Assuming you have an ID on Destination now
                            name: destinationName,
                            imageUrl: destinationImageUrl,
                            rating: 0.0, // Default or fetch if needed
                            location: destinationLocation,
                            participantAvatars: nil, // Not part of booking data directly
                            description: nil, // Not part of booking data directly
                            price: 0.0,
                            galleryImageUrls: []// Not part of booking data directly
                            
                        )
                        
                        return ScheduledEvent(id: doc.documentID, date: dateTimestamp.dateValue(), destination: dummyDestination)

                    } catch {
                        print("Error decoding scheduled event: \(error.localizedDescription)")
                        return nil
                    }
                }
            }
    }

    deinit {
        listener?.remove()
    }
}

