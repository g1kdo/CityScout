//
// CustomMultiDatePickerView.swift
// CityScout
//
// Created by Umuco Auca on 03/11/2025.
//


import SwiftUI

// MARK: - Date Toggling Helper (Remains the same)
extension Set where Element == Date {
    // Toggles the presence of a date in the set, matching only the day, month, and year components.
    mutating func toggle(_ date: Date, using calendar: Calendar) {
        let matchingDate = self.first { calendar.isDate($0, inSameDayAs: date) }
        
        if let existingDate = matchingDate {
            // Found a match, so remove it (Deselect)
            self.remove(existingDate)
        } else {
            // No match found, so insert the new date (Select).
            // Normalize the date to start of day for consistent storage.
            let startOfDayDate = calendar.startOfDay(for: date)
            self.insert(startOfDayDate)
        }
    }
}

// MARK: - Custom Multi-Date Picker View (Simplified)
struct CustomMultiDatePickerView: View {
    // Input/Output Bindings
    @Binding var selectedDates: Set<Date>
    @Binding var currentMonth: Date // Controls which month is displayed
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 1 // 1 = Sunday
        return cal
    }
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(spacing: 15) {
            
            // 1. Weekday Header
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.callout)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }
            
            // 2. Day Grid
            let days = generateDays(for: currentMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(days, id: \.self) { date in
                    dayView(for: date)
                }
            }
        }
        .padding()
    }

    // MARK: - Day Rendering Logic (Modified)
    @ViewBuilder
    private func dayView(for date: Date) -> some View {
        // --- NEW LOGIC: Check if the date is in the past relative to today ---
        // We compare the start of the day for the date being rendered against the start of today.
        let todayStartOfDay = calendar.startOfDay(for: Date())
        let dateStartOfDay = calendar.startOfDay(for: date)
        let isPast = dateStartOfDay < todayStartOfDay
        // ---------------------------------------------------------------------
        
        let isSelected = selectedDates.contains(where: { calendar.isDate($0, inSameDayAs: date) })
        let isToday = calendar.isDateInToday(date)
        let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
        
        // Determine if the day is interactable (must be in the current month AND not in the past)
        let isSelectable = isCurrentMonth && !isPast
        
        VStack(spacing: 4) {
            Text(String(calendar.component(.day, from: date)))
                .font(.title3)
                .fontWeight(isSelected || isToday ? .bold : .regular)
                .foregroundColor({
                    // Set color based on state
                    if isSelected {
                        return Color(hex: "#24BAEC") // Selected color
                    } else if isPast {
                        return Color.gray // Past days are gray
                    } else if isCurrentMonth {
                        return Color.primary // Current month days are primary
                    } else {
                        return Color.secondary.opacity(0.5) // Adjacent month days
                    }
                }())
                .frame(width: 40, height: 40)
                .background {
                    if isSelected && !isPast {
                        // Highlight the selected date with the accent color
                        Circle().fill(Color(hex: "#24BAEC")).opacity(0.15)
                    } else if isToday && !isSelected {
                        Circle().fill(Color.gray.opacity(0.15))
                    }
                    // No background for past days
                }
                .onTapGesture {
                    if isSelectable {
                        selectedDates.toggle(date, using: calendar)
                    }
                }
            
            Spacer().frame(height: 5)
        }
        // Past dates should be less opaque, but only if they are not selected.
        .opacity(isPast && !isSelected ? 0.6 : 1.0)
        
        // Only allow hit testing if the date is in the current month AND is not in the past.
        .allowsHitTesting(isSelectable)
    }
    
    // MARK: - generateDays function (Remains the same)
    private func generateDays(for date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthInterval.start)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let emptyDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days: [Date] = []
        
        // Preceding days from the previous month
        for i in 0..<emptyDays {
            if let date = calendar.date(byAdding: .day, value: -(emptyDays - i), to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        // Days in the current month
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthInterval.start)?.count ?? 0
        for i in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: i, to: firstDayOfMonth) {
                days.append(date)
            }
        }

        // Fill out remaining slots
        while days.count % 7 != 0 || days.count < 35 {
            if let lastDate = days.last,
               let nextDay = calendar.date(byAdding: .day, value: 1, to: lastDate) {
                days.append(nextDay)
            } else {
                break
            }
        }
        
        if days.count > 42 {
            days = Array(days.prefix(42))
        }

        return days
    }
}

// NOTE: You will still need your Color extension for Color(hex: "#24BAEC") to work.
