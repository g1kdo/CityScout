import SwiftUI

struct ScheduleView: View {
    @State private var selectedDate: Date = Date()
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var scheduleVM = ScheduleViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CalendarHeader(selectedDate: $selectedDate)
                          .padding(.horizontal)
                          .padding(.bottom, 20)

            // The CalendarView now provides the single, correct header.
            CalendarView(selectedDate: $selectedDate)
                .padding(.bottom, 30)

            HStack {
                Text("My Schedule")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("View all") {
                    // Action for viewing all scheduled events
                }
                .font(.subheadline)
                .foregroundColor(Color(hex: "#FF7029"))
            }
            .padding(.horizontal)
            .padding(.bottom, 15)

            ScrollView(.vertical, showsIndicators: false) {
                if filteredEvents.isEmpty {
                    Text("No events scheduled for this date.")
                        .foregroundColor(.secondary) // Use adaptive color
                        .padding()
                } else {
                    VStack(spacing: 15) {
                        ForEach(filteredEvents) { event in
                            ScheduleEventRow(event: event)
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
            if let userId = newUserId {
                scheduleVM.subscribeToSchedule(for: userId)
            }
        }
        // The view will now correctly adopt the system's theme.
    }

    private var filteredEvents: [ScheduledEvent] {
        scheduleVM.scheduledEvents.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
}
