import SwiftUI
import Kingfisher

struct ScheduleEventRow: View {
    let event: ScheduledEvent
    // --- NEW PROPERTY ---
    // This allows us to show or hide the cancel button.
    var showCancelButton: Bool = true
    let onCancel: () -> Void
    
    var isPastEvent: Bool {
        return event.date < Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
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
                    Text(formattedDate(event.date))
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

            // --- UPDATED LOGIC ---
            // The button is now only shown if it's not a past event AND
            // if `showCancelButton` is true.
            if isPastEvent {
                Text("Event\nPassed")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(width: 60)
            } else if showCancelButton {
                Button("Cancel", role: .destructive, action: onCancel)
                    .font(.caption.bold())
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
        .shadow(color: Color.primary.opacity(0.10), radius: 5, x: 0, y: 2)
        .opacity(isPastEvent ? 0.6 : 1.0)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy, h:mm a"
        return formatter.string(from: date)
    }
}
