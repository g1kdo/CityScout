//
//  ReviewCardView.swift
//  CityScout
//
//  Created by Umuco Auca on 29/07/2025.
//


// Views/ReviewView.swift (within the same file as ReviewView or its own)
import SwiftUI
// A simple card to display an individual review
struct ReviewCardView: View {
    let review: ReviewViewModel.Review

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(review.destinationName)
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 2) {
                ForEach(0..<5) { index in
                    Image(systemName: index < review.rating ? "star.fill" : "star")
                        .foregroundColor(index < review.rating ? .yellow : .gray)
                        .font(.caption)
                }
                Text("\(review.rating)/5")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Text(review.comment)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(nil) // Allow multiple lines

            HStack {
                Text("by \(review.authorId)") // Display the author's name
                    .font(.caption2.bold()) // Make it slightly bolder
                    .foregroundColor(.gray)
                Spacer()
                Text("Reviewed on \(review.timestamp, formatter: itemFormatter)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
    }
}

// Date Formatter (keep as is)
private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
}()
