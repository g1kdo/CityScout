import SwiftUI
import Kingfisher

struct ScheduleEventRow: View {
    let event: ScheduledEvent
    var showActionBar: Bool = true
    let onCancel: () -> Void
    
    // Get the whole ViewModel from the environment
    @EnvironmentObject var scheduleVM: ScheduleViewModel
    
    @State private var isAddingToCalendar = false
    @State private var syncStatusMessage: String?

    private var isPastEvent: Bool {
        return event.endDate < Date()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 15) {
                KFImage(URL(string: event.destination.imageUrl))
                    .placeholder { ProgressView() }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .cornerRadius(10)
                    .clipped()
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formattedDateRange(from: event.startDate, to: event.endDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(event.destination.name)
                        .font(.headline)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(event.destination.location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .layoutPriority(1)
                Spacer(minLength: 8)
            }
            
            if showActionBar && !isPastEvent {
                Divider()
                HStack {
                    // This button now calls the function on the ViewModel
                    Button(action: {
                        Task {
                            isAddingToCalendar = true
                            let success = await scheduleVM.syncEventToCalendar(event: event)
                            syncStatusMessage = success ? "Added to Calendar!" : (scheduleVM.calendarSyncManager.lastSyncError ?? "Failed to add.")
                            isAddingToCalendar = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation { syncStatusMessage = nil }
                            }
                        }
                    }) {
                        HStack(spacing: 4) {
                            if isAddingToCalendar {
                                ProgressView().frame(width: 12, height: 12)
                            } else {
                                Image(systemName: "calendar.badge.plus")
                            }
                            Text("Add to Calendar")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Color(hex: "#24BAEC"))
                    
                    Spacer()
                    
                    Button("Cancel Trip", role: .destructive, action: onCancel)
                        .font(.caption.bold())
                }
                
                if let message = syncStatusMessage {
                    Text(message).font(.caption).foregroundColor(.secondary).transition(.opacity)
                }
            } else if isPastEvent {
                HStack {
                    Spacer()
                    Text("Trip Completed")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Spacer()
                }.padding(.top, 5)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
        .shadow(color: Color.primary.opacity(0.10), radius: 5, x: 0, y: 2)
        .opacity(isPastEvent ? 0.6 : 1.0)
    }

    private func formattedDateRange(from startDate: Date, to endDate: Date) -> String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d MMM"
        return "\(dayFormatter.string(from: startDate)) - \(dayFormatter.string(from: endDate))"
    }
}
