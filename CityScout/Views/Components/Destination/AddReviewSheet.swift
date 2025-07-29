//
//  AddReviewSheet.swift
//  CityScout
//
//  Created by Umuco Auca on 29/07/2025.
//


// Views/ReviewView.swift (within the same file as ReviewView or its own)
import SwiftUI
// Sheet for adding a new review
struct AddReviewSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel // Added to access signed-in user
    @ObservedObject var viewModel: ReviewViewModel

    @State private var selectedDestinationName: String = ""
    @State private var reviewComment: String = ""
    @State private var starRating: Int = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Add Your Review")
                        .font(.title2.bold())
                        .padding(.top, 20)

                    VStack(alignment: .leading) {
                        Text("Destination Name")
                            .font(.subheadline.bold())
                        TextField("e.g., Lake Kivu", text: $selectedDestinationName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    VStack(alignment: .leading) {
                        Text("Your Rating")
                            .font(.subheadline.bold())
                        HStack {
                            ForEach(0..<5) { index in
                                Image(systemName: index < starRating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                                    .onTapGesture {
                                        starRating = index + 1
                                    }
                            }
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Your Comment")
                            .font(.subheadline.bold())
                        TextEditor(text: $reviewComment)
                            .frame(height: 150)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .padding(1)
                    }

                    Button {
                        Task {
                            guard let currentUser = authVM.signedInUser else {
                                alertMessage = "You must be logged in to submit a review."
                                showingAlert = true
                                return
                            }
                            guard let authorId = currentUser.id else {
                                alertMessage = "Your user ID could not be found."
                                showingAlert = true
                                return
                            }
                            let authorName = currentUser.displayName ?? "Anonymous User" // Use display name, or fallback

                            if selectedDestinationName.isEmpty || reviewComment.isEmpty || starRating == 0 {
                                alertMessage = "Please fill in all fields and provide a rating."
                                showingAlert = true
                            } else {
                                let success = await viewModel.submitReview(
                                    destinationId: UUID().uuidString,
                                    destinationName: selectedDestinationName,
                                    rating: starRating,
                                    comment: reviewComment
                                //    authorId: authorId    // Pass current user's ID
                                //    authorName: authorName    // Pass current user's display name
                                )
                                if success {
                                    dismiss()
                                } else {
                                    alertMessage = viewModel.errorMessage ?? "Failed to submit review."
                                    showingAlert = true
                                }
                            }
                        }
                    } label: {
                        Group {
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text("Submit Review")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#FF7029"))
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isLoading)
                    .opacity(viewModel.isLoading ? 0.6 : 1.0)
                }
                .padding()
            }
            .alert("Submission Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
