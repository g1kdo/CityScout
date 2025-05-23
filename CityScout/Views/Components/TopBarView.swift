import SwiftUI

struct TopBarView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel

    var body: some View {
        HStack(spacing: 12) {
            // ───────────── Capsule (only avatar + name) ─────────────
            HStack(spacing: 8) {
                if let user = authVM.user {
                    Image("LocalAvatarImage")
                      .resizable()
                      .scaledToFill()
                      .frame(width: 32, height: 32)  // ← avatar size
                      .clipShape(Circle())

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
//        .padding(.top, safeAreaTop() + 5)
    }

//    private func safeAreaTop() -> CGFloat {
//        UIApplication.shared.connectedScenes
//            .compactMap { $0 as? UIWindowScene }
//            .first?
//            .windows.first?
//            .safeAreaInsets.top ?? 0
//    }
}
