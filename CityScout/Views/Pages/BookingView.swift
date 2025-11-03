import SwiftUI

struct BookingView: View {
    let destination: Destination
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject var bookingVM = BookingViewModel(messageVM: MessageViewModel())
    @Environment(\.dismiss) var dismiss

    private var checkInTimeRange: ClosedRange<Date> {
        let calendar = Calendar.current
        
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


private struct BookingTitleView: View {
    let destinationName: String
    
    // 1. Unique IDs for ScrollViewReader control
    private let textStartID = 0
    private let duplicatedTextID = 1
    
    @State private var isScrolling = false
    
    // 2. The combined string to ensure spacing between copies
    private var fullMarqueeText: String {
        // Use a wide separator of spaces to ensure a gap between loops
        let separator = String(repeating: " ", count: 10)
        return "Book Your Trip to \(destinationName)" + separator
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                // Use an HStack to hold the duplicated content side-by-side
                HStack(spacing: 0) {
                    // --- First Copy (Target ID: 0) ---
                    Text(fullMarqueeText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .id(textStartID) // The start of the loop
                    
                    // --- Second Copy (Target ID: 1) ---
                    Text(fullMarqueeText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .id(duplicatedTextID) // The target for the initial scroll/jump
                }
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal) // Add horizontal padding for a clean look
            }
            .padding(.bottom, 10)
            .onAppear {
                startMarqueeAnimation(proxy: proxy)
            }
        }
    }
    
    // 3. The Continuous Marquee Animation Logic
    private func startMarqueeAnimation(proxy: ScrollViewProxy) {
        guard destinationName.count > 15 else { return }

        // Start the scrolling task
        Task {
            // Calculate the time it takes to scroll one text copy (e.g., 5 seconds per copy)
            let scrollDuration: Double = Double(destinationName.count) * 0.3 // ~3.0-5.0 seconds total scroll

            // The loop runs indefinitely
            while true {
                // 1. Scroll the content to the start of the duplicated text (ID 1)
                // This scrolls the first copy entirely out of view.
                withAnimation(.linear(duration: scrollDuration)) {
                    proxy.scrollTo(duplicatedTextID, anchor: .leading)
                }

                // Wait for the animation to complete
                try? await Task.sleep(for: .seconds(scrollDuration))

                // 2. Instantly and silently jump back to the start position (ID 0)
                // This must be done without animation to prevent a visual flicker.
                proxy.scrollTo(textStartID, anchor: .leading)
                
                // The loop immediately starts the scroll from step 1 again.
            }
        }
    }
}


private struct DateSelectionView: View {
    @ObservedObject var bookingVM: BookingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Dates")
                .font(.headline)
                .padding(.horizontal)

            MultiDatePicker("Select Dates", selection: $bookingVM.selectedDates, in: Date()...)
                .datePickerStyle(.graphical)
                .accentColor(Color(hex: "#24BAEC"))
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Stretch container
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}


private struct TimeSelectionView: View {
    @ObservedObject var bookingVM: BookingViewModel
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
    @ObservedObject var bookingVM: BookingViewModel

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
                    
                    guard let userId = authVM.user?.uid else {
                        bookingVM.errorMessage = "User not logged in."
                        return
                    }
                    await bookingVM.bookDestination(destination: destination, userId: userId)
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
