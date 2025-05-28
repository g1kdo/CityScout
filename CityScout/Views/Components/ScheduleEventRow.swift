//
//  ScheduleEventRow.swift
//  CityScout
//
//  Created by Umuco Auca on 26/05/2025.
//
import SwiftUI

struct ScheduleEventRow: View {
    let event: ScheduledEvent

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(event.destination.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .cornerRadius(10)
                .clipped()

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(formattedDate(event.date))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text(event.destination.name)
                    .font(.headline)
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(event.destination.location)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
}

struct ScheduleEventRow_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleEventRow(event: ScheduledEvent(date: Date(), destination: Destination.sampleDestinations[0]))
            .padding()
           // .previewLayout(.sizeThatFits)
    }
}
