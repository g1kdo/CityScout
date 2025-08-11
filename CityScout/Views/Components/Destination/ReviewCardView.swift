import SwiftUI
import Kingfisher

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
}()

struct ReviewCardView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var viewModel: ReviewViewModel
    let review: ReviewViewModel.Review
    let isMyReview: Bool
    
    @State private var myReaction: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            HStack(alignment: .top) {
                KFImage(review.authorProfilePictureURL)
                    .placeholder {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.secondary)
                    }
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(review.authorDisplayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(review.destinationName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < review.rating ? "star.fill" : "star")
                            .foregroundColor(index < review.rating ? .yellow : .secondary)
                            .font(.caption)
                    }
                    Text("\(review.rating)/5")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(review.comment)
                .font(.body)
                .foregroundColor(.primary) // Changed to primary for better readability
                .lineLimit(nil)
            
            HStack {
                Text("Reviewed on \(review.timestamp, formatter: itemFormatter)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
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
        // --- CHANGE IS HERE ---
        // Using a more standard adaptive background color
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 3)
        .onAppear {
            if let userId = authVM.signedInUser?.id {
                myReaction = review.reactedUsers[userId]
            }
        }
        .onChange(of: review.reactedUsers) { _, _ in
            if let userId = authVM.signedInUser?.id {
                myReaction = review.reactedUsers[userId]
            }
        }
    }
}
