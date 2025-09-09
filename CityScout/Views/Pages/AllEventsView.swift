import SwiftUI

struct AllEventsView: View {
    let upcomingEvents: [ScheduledEvent]
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                
                if upcomingEvents.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "suitcase.cart.fill")
                            .font(.largeTitle)
                            .foregroundColor(Color(hex:"#FF7029"))
                        Text("No Upcoming Trips")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("When you book a trip, you'll see it here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List {
                        Section(header: Text("Upcoming Trips")) {
                            ForEach(upcomingEvents) { event in
                                // --- FIX: Hide the action bar ---
                                // This prevents the crash and cleans up the UI.
                                ScheduleEventRow(event: event, showActionBar: false) {}
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("All My Trips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex:"#FF7029"))
                }
            }
        }
    }
}
