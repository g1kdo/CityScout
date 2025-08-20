import SwiftUI

// This new view displays a simple list of all upcoming scheduled events.
struct AllEventsView: View {
    @Environment(\.dismiss) var dismiss
    // This view receives the list of upcoming events from its parent.
    let upcomingEvents: [ScheduledEvent]

    var body: some View {
        NavigationStack {
            ZStack {
                // Add an adaptive background to ensure it's not transparent
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                Group {
                    if upcomingEvents.isEmpty {
                        VStack {
                            Image(systemName: "calendar.badge.plus")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 4)
                            Text("No Upcoming Events")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Book a trip to see it on your schedule.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        List {
                            ForEach(upcomingEvents) { event in
                                // We reuse the ScheduleEventRow but hide the cancel button
                                // as this is a read-only summary view.
                                ScheduleEventRow(event: event, showCancelButton: false, onCancel: {})
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("All Upcoming Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                                  
                                   Button("Done") { dismiss() }
                                       .foregroundColor(Color(hex: "#FF7029"))
                               }
            }
        }
    }
}
