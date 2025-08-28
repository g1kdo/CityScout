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
                    .fill(Color(hex: "#24BAEC"))
                    .frame(width: 5, height: 5)
            } else {
                Circle().fill(Color.clear).frame(width: 5, height: 5)
            }
        }
    }
    
    // --- CORRECTED LOGIC ---
    // This function now correctly checks if a calendar day falls within
    // the start and end day of ANY event, including multi-day and past events.
    private func hasEvent(on date: Date) -> Bool {
        let day = calendar.startOfDay(for: date)
        
        return events.contains { event in
            guard event.startDate <= event.endDate else { return false }
            
            let eventStartDay = calendar.startOfDay(for: event.startDate)
            let eventEndDay = calendar.startOfDay(for: event.endDate)
            
            return day >= eventStartDay && day <= eventEndDay
        }
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
