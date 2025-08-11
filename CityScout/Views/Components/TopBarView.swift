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
                    KFImage(user.profilePictureAsURL)
                        .placeholder {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                                .foregroundColor(.secondary) // Use adaptive color
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
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
            // --- CHANGE IS HERE ---
            // Replaced Color(.systemGray6) with a more distinct secondary background
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(Capsule())
            .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2) // Use adaptive shadow
            
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
