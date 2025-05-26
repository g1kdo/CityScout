//
//  OTPDigitField.swift
//  CityScout
//
//  Created by Umuco Auca on 20/05/2025.
//
import SwiftUI

struct OTPDigitField: View {
    @Binding var text: String

    var body: some View {
        TextField("", text: $text)
            .font(.title2) // Larger font for the digit
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .frame(width: 60, height: 60)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .onChange(of: text) { oldValue, newValue in
                // Ensure only one digit is entered
                if newValue.count > 1 {
                    text = String(newValue.prefix(1))
                }
            }
    }
}
