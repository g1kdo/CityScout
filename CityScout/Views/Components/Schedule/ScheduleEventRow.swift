//
//  ScheduleEventRow.swift
//  CityScout
//
//  Created by Umuco Auca on 26/05/2025.
//


//
//  ScheduleEventRow.swift
//  CityScout
//
//  Created by Umuco Auca on 26/05/2025.
//

import SwiftUI
import Kingfisher // Import Kingfisher

struct ScheduleEventRow: View {
    let event: ScheduledEvent

    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            
            KFImage(URL(string: event.destination.imageUrl)) // Use KFImage
                .placeholder {
                    ProgressView() // Show a progress view while loading
                }
                .onFailure { error in
                    // A more prominent placeholder for failed load
                    Image(systemName: "exclamationmark.triangle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.red)
                        .frame(width: 80, height: 80) // Ensure placeholder fills the frame
                        .background(Color.secondary.opacity(0.1)) // Add a subtle background
                        .cornerRadius(10)
                }
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .cornerRadius(10)
                .clipped()
                

            VStack(alignment: .leading, spacing: 5) { // Spacing between calendar, title, and location
                HStack(spacing: 4) { // Tighter spacing for icon and text
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(formattedDate(event.date))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Limit destination name to max 2 lines
                Text(event.destination.name)
                    .font(.headline)
                    .lineLimit(2) // Allow up to 2 lines
                    .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion, prevent horizontal clipping if too long
                
                HStack(spacing: 4) { // Tighter spacing for icon and text
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                    // Limit location to max 1 line to keep it concise
                    Text(event.destination.location)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1) // Keep location on a single line
                        .truncationMode(.tail) // Add ellipsis if too long
                }
            }
            // Use .layoutPriority to ensure this VStack takes up available space
            // but still leaves room for the chevron
            .layoutPriority(1) // Give this VStack higher priority to take space

            Spacer() // Pushes the chevron to the end

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption) // Make chevron slightly smaller to align with text visually
        }
        .padding(.vertical, 10) // Slightly more vertical padding
        .padding(.horizontal) // Apply horizontal padding directly here to ensure content is inside
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        // Example: "26 May 2025, 3:30 PM"
        formatter.dateFormat = "d MMM yyyy, h:mm a" // Abbreviated month for brevity
        return formatter.string(from: date)
    }
}

struct ScheduleEventRow_Previews: PreviewProvider {
    static var previews: some View {
        // You'll need to define ScheduledEvent and Destination for this preview to work
        // Using a sample event for the preview
        ScheduleEventRow(event: ScheduledEvent(
            id: UUID().uuidString,
            date: Date(),
            destination: Destination(
                id: UUID().uuidString,
                name: "Very Long Destination Name That Might Wrap And Wrap",
                imageUrl: "https://picsum.photos/80/80", // Use a placeholder image URL for preview
                rating: 4.5,
                location: "A Slightly Longer Location Name",
                participantAvatars: [],
                description: "",
                price: 0,
                galleryImageUrls:   []
            )
        ))
        .previewLayout(.sizeThatFits)
        .padding() // Add padding to the preview to see the shadow and layout
    }
}
