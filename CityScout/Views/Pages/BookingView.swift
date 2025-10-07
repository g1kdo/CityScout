import SwiftUI

struct BookingView: View {
    let destination: Destination
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject var bookingVM = BookingViewModel(messageVM: MessageViewModel())
    @Environment(\.dismiss) var dismiss

    // The checkInTimeRange logic remains here as a computed property since it's core to the time validation.
    private var checkInTimeRange: ClosedRange<Date> {
        let calendar = Calendar.current
        
        // Use the first available date for time restriction, if any.
        let firstSelectedDate = bookingVM.selectedDates
            .compactMap { calendar.date(from: $0) }
            .min() ?? Date()

        if calendar.isDateInToday(firstSelectedDate) {
            // If the user picked today, the time must be in the future (from now).
            return Date()...calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
        } else {
            // For any future date, allow any time on that day.
            let startOfDay = calendar.startOfDay(for: firstSelectedDate)
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)!
            return startOfDay...endOfDay
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Title Component
                        BookingTitleView(destinationName: destination.name)
                        
                        // 2. Date Selection
                        DateSelectionView(bookingVM: bookingVM)

                        // 3. Time Selection
                        TimeSelectionView(
                            bookingVM: bookingVM,
                            checkInTimeRange: checkInTimeRange
                        )

                        // 4. People Stepper
                        PeopleStepperView(bookingVM: bookingVM)

                    }
                    .padding(.top)
                }
                
                // 5. Confirmation Button (Fixed Footer)
                BookingConfirmationButton(bookingVM: bookingVM, destination: destination, partner: nil)
            }
            .navigationTitle("Booking Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "#FF7029"))
                }
            }
            .alert("Success!", isPresented: $bookingVM.bookingSuccess) {
                Button("OK", role: .cancel) { dismiss() }
            } message: {
                Text("Your trip to \(destination.name) has been confirmed. You can find the details in your schedule.")
            }
            .onAppear {
                bookingVM.calculateTripCost(destination: destination)
            }
            // Use the parameter name syntax for onChange for wider Swift compatibility
            .onChange(of: bookingVM.selectedDates) { _, _ in
                bookingVM.calculateTripCost(destination: destination)
            }
            .onChange(of: bookingVM.numberOfPeople) { _, _ in
                bookingVM.calculateTripCost(destination: destination)
            }
        }
    }
}

/**
 Handles the scrolling title at the top of the booking view.
 */
private struct BookingTitleView: View {
    let destinationName: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text("Book Your Trip to \(destinationName)")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.bottom, 10)
    }
}

/**
 Handles the Date Selection (MultiDatePicker).
 */
private struct DateSelectionView: View {
    @ObservedObject var bookingVM: BookingViewModel // Assuming BookingViewModel is defined externally
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Select Dates")
                .font(.headline)
                .padding(.horizontal)
            
            // Assuming MultiDatePicker is defined elsewhere or imported
            MultiDatePicker("Select Dates", selection: $bookingVM.selectedDates, in: Date()...)
                .datePickerStyle(.graphical)
                .accentColor(Color(hex: "#24BAEC"))
        }
        .padding(.bottom, 10)
    }
}


/**
 Inner component for Check-in and Check-out time pickers.
 */
private struct TimeSelectionView: View {
    @ObservedObject var bookingVM: BookingViewModel // Assuming BookingViewModel is defined externally
    let checkInTimeRange: ClosedRange<Date>
    
    var body: some View {
        HStack {
            // Check-in Time Picker
            VStack(alignment: .leading) {
                Text("Check-in Time")
                    .font(.headline)
                DatePicker("Check-in Time", selection: $bookingVM.checkInTime, in: checkInTimeRange, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }
            Spacer()
            // Check-out Time Picker
            VStack(alignment: .leading) {
                Text("Check-out Time")
                    .font(.headline)
                DatePicker("Check-out Time", selection: $bookingVM.checkOutTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }
        }
        .padding(.horizontal)
    }
}

private struct PeopleStepperView: View {
    @ObservedObject var bookingVM: BookingViewModel // Assuming BookingViewModel is defined externally

    var body: some View {
        VStack(alignment: .leading) {
            Text("Number of People")
                .font(.headline)
            Stepper(value: $bookingVM.numberOfPeople, in: 1...10) {
                Text("\(bookingVM.numberOfPeople) people")
            }
        }
        .padding(.horizontal)
    }
}

private struct BookingConfirmationButton: View {
    // Assuming ViewModels and Destination are defined externally
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var bookingVM: BookingViewModel
    let destination: Destination
    let partner: Partner?
    
    var body: some View {
        VStack {
            // Error Message
            if let errorMessage = bookingVM.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            // Confirm Button
            Button(action: {
                Task {
                    // Assuming AuthenticationViewModel.User has a 'uid'
                    guard let userId = authVM.user?.uid else {
                        bookingVM.errorMessage = "User not logged in."
                        return
                    }
                    await bookingVM.bookDestination(destination: destination, partner: partner, userId: userId)
                }
            }) {
                if bookingVM.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#24BAEC").opacity(0.8))
                        .cornerRadius(12)
                } else {
                    Text("Confirm Booking ($\(bookingVM.totalCost, specifier: "%.2f"))")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#24BAEC"))
                        .cornerRadius(12)
                }
            }
            .disabled(bookingVM.isLoading)
            .padding()
        }
        .background(Color(.systemBackground))
    }
}
