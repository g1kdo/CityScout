// Views/TopBarView.swift
import SwiftUI
import Kingfisher

struct TopBarView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var notificationVM = NotificationViewModel()
    
    // State variable to control the presentation of the fullScreenCover
    @State private var showingNotifications = false
    
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
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            .foregroundColor(.gray)
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
            
            // ───────────── Notification Bell with Button and fullScreenCover ─────────────
            Button(action: {
                // Toggle the state to show the fullScreenCover
                showingNotifications.toggle()
            }) {
                NotificationBell(unreadCount: notificationVM.unreadCount)
            }
        }
        .padding(.horizontal, 20)
        .onAppear {
            notificationVM.fetchNotifications()
        }
        .fullScreenCover(isPresented: $showingNotifications) {
            // The view to present as a fullScreenCover
            NotificationView()
                .environmentObject(notificationVM)
        }
    }
}
