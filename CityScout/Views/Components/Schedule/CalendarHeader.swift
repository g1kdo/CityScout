import SwiftUI

struct CalendarHeader: View {
    @Binding var selectedDate: Date
    private let calendar = Calendar.current
    private let monthAndYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy" // Format to show month and year
        return formatter
    }()

    var body: some View {
        HStack {
            // Display the current month and year
            Text(monthAndYearFormatter.string(from: selectedDate))
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()

            // Button to go to the previous month
            Button(action: {
                changeMonth(by: -1)
            }) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
            
            // Button to go to the next month
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
    }
    
    // Logic to change the month of the selectedDate
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }
}
