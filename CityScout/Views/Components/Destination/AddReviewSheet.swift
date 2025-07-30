//
//  AddReviewSheet.swift
//  CityScout
//
//  Created by Umuco Auca on 29/07/2025.
//


// Views/AddReviewSheet.swift
import SwiftUI

struct AddReviewSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var viewModel: ReviewViewModel
    
    let reviewToEdit: ReviewViewModel.Review?
    
    @State private var selectedDestinationName: String = ""
    @State private var reviewComment: String = ""
    @State private var starRating: Int = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""

    private var isEditMode: Bool {
        reviewToEdit != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text(isEditMode ? "Edit Your Review" : "Add Your Review")
                        .font(.title2.bold())
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading) {
                        Text("Destination Name")
                            .font(.subheadline.bold())
                        TextField("e.g., Lake Kivu", text: $selectedDestinationName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(isEditMode)
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
                            .disableAutocorrection(false)
                    }
                    
                    Button {
                        Task {
                            guard let currentUser = authVM.signedInUser,
                                  let authorId = currentUser.id else {
                                alertMessage = "You must be logged in to submit a review."
                                showingAlert = true
                                return
                            }
                            
                            if selectedDestinationName.isEmpty || reviewComment.isEmpty || starRating == 0 {
                                alertMessage = "Please fill in all fields and provide a rating."
                                showingAlert = true
                                return
                            }
                            
                            var success = false
                            if isEditMode, let review = reviewToEdit {
                                success = await viewModel.editReview(review: review, newComment: reviewComment, newRating: starRating)
                            } else {
                                success = await viewModel.addReview(
                                    destinationId: UUID().uuidString,
                                    destinationName: selectedDestinationName,
                                    rating: starRating,
                                    comment: reviewComment,
                                    authorId: authorId,
                                    authorDisplayName: currentUser.displayName ?? "Anonymous",
                                    // CORRECTED LINE: Use the computed property
                                    authorProfilePictureURL: currentUser.profilePictureAsURL
                                )
                            }
                            
                            if success {
                                dismiss()
                            } else {
                                alertMessage = viewModel.errorMessage ?? "Failed to submit review."
                                showingAlert = true
                            }
                        }
                    } label: {
                        Group {
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text(isEditMode ? "Update Review" : "Submit Review")
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
            .onAppear {
                if isEditMode, let review = reviewToEdit {
                    self.selectedDestinationName = review.destinationName
                    self.reviewComment = review.comment
                    self.starRating = review.rating
                }
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
