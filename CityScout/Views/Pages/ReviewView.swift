//
//  ReviewView.swift
//  CityScout
//
//  Created by Umuco Auca on 29/07/2025.
//


// Views/ReviewView.swift
import SwiftUI

struct ReviewView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel // If needed for user context
    @StateObject private var viewModel = ReviewViewModel()
    @State private var showAddReviewSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header (similar to EditProfileView or HomeView's top bar)
                HStack {
                    Spacer()
                    Text("Your Reviews")
                        .font(.title2.bold())
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 20) // Spacing from content

                // Add New Review Button
                Button {
                    showAddReviewSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Write a New Review")
                    }
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#24BAEC")) // Consistent blue accent color
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)

                if viewModel.isLoading {
                    ProgressView("Loading reviews...")
                        .padding()
                } else if let error = viewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else if viewModel.reviews.isEmpty {
                    VStack {
                        Image(systemName: "pencil.and.scribble")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                            .padding(.bottom, 5)
                        Text("No reviews submitted yet.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 50)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(viewModel.reviews) { review in
                                ReviewCardView(review: review)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20) // Padding for scrollable content
                    }
                }
            }
            .background(Color.white.ignoresSafeArea())
            .sheet(isPresented: $showAddReviewSheet) {
                // Present a sheet for adding a new review
                // You'll need a Destination model to pass if you want to select a specific place
                // For simplicity, let's just make a placeholder for selecting a destination
                // In a real app, this might navigate to a specific destination detail to review it.
                AddReviewSheet(viewModel: viewModel)
            }
            .onAppear {
                // Optionally refresh reviews when view appears
                viewModel.loadPlaceholderReviews()
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
}()
