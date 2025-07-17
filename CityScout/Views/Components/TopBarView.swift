import SwiftUI
import Kingfisher // Assuming Kingfisher is available and preferred for image loading

struct TopBarView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel // Already correct

    var body: some View {
        HStack(spacing: 12) {
            // ───────────── Capsule (only avatar + name) ─────────────
            HStack(spacing: 8) {
                if let user = authVM.signedInUser {
                    // Load profile image using KFImage for better caching and placeholder handling
                    // Use the profilePictureAsURL helper property from SignedInUser
                    if let profileImageURL = user.profilePictureAsURL {
                        KFImage(profileImageURL)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
//                            .onFailure { error in
//                                print("Error loading profile image with Kingfisher: \(error.localizedDescription)")
//                            }
                    } else {
                        // Fallback to a default system image if no URL is available
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            .foregroundColor(.gray) // Default color for placeholder
                    }

                    Text(user.displayName ?? "User")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                } else {
                    // Show a progress view or a default placeholder when user data is loading
                    ProgressView()
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)

            Spacer()

            // Assuming NotificationBell is defined elsewhere
            NotificationBell(unreadCount: 0)
        }
        .padding(.horizontal, 20)
    }
}

// Placeholder for NotificationBell if it's not defined in your project
// You should remove this if you have a proper NotificationBell struct
/*
struct NotificationBell: View {
    let unreadCount: Int

    var body: some View {
        Button(action: {
            // Handle notification bell tap
            print("Notification bell tapped!")
        }) {
            ZStack {
                Image(systemName: "bell.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .padding(8)
                    .background(Circle().fill(Color(.systemGray6)).frame(width: 44, height: 44))

                if unreadCount > 0 {
                    Text("\(unreadCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 15, y: -15)
                }
            }
        }
    }
}
*/
