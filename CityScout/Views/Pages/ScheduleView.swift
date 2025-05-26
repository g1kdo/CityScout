//
//  ScheduleView.swift
//  CityScout
//
//  Created by Umuco Auca on 26/05/2025.
//
import SwiftUI

struct ScheduleView: View {
    @State private var selectedDate: Date = Date()
    @State private var scheduledEvents: [ScheduledEvent] = []

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
        .onAppear(perform: loadScheduledEvents)
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }

    private var filteredEvents: [ScheduledEvent] {
        scheduledEvents.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private func loadScheduledEvents() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day = 26
        if let eventDate = calendar.date(from: components) {
            scheduledEvents = [
                ScheduledEvent(date: eventDate, destination: Destination.sampleDestinations[0]),
                ScheduledEvent(date: eventDate, destination: Destination.sampleDestinations[1]),
                ScheduledEvent(date: eventDate, destination: Destination.sampleDestinations[2])
            ]
        }

        var octoberComponents = DateComponents()
        octoberComponents.year = 2025
        octoberComponents.month = 10
        octoberComponents.day = 22
        if let octoberEventDate = calendar.date(from: octoberComponents) {
            scheduledEvents.append(ScheduledEvent(date: octoberEventDate, destination: Destination.sampleDestinations[0]))
            scheduledEvents.append(ScheduledEvent(date: octoberEventDate, destination: Destination.sampleDestinations[1]))
            scheduledEvents.append(ScheduledEvent(date: octoberEventDate, destination: Destination.sampleDestinations[2]))
        }
    }
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
    }
}
