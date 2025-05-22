import SwiftUI

/// A bell outline icon with an optional unread badge, centered in a light gray circular background.
struct NotificationBell: View {
    let unreadCount: Int

    var body: some View {
        ZStack {
            // Gray circular background
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 44, height: 44)

            // Outline bell icon centered
            Image(systemName: "bell")
                .font(.system(size: 20))
                .foregroundColor(.black)
        }
        // Place the badge on the top trailing of the ZStack
        .overlay(alignment: .topTrailing) {
            if unreadCount > 0 {
                Text(unreadCount > 99 ? "99+" : "\(unreadCount)")
                    .font(.caption2).bold()
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Circle().fill(Color.red))
                    .offset(x: 8, y: -8)
            }
        }
    }
}



