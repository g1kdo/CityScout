//
//  CalendarView.swift
//  CityScout
//
//  Created by Umuco Auca on 26/05/2025.
//
import SwiftUI
import Foundation // Make sure Foundation is imported for Date and Calendar operations

struct CalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentDate: Date = Date() // Used to display the current month

    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM YYYY" // Changed to YYYY to display full year
        return formatter
    }()

    var body: some View {
        VStack(spacing: 20) {
            // Month Navigation
            HStack {
                Button(action: {
                    changeMonth(by: -1)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                Spacer()
                Text(dateFormatter.string(from: currentDate))
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    changeMonth(by: 1)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)

            // Day of Week Header
            HStack {
                // Use the public weekDays from the Date extension
                ForEach(Date.weekDays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.footnote)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.gray)
                }
            }

            // Days Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(daysInMonth(for: currentDate), id: \.self) { date in
                    if calendar.isDate(date, equalTo: currentDate, toGranularity: .month) {
                        // Use the public isSameDayAs from the Date extension
                        DayCell(date: date, isSelected: date.isSameDayAs(selectedDate)) {
                            selectedDate = date
                        }
                    } else if date == Date.distantPast { // Check for our placeholder
                        Text("") // Empty cell for leading blanks
                            .frame(maxWidth: .infinity, minHeight: 40)
                    } else {
                        // Optionally handle trailing blank days if necessary
                        Text("")
                            .frame(maxWidth: .infinity, minHeight: 40)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func daysInMonth(for date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return [] }
        guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else { return [] }

        var dates: [Date] = []

        // Add leading empty days for alignment
        let weekdayOfFirstDay = calendar.component(.weekday, from: firstDayOfMonth)
        // Adjust for Sunday = 1, Monday = 2, etc., to match your calendar's start day (e.g., Sunday)
        let numberOfLeadingBlanks = (weekdayOfFirstDay - calendar.firstWeekday + 7) % 7
        for _ in 0..<numberOfLeadingBlanks {
            dates.append(Date.distantPast) // Use a distinct placeholder for blank days
        }

        // Add days of the month
        // Corrected enumerateDates usage
        calendar.enumerateDates(
            //in: monthInterval,
            startingAfter: <#Date#>, matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .strict,
            using: { date, _, stop in
                
                if let date = date {
                    dates.append(date)
                }
            }
        )

        return dates
    }

    private func changeMonth(by months: Int) {
        if let newDate = calendar.date(byAdding: .month, value: months, to: currentDate) {
            currentDate = newDate
        }
    }
}

// Helper for DayCell (No changes needed here if you only moved the Date extension)
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: action) {
            VStack {
                Text(String(calendar.component(.day, from: date)))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 40, height: 40)
            .background(isSelected ? Color(hex: "#FF7029") : Color.clear)
            .clipShape(Circle())
        }
    }
}

struct CalendarView_Previews: PreviewProvider {
    @State static var selectedDate: Date = Date()
    static var previews: some View {
        CalendarView(selectedDate: $selectedDate)
    }
}
