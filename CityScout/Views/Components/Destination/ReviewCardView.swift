//
//  ReviewCardView.swift
//  CityScout
//
//  Created by Umuco Auca on 29/07/2025.
//


// Views/ReviewCardView.swift
import SwiftUI
import Kingfisher // Import Kingfisher for image loading and caching

// Date Formatter (keep as is)
private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
}()

struct ReviewCardView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var viewModel: ReviewViewModel // Pass the ViewModel to perform actions
    let review: ReviewViewModel.Review
    let isMyReview: Bool
    
    // State to hold the current user's reaction
    @State private var myReaction: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) { // Main VStack from old design
            
            // Top section: Profile Pic, Author Name, Destination Name, Rating
            HStack(alignment: .top) {
                // User profile image (from new design, using Kingfisher)
                if let profileURL = review.authorProfilePictureURL {
                    KFImage(profileURL) // Use KFImage for caching
                        .placeholder {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.gray)
                        }
                        .resizable()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Author Display Name
                    Text(review.authorDisplayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Destination Name (from old design)
                    Text(review.destinationName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer() // Pushes rating to the right
                
                // Star rating display (combined from old and new)
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < review.rating ? "star.fill" : "star")
                            .foregroundColor(index < review.rating ? .yellow : .gray)
                            .font(.caption)
                    }
                    Text("\(review.rating)/5") // Rating text from old design
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Review Comment
            Text(review.comment)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(nil) // Allow multiple lines
            
            // Bottom section: Timestamp and Reactions
            HStack {
                Text("Reviewed on \(review.timestamp, formatter: itemFormatter)")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Reaction buttons (from new design, only if not my review)
                if !isMyReview {
                    HStack(spacing: 20) {
                        // Agree button
                        Button {
                            Task {
                                guard let userId = authVM.signedInUser?.id else { return }
                                await viewModel.reactToReview(review: review, userId: userId, reaction: "agree")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: myReaction == "agree" ? "hand.thumbsup.fill" : "hand.thumbsup")
                                    .foregroundColor(myReaction == "agree" ? .green : .secondary)
                                Text("\(review.agrees)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Disagree button
                        Button {
                            Task {
                                guard let userId = authVM.signedInUser?.id else { return }
                                await viewModel.reactToReview(review: review, userId: userId, reaction: "disagree")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: myReaction == "disagree" ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                    .foregroundColor(myReaction == "disagree" ? .red : .secondary)
                                Text("\(review.disagrees)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding()
        // Apply old background, but use isMyReview for a slight tint
        .background(isMyReview ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3) // Old shadow
        .onAppear {
            if let userId = authVM.signedInUser?.id {
                myReaction = review.reactedUsers[userId]
            }
        }
        .onChange(of: review.reactedUsers) { oldValue, _ in
            if let userId = authVM.signedInUser?.id {
                myReaction = review.reactedUsers[userId]
            }
        }
    }
}
