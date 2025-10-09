//
//  AddReviewSheet.swift
//  CityScout
//
//  Created by Umuco Auca on 29/07/2025.
//


import SwiftUI

struct AddReviewSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var viewModel: ReviewViewModel // Make sure this is @ObservedObject

    let reviewToEdit: ReviewViewModel.Review?
    
    @State private var selectedDestinationName: String = ""
    @State private var selectedDestinationId: String? // New state for selected destination ID
    @State private var reviewComment: String = ""
    @State private var starRating: Int = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showDestinationSuggestions: Bool = false // To control suggestion list visibility

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
                            .disabled(isEditMode) // Disable if in edit mode
                            .onChange(of: selectedDestinationName) { newValue in
                                if !isEditMode { // Only fetch suggestions if not in edit mode
                                    viewModel.fetchDestinationSuggestions(query: newValue)
                                    showDestinationSuggestions = !newValue.isEmpty
                                    // Reset selectedDestinationId if text changes
                                    selectedDestinationId = nil
                                }
                            }
                        
                        if showDestinationSuggestions && !isEditMode {
                            if viewModel.isSearchingDestinations {
                                ProgressView()
                                    .padding(.vertical, 5)
                            } else if let error = viewModel.destinationSearchError {
                                Text("Error: \(error)")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            } else if viewModel.destinationSuggestions.isEmpty && !selectedDestinationName.isEmpty {
                                Text("No matching destinations found. You can only review existing destinations.")
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.vertical, 5)
                            } else {
                                List {
                                    ForEach(viewModel.destinationSuggestions) { destination in
                                        Text(destination.name)
                                            .onTapGesture {
                                                self.selectedDestinationName = destination.name
                                                self.selectedDestinationId = destination.id
                                                self.showDestinationSuggestions = false // Hide suggestions after selection
                                            }
                                    }
                                }
                                .frame(height: min(CGFloat(viewModel.destinationSuggestions.count) * 44, 200)) // Limit height
                                .listStyle(.plain)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
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
                            
                            // For new reviews, ensure a destination has been selected from suggestions
                            if !isEditMode && selectedDestinationId == nil {
                                alertMessage = "Please select an existing destination from the suggestions."
                                showingAlert = true
                                return
                            }
                            
                            var success = false
                            if isEditMode, let review = reviewToEdit {
                                success = await viewModel.editReview(review: review, newComment: reviewComment, newRating: starRating)
                            } else {
                                // Use the selectedDestinationId for new reviews
                                guard let destId = selectedDestinationId else {
                                    alertMessage = "No destination ID found. Please select a destination from the list."
                                    showingAlert = true
                                    return
                                }
                                success = await viewModel.addReview(
                                    destinationId: destId, // Use the dynamically selected ID
                                    destinationName: selectedDestinationName,
                                    rating: starRating,
                                    comment: reviewComment,
                                    authorId: authorId,
                                    authorDisplayName: currentUser.displayName ?? "Anonymous",
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
                    .disabled(viewModel.isLoading || (!isEditMode && selectedDestinationId == nil && !selectedDestinationName.isEmpty)) // Disable if loading or no valid dest selected for new review
                    .opacity(viewModel.isLoading || (!isEditMode && selectedDestinationId == nil && !selectedDestinationName.isEmpty) ? 0.6 : 1.0)
                }
                .padding()
            }
            .onAppear {
                if isEditMode, let review = reviewToEdit {
                    self.selectedDestinationName = review.destinationName
                    self.selectedDestinationId = review.destinationId // Initialize ID for edit mode
                    self.reviewComment = review.comment
                    self.starRating = review.rating
                } else {
                    // Clear states for new review if sheet is reused
                    self.selectedDestinationName = ""
                    self.selectedDestinationId = nil
                    self.reviewComment = ""
                    self.starRating = 0
                }
            }
            .alert("Submission Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                                  
                                   Button("Cancel") { dismiss() }
                                       .foregroundColor(Color(hex: "#FF7029"))
                               }
            }
        }
    }
}
