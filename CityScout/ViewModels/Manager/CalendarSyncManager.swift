import Foundation
import EventKit
import SwiftUI

@MainActor
class CalendarSyncManager: ObservableObject {
    private let eventStore = EKEventStore()

    @Published var permissionGranted = false
    @Published var lastSyncError: String?
    
    init() {
        checkCalendarPermission()
    }

    private func checkCalendarPermission() {
        let status = EKEventStore.authorizationStatus(for: .event)
        permissionGranted = (status == .authorized || status == .fullAccess)
    }

    func requestAccess() async {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            DispatchQueue.main.async {
                self.permissionGranted = granted
                if !granted {
                    self.lastSyncError = "Calendar access was denied. You can enable it in Settings."
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.lastSyncError = "Failed to request calendar access: \(error.localizedDescription)"
            }
        }
    }

    // UPDATED: This function now returns the unique event identifier as a String.
    func addEventToCalendar(event: ScheduledEvent) async -> String? {
        if !permissionGranted {
            await requestAccess()
            if !permissionGranted { return nil }
        }

        if await eventExists(event: event) {
            print("Event already exists in the calendar.")
            return nil
        }
        
        let newEvent = EKEvent(eventStore: eventStore)
        newEvent.title = "Trip to \(event.destination.name)"
        newEvent.location = event.destination.location
        newEvent.startDate = event.startDate
        newEvent.endDate = event.endDate
        newEvent.notes = "Booking for \(event.numberOfPeople) person(s)."
        newEvent.calendar = eventStore.defaultCalendarForNewEvents
        
        let alarm = EKAlarm(relativeOffset: -3600) // 1 hour before
        newEvent.addAlarm(alarm)

        do {
            try eventStore.save(newEvent, span: .thisEvent)
            return newEvent.eventIdentifier // Return the ID on success
        } catch {
            DispatchQueue.main.async {
                self.lastSyncError = "Failed to save event: \(error.localizedDescription)"
            }
            return nil
        }
    }

    // NEW: This function removes an event from the calendar using its ID.
    func removeEventFromCalendar(withIdentifier identifier: String) {
        guard permissionGranted else {
            print("Cannot remove event, calendar permission not granted.")
            return
        }
        
        if let eventToRemove = eventStore.event(withIdentifier: identifier) {
            do {
                try eventStore.remove(eventToRemove, span: .thisEvent, commit: true)
                print("Successfully removed event from calendar.")
            } catch {
                DispatchQueue.main.async {
                    self.lastSyncError = "Failed to remove event: \(error.localizedDescription)"
                }
            }
        } else {
            print("Could not find event with identifier \(identifier) to remove.")
        }
    }
    
    private func eventExists(event: ScheduledEvent) async -> Bool {
        let predicate = eventStore.predicateForEvents(withStart: event.startDate, end: event.endDate, calendars: nil)
        let existingEvents = eventStore.events(matching: predicate)
        
        return existingEvents.contains { $0.title == "Trip to \(event.destination.name)" && $0.startDate == event.startDate }
    }
}
