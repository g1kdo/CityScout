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
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var viewModel = ReviewViewModel()
    @State private var showAddReviewSheet = false
    @State private var reviewToEdit: ReviewViewModel.Review?
    @State private var isShowingEditSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
                    List {
                        // FIX: Add the missing parameters here.
                        ReviewListContent(
                            viewModel: viewModel,
                            authVM: authVM,
                            reviewToEdit: $reviewToEdit,
                            isShowingEditSheet: $isShowingEditSheet
                        )
                    }
                    .listStyle(.plain)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

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
                    .background(Color(hex: "#24BAEC"))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color.white.ignoresSafeArea())
            .sheet(isPresented: $showAddReviewSheet) {
                AddReviewSheet(viewModel: viewModel, reviewToEdit: reviewToEdit)
            }
            .sheet(isPresented: $isShowingEditSheet) {
                if let review = reviewToEdit {
                    AddReviewSheet(viewModel: viewModel, reviewToEdit: review)
                }
            }
            .onAppear {
                viewModel.fetchReviews()
            }
            .navigationTitle("Reviews")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Private Helper View
// This new struct handles the ForEach loop to simplify the main body
private struct ReviewListContent: View {
    @ObservedObject var viewModel: ReviewViewModel
    @ObservedObject var authVM: AuthenticationViewModel
    @Binding var reviewToEdit: ReviewViewModel.Review?
    @Binding var isShowingEditSheet: Bool
    
    var body: some View {
        ForEach(viewModel.reviews) { review in
            ReviewCardView(
                viewModel: viewModel,
                review: review,
                isMyReview: review.authorId == authVM.signedInUser?.id
            )
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(review.authorId == authVM.signedInUser?.id ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            )
            .swipeActions(edge: .leading) {
                if review.authorId == authVM.signedInUser?.id {
                    Button {
                        reviewToEdit = review
                        isShowingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
            .swipeActions(edge: .trailing) {
                if review.authorId == authVM.signedInUser?.id {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteReview(review: review)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                    .tint(.red)
                }
            }
        }
    }
}
