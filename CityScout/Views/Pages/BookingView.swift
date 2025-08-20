//
//  BookingView.swift
//  CityScout
//
//  Created by Umuco Auca on 30/07/2025.
//


// Views/Components/BookingView.swift
import SwiftUI

struct BookingView: View {
    let destination: Destination
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var bookingVM: BookingViewModel // Injected from DestinationDetailView
    @Environment(\.dismiss) var dismiss // To dismiss the sheet

    var body: some View {
        NavigationView { // Use NavigationView for the title and dismiss button
            VStack(spacing: 20) {
                Text("Book Your Trip to \(destination.name)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)

                // Date Selection
                VStack(alignment: .leading) {
                    Text("Select Date")
                        .font(.headline)
                    DatePicker(
                        "Date",
                        selection: $bookingVM.selectedDate,
                        in: Date()..., // Allow only future dates
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical) // Modern calendar style
                    .accentColor(Color(hex: "#24BAEC")) // Accent color for the calendar
                }

                // Time Selection
                VStack(alignment: .leading) {
                    Text("Select Time")
                        .font(.headline)
                    DatePicker(
                        "Time",
                        selection: $bookingVM.selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact) // Compact style for time
                }
                .padding(.horizontal)

                // Number of People
                VStack(alignment: .leading) {
                    Text("Number of People")
                        .font(.headline)
                    Stepper(value: $bookingVM.numberOfPeople, in: 1...10) { // Limit to 10 people for now
                        Text("\(bookingVM.numberOfPeople) people")
                    }
                }
                .padding(.horizontal)


                Spacer()

                // Booking Button
                Button(action: {
                    Task {
                        // Ensure userId is available before booking
                        guard let userId = authVM.user?.uid else {
                            bookingVM.errorMessage = "User not logged in."
                            return
                        }
                        await bookingVM.bookDestination(destination: destination, userId: userId)
                        if bookingVM.bookingSuccess {
                            dismiss() // Dismiss on successful booking
                        }
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
                        Text("Confirm Booking ($\(destination.price * Double(bookingVM.numberOfPeople), specifier: "%.2f"))") // Assuming price is on Destination
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#24BAEC"))
                            .cornerRadius(12)
                    }
                }
                .disabled(bookingVM.isLoading) // Disable button while loading

                // Error Message
                if let errorMessage = bookingVM.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding()
            .navigationTitle("Booking Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                                  
                                   Button("Cancel") { dismiss() }
                                       .foregroundColor(Color(hex: "#FF7029"))
                               }            }
        }
    }
}
