//
//  ForgotPasswordView.swift
//  CityScout
//
//  Created by Umuco Auca on 20/05/2025.
//


import SwiftUI

// MARK: - Forgot Password View

struct ForgotPasswordView: View {
    @State private var email: String = ""
    @State private var showCheckEmailState: Bool = false

    var body: some View {
        NavigationView { // Added NavigationView for the back button
            VStack(spacing: 25) { // Increased spacing for visual separation
                // Back button (only shown in check email state)
                if showCheckEmailState {
                    HStack {
                        Button(action: {
                            // Action to go back or dismiss
                            showCheckEmailState = false // For example, go back to initial form
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.black)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                } else {
                    // Placeholder for alignment if no back button
                    Spacer().frame(height: 44) // Approximate height of a nav bar item
                }


                Text("Forgot password")
                    .font(.largeTitle)
                    .fontWeight(.bold) // Exact replica has bold title
                    .padding(.bottom, 5) // Reduced padding as per screenshot

                Text("Enter your email account to reset\nyour password") // Newline for exact replica
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40) // Constrain width

                Spacer() // Pushes content towards center

                if showCheckEmailState {
                    // Check your email state UI
                    Image(systemName: "envelope.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80) // Adjusted size for visual match
                        .foregroundColor(.white)
                        .padding(20)
                        .background(Color(hex: "#FF8C42")) // Orange color from screenshot
                        .cornerRadius(40) // Half of width/height for perfect circle
                        .padding(.bottom, 20)

                    Text("Check your email")
                        .font(.title2) // Slightly smaller than largeTitle but prominent
                        .fontWeight(.bold)
                        .padding(.bottom, 5)

                    Text("We have sent the password\nrecovery instructions to your email")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    // The email field in this state is not a button but a display
                    FloatingField(label: "Email Address", placeholder: "example@cityscout.com", text: .constant("example@cityscout.com"))
                        .padding(.horizontal)
                        .padding(.top, 20) // Spacing from text above
                        .padding(.bottom, 50) // Space before the very bottom if other elements were there

                } else {
                    // Initial form state UI
                    FloatingField(label: "Email Address", placeholder: "example@cityscout.com", text: $email, keyboardType: .emailAddress)
                        .padding(.horizontal) // Apply horizontal padding to the field
                        .padding(.bottom, 30) // More space before button

                    PrimaryButton(title: "Reset Password") {
                        // Simulate sending email and transition to the check email state
                        email = "www.uihut@gmail.com" // Update email for the next state
                        showCheckEmailState = true
                        print("Reset password button tapped, transitioning to check email state.")
                    }
                    .padding(.horizontal) // Apply horizontal padding to the button
                }

                Spacer() // Pushes content towards center
            }
            .navigationBarHidden(true) // Hide default navigation bar to use custom back button
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ForgotPasswordView()
}
