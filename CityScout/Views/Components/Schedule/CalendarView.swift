import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    let events: [ScheduledEvent]

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 1 // 1 = Sunday
        return cal
    }
    
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.callout)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }
            
            let days = generateDays(for: selectedDate)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(days, id: \.self) { date in
                    if calendar.isDate(date, equalTo: selectedDate, toGranularity: .month) {
                        dayView(for: date)
                    } else {
                        Text("").frame(maxWidth: .infinity, maxHeight: .infinity).hidden()
                    }
                }
            }
        }
        .padding(.horizontal)
    }


    @ViewBuilder
    private func dayView(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        
        // 1. New variable to determine the color of the event dot
        let eventColor: Color = hasEventPassed(on: date) ? .gray : Color(hex: "#24BAEC")
        
        VStack(spacing: 4) {
            Text(String(calendar.component(.day, from: date)))
                .font(.title3)
                .fontWeight(isSelected || isToday ? .bold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 40, height: 40)
                .background {
                    if isSelected {
                        Circle().fill(Color(hex: "#FF7029"))
                    } else if isToday {
                        Circle().fill(Color.gray.opacity(0.15))
                    }
                }
                .onTapGesture {
                    selectedDate = date
                }
            
            if hasEvent(on: date) {
                Circle()
                    // 2. Use the dynamic eventColor
                    .fill(eventColor)
                    .frame(width: 5, height: 5)
            } else {
                Circle().fill(Color.clear).frame(width: 5, height: 5)
            }
        }
    }

    private func hasEvent(on date: Date) -> Bool {
        let day = calendar.startOfDay(for: date)
        
        return events.contains { event in
            // Handle cases where startDate might be after endDate (though unlikely in good data)
            guard event.startDate <= event.endDate else { return false }
              
            let eventStartDay = calendar.startOfDay(for: event.startDate)
            // Add one day to the end date to ensure multi-day events show the dot on the last day too
            let eventEndDay = calendar.startOfDay(for: event.endDate)
              
            return day >= eventStartDay && day <= eventEndDay
        }
    }
    
    /// NEW: Checks if a date has events AND if ALL those events are entirely in the past.
    /// It returns true (GRAY dot) if the *latest* end time of any event on that day is before the current moment.
    private func hasEventPassed(on date: Date) -> Bool {
        // First, check if there are any events at all on this day
        let eventsOnDay = events.filter { event in
            let day = calendar.startOfDay(for: date)
            let eventStartDay = calendar.startOfDay(for: event.startDate)
            let eventEndDay = calendar.startOfDay(for: event.endDate)
            return day >= eventStartDay && day <= eventEndDay
        }
        
        guard !eventsOnDay.isEmpty else { return false } // No events, so it hasn't passed (and won't show)
        
        let now = Date()
        
        // Find the LATEST end time of any event on this day
        let latestEndTime = eventsOnDay.compactMap { $0.endDate }.max() ?? date
        
        // The dot should be gray if the latest event for this day has ENDED before 'now'.
        // We use the event's actual end time, not just the end of the calendar day.
        return latestEndTime < now
    }
    

    private func generateDays(for date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthInterval.start)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let emptyDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days: [Date] = []
        if emptyDays > 0 {
            for i in 0..<emptyDays {
                if let date = calendar.date(byAdding: .day, value: -(emptyDays - i), to: firstDayOfMonth) {
                    days.append(date)
                }
            }
        }
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthInterval.start)!.count
        for i in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: i, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        return days
    }
}
