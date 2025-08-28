import SwiftUI

struct ScheduleView: View {
    @State private var selectedDate: Date = Date()
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var scheduleVM = ScheduleViewModel()
    
    @State private var eventToCancel: ScheduledEvent?
    @State private var showingCancelAlert = false
    @State private var showingAllEvents = false

    private var allEventsForCalendar: [ScheduledEvent] {
        return scheduleVM.scheduledEvents + scheduleVM.pastEvents
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            CalendarHeader(selectedDate: $selectedDate)
                .padding(.horizontal)

            CalendarView(selectedDate: $selectedDate, events: allEventsForCalendar)

            HStack {
                Text("My Schedule")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("View all") {
                    showingAllEvents = true
                }
                .font(.subheadline)
                .foregroundColor(Color(hex: "#FF7029"))
            }
            .padding(.horizontal)

            ScrollView(.vertical, showsIndicators: false) {
                if filteredEvents.isEmpty {
                    Text("No events scheduled for this date.")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 15) {
                        ForEach(filteredEvents) { event in
                            ScheduleEventRow(event: event) {
                                self.eventToCancel = event
                                self.showingCancelAlert = true
                            }
                            // Pass the ViewModel to each row
                            .environmentObject(scheduleVM)
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .onAppear {
            if let userId = authVM.user?.uid {
                scheduleVM.subscribeToSchedule(for: userId)
            }
        }
        .onChange(of: authVM.user?.uid) { _, newUserId in
            scheduleVM.subscribeToSchedule(for: newUserId)
        }
        .alert("Cancel Booking?", isPresented: $showingCancelAlert, presenting: eventToCancel) { event in
            Button("Confirm Cancellation", role: .destructive) {
                Task {
                    await scheduleVM.cancelBooking(event: event)
                }
            }
            Button("Never Mind", role: .cancel) {}
        } message: { event in
            let feeDetails = scheduleVM.cancellationFeeDetails(for: event)
            if feeDetails.hasFee {
                Text("If you cancel now, a 20% fee of $\(String(format: "%.2f", feeDetails.feeAmount)) will be charged. Are you sure?")
            } else {
                Text("Are you sure you want to cancel your booking for \(event.destination.name)? You will receive a full refund.")
            }
        }
        .fullScreenCover(isPresented: $showingAllEvents) {
            AllEventsView(upcomingEvents: scheduleVM.scheduledEvents)
        }
    }

    private var filteredEvents: [ScheduledEvent] {
        allEventsForCalendar.filter { event in
            let selectedDay = Calendar.current.startOfDay(for: selectedDate)
            guard event.startDate <= event.endDate else { return false }
            let eventRange = Calendar.current.startOfDay(for: event.startDate)...event.endDate
            return eventRange.contains(selectedDay)
        }
    }
}
