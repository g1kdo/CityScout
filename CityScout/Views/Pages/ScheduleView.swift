//
//  ScheduleView.swift
//  CityScout
//
//  Created by Umuco Auca on 26/05/2025.
//
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
                        .foregroundColor(.gray)
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
           .onChange(of: authVM.user?.uid) { oldValue, newUserId in
               if let userId = newUserId {
                   scheduleVM.subscribeToSchedule(for: userId)
               }
           }
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }

    private var filteredEvents: [ScheduledEvent] {
        // Make sure you're accessing the scheduledEvents from your @StateObject scheduleVM
        scheduleVM.scheduledEvents.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
    }
}
