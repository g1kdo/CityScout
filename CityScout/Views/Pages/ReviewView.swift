import SwiftUI

struct ReviewView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var viewModel = ReviewViewModel(homeViewModel: HomeViewModel())
    @State private var showAddReviewSheet = false
    @State private var reviewToEdit: ReviewViewModel.Review?
    @State private var isShowingEditSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // --- DEFINITIVE FIX IS HERE ---
                // This new logic checks for the initial fetch state.
                // It will show a ProgressView ONLY on the very first load,
                // preventing the "flash" on subsequent views.
                if viewModel.isPerformingInitialFetch {
                    ProgressView("Loading reviews...")
                        .frame(maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else if viewModel.reviews.isEmpty {
                    VStack {
                        Image(systemName: "pencil.and.scribble")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 5)
                        Text("No reviews submitted yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    HStack {
                        Spacer()
                        Picker("Sort By", selection: $viewModel.sortOption) {
                            ForEach(ReviewViewModel.SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.gray)
                        .padding(.trailing, 8)
                    }
                    .padding(.top, 8)

                    List {
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

                // This part of your UI remains the same
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
                .padding(.bottom, 5)
            }
            .background(Color(.systemBackground)).ignoresSafeArea()
            .fullScreenCover(isPresented: $showAddReviewSheet) {
                AddReviewSheet(viewModel: viewModel, reviewToEdit: reviewToEdit)
            }
            .fullScreenCover(isPresented: $isShowingEditSheet) {
                if let review = reviewToEdit {
                    AddReviewSheet(viewModel: viewModel, reviewToEdit: review)
                }
            }
            
            .navigationTitle("Reviews")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct ReviewListContent: View {
    @ObservedObject var viewModel: ReviewViewModel
    @ObservedObject var authVM: AuthenticationViewModel
    @Binding var reviewToEdit: ReviewViewModel.Review?
    @Binding var isShowingEditSheet: Bool
    
    var body: some View {
        ForEach(viewModel.sortedReviews) { review in
            // Find the original review in the main 'reviews' array
            if let index = viewModel.reviews.firstIndex(where: { $0.id == review.id }) {
                ReviewCardView(
                    viewModel: viewModel,
                    review: $viewModel.reviews[index],
                    isMyReview: review.authorId == authVM.signedInUser?.id
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(review.authorId == authVM.signedInUser?.id ? Color.blue.opacity(0.1) : Color(.secondarySystemGroupedBackground))
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
}
