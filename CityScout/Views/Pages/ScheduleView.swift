import SwiftUI

struct ScheduleView: View {
    @State private var selectedDate: Date = Date()
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var scheduleVM = ScheduleViewModel()
    
    // State for managing alerts and sheets
    @State private var eventToCancel: ScheduledEvent?
    @State private var showingCancelAlert = false
    @State private var showingAllEvents = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CalendarHeader(selectedDate: $selectedDate)
                .padding(.horizontal)
                .padding(.bottom, 20)

            CalendarView(selectedDate: $selectedDate)
                .padding(.bottom, 30)

            HStack {
                Text("My Schedule")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                // This button now presents the AllEventsView sheet
                Button("View all") {
                    showingAllEvents = true
                }
                .font(.subheadline)
                .foregroundColor(Color(hex: "#FF7029"))
            }
            .padding(.horizontal)
            .padding(.bottom, 15)

            ScrollView(.vertical, showsIndicators: false) {
                if filteredEvents.isEmpty {
                    Text("No events scheduled for this date.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    VStack(spacing: 15) {
                        ForEach(filteredEvents) { event in
                            ScheduleEventRow(event: event) {
                                self.eventToCancel = event
                                self.showingCancelAlert = true
                            }
                            .padding(.horizontal)
                            // Disable interaction for past events
                            .disabled(event.date < Calendar.current.startOfDay(for: Date()))
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
            if let userId = newUserId {
                scheduleVM.subscribeToSchedule(for: userId)
            }
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
        // This sheet presents the new AllEventsView
        .fullScreenCover(isPresented: $showingAllEvents) {
            AllEventsView(upcomingEvents: scheduleVM.upcomingEvents)
        }
    }

    private var filteredEvents: [ScheduledEvent] {
        scheduleVM.scheduledEvents.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
}
