//
//  OTPVerificationView.swift
//  CityScout
//
//  Created by Umuco Auca on 20/05/2025.
//
import SwiftUI

struct OTPVerificationView: View {
    @State private var otpDigits: [String] = Array(repeating: "", count: 4)
    @FocusState private var focusedField: Int? // To manage focus on OTP fields
    @State private var timerText: String = "01:26"

    var body: some View {
        NavigationView { // Added NavigationView for the back button
            VStack(spacing: 25) { // Increased spacing
                HStack {
                    Button(action: {
                        // Action to go back or dismiss
                        print("Back button tapped in OTP Verification")
                        // In a real app, you'd dismiss this view or pop navigation stack
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                Text("OTP Verification")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 5)

                Text("Please check your email \nto see the verification code")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                // OTP Code Label
                HStack {
                    Text("OTP Code")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 5)

                // OTP Digit Fields
                HStack(spacing: 40) { // Spacing between OTP boxes
                    ForEach(0..<4, id: \.self) { index in
                        OTPDigitField(text: $otpDigits[index])
                            .frame(width: 60, height: 60) // Fixed size for the boxes
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(focusedField == index ? Color.blue : Color.clear, lineWidth: 2) // Highlight focused field
                            )
                            .keyboardType(.numberPad)
                            .onChange(of: otpDigits[index]) { newValue in
                                if newValue.count > 1 {
                                    otpDigits[index] = String(newValue.prefix(1)) // Ensure only one digit
                                }
                                if newValue.count == 1 {
                                    if index < otpDigits.count - 1 {
                                        focusedField = index + 1 // Move focus to next field
                                    } else {
                                        focusedField = nil // All fields filled, dismiss keyboard
                                    }
                                } else if newValue.isEmpty {
                                    if index > 0 {
                                        focusedField = index - 1 // Move focus to previous field on backspace
                                    }
                                }
                            }
                            .focused($focusedField, equals: index)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30) // Space before button

                PrimaryButton(title: "Verify") {
                    let enteredOTP = otpDigits.joined()
                    print("OTP entered: \(enteredOTP)")
                    // Implement OTP verification logic
                }
                .padding(.horizontal)

                HStack {
                    Text("Resend code to")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(timerText) // Display the timer
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "#24BAEC")) // Blue color for timer
                }
                .padding(.horizontal)
                .padding(.top, 20) // Space from button

                Spacer()
            }
            .navigationBarHidden(true) // Hide default navigation bar
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


#Preview {
    OTPVerificationView()
}
