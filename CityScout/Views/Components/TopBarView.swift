import SwiftUI

struct TopBarView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel // Already correct

    var body: some View {
        HStack(spacing: 12) {
            // ───────────── Capsule (only avatar + name) ─────────────
            HStack(spacing: 8) {
                if let user = authVM.signedInUser {
                    // Load profile image from URL if available, otherwise use default
                    if let profileImageURL = user.profilePictureURL {
                        AsyncImage(url: profileImageURL) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        } placeholder: {
                            ProgressView()
                                .frame(width: 32, height: 32)
                        }
                    } else {
                        Image("LocalAvatarImage")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    }

                    Text(user.displayName ?? "User")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                } else {
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

            NotificationBell(unreadCount: 0)
        }
        .padding(.horizontal, 20)
    }
}
