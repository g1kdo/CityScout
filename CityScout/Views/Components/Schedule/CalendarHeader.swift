//
//  CalendarHeader.swift
//  CityScout
//
//  Created by Umuco Auca on 26/05/2025.
//
import SwiftUI

struct CalendarHeader: View {
    @Binding var selectedDate: Date
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        return formatter
    }()

    var body: some View {
        HStack {
            Text(dateFormatter.string(from: selectedDate))
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
            Button(action: {
                if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
                    selectedDate = newDate
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
            Button(action: {
                if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
                    selectedDate = newDate
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
}

struct CalendarHeader_Previews: PreviewProvider {
    @State static var selectedDate: Date = Date()
    static var previews: some View {
        CalendarHeader(selectedDate: $selectedDate)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
