import SwiftUI
import Kingfisher

struct TopBarView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel

    var body: some View {
        HStack(spacing: 12) {
            // ───────────── Capsule (only avatar + name) ─────────────
            HStack(spacing: 8) {
                if let user = authVM.signedInUser {
                    if let profileImageURL = user.profilePictureAsURL {
                        KFImage(profileImageURL)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
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
