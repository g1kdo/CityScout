struct CalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentDate: Date = Date() // Used to display the current month

    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
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
                        DayCell(date: date, isSelected: calendar.isDate(date, inSameDayAs: selectedDate)) {
                            selectedDate = date
                        }
                    } else {
                        Text("") // Empty cell for days outside the current month
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
        let numberOfLeadingBlanks = (weekdayOfFirstDay - calendar.firstWeekday + 7) % 7
        for _ in 0..<numberOfLeadingBlanks {
            dates.append(Date.distantPast) // Placeholder for empty cells
        }

        // Add days of the month
        calendar.enumerateDates(in: monthInterval, for: .day) { date, _, stop in
            if let date = date {
                dates.append(date)
            }
        }
        return dates
    }

    private func changeMonth(by months: Int) {
        if let newDate = calendar.date(byAdding: .month, value: months, to: currentDate) {
            currentDate = newDate
        }
    }
}