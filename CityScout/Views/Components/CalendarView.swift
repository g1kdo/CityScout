//
//  CalendarView.swift
//  CityScout
//
//  Created by Umuco Auca on 26/05/2025.
//
import SwiftUI
import Foundation // Make sure Foundation is imported for Date and Calendar operations

struct CalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentDate: Date = Date() // Used to display the current month

    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy" // Changed to yyyy to display full year
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
                    // Only show day numbers for dates within the current month, or if it's the `distantPast` placeholder
                    if calendar.isDate(date, equalTo: currentDate, toGranularity: .month) || date == Date.distantPast {
                        DayCell(date: date, isSelected: date.isSameDayAs(selectedDate)) {
                            selectedDate = date
                        }
                    } else {
                        // For days outside the current month (e.g., trailing days of the next month if needed)
                        Text("") // Empty cell for non-relevant days
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

        let weekdayOfFirstDay = calendar.component(.weekday, from: firstDayOfMonth)
        // Adjust for Sunday = 1, Monday = 2, etc., to match your calendar's start day (e.g., Sunday)
        let numberOfLeadingBlanks = (weekdayOfFirstDay - calendar.firstWeekday + 7) % 7
        for _ in 0..<numberOfLeadingBlanks {
            dates.append(Date.distantPast) 
        }

        // --- FIX STARTS HERE ---
        // Iterate through each day in the month interval
        var currentDay = monthInterval.start
        while currentDay < monthInterval.end {
            dates.append(currentDay)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else { break }
            currentDay = nextDay
        }
        // --- FIX ENDS HERE ---

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
                if date != Date.distantPast {
                    Text(String(calendar.component(.day, from: date)))
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                } else {
                    Text("") 
                }
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
