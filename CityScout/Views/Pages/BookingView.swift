import SwiftUI

struct BookingView: View {
    let destination: Destination
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject var bookingVM = BookingViewModel()
    @Environment(\.dismiss) var dismiss

    // --- NEW LOGIC: DYNAMIC TIME RANGE ---
    // This computed property determines the valid time range for the check-in picker.
    private var checkInTimeRange: ClosedRange<Date> {
        let calendar = Calendar.current
        // Get the earliest selected date, if any.
        let firstSelectedDate = bookingVM.selectedDates
            .compactMap { calendar.date(from: $0) }
            .min() ?? Date()

        // If the selected date is today, the time must be in the future.
        if calendar.isDateInToday(firstSelectedDate) {
            // The range starts from now until the end of the day.
            return Date()...calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
        } else {
            // For any future date, allow any time to be selected.
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
                        // --- NEW UI: SCROLLING "TRAIL OF WORDS" TITLE ---
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text("Book Your Trip to \(destination.name)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal) // Add padding so it doesn't touch the edges
                                .fixedSize(horizontal: true, vertical: false) // Prevents text from wrapping
                        }
                        .padding(.bottom, 10)

                        VStack(alignment: .leading) {
                            Text("Select Dates")
                                .font(.headline)
                                .padding(.horizontal)
                            MultiDatePicker("Select Dates", selection: $bookingVM.selectedDates, in: Date()...)
                                .datePickerStyle(.graphical)
                                .accentColor(Color(hex: "#24BAEC"))
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Check-in Time")
                                    .font(.headline)
                                // The DatePicker now uses the dynamic time range.
                                DatePicker("Check-in Time", selection: $bookingVM.checkInTime, in: checkInTimeRange, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Check-out Time")
                                    .font(.headline)
                                DatePicker("Check-out Time", selection: $bookingVM.checkOutTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading) {
                            Text("Number of People")
                                .font(.headline)
                            Stepper(value: $bookingVM.numberOfPeople, in: 1...10) {
                                Text("\(bookingVM.numberOfPeople) people")
                            }
                        }
                        .padding(.horizontal)

                    }
                    .padding(.top)
                }

                VStack {
                    if let errorMessage = bookingVM.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }

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
            .navigationTitle("Booking Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "#FF7029"))
                }
            }
            .alert("Success!", isPresented: $bookingVM.bookingSuccess) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Your trip to \(destination.name) has been confirmed. You can find the details in your schedule.")
            }
            .onAppear {
                bookingVM.calculateTripCost(destination: destination)
            }
            .onChange(of: bookingVM.selectedDates) { _, _ in
                bookingVM.calculateTripCost(destination: destination)
            }
            .onChange(of: bookingVM.numberOfPeople) { _, _ in
                bookingVM.calculateTripCost(destination: destination)
            }
        }
    }
}
