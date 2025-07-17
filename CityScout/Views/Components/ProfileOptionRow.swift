//
//  ProfileOptionRow.swift
//  CityScout
//
//  Created by Umuco Auca on 17/07/2025.
//
import SwiftUI

struct ProfileOptionRow: View {
    let icon: String // System icon name (e.g., "person", "gear")
    let title: String // Title for the option
    var showChevron: Bool = true // Controls visibility of the chevron icon
    let action: () -> Void // Closure to execute when the row is tapped

    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                // Icon
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor) // Use accent color for consistency
                    .frame(width: 30, height: 30) // Fixed size for icon
                    .background(Color.accentColor.opacity(0.1)) // Light background for icon
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Title
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                // Chevron icon (optional)
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
            .background(Color(.systemBackground)) // Background for the row
            .cornerRadius(12) // Rounded corners for the row
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2) // Subtle shadow
        }
    }
}
