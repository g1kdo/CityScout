// Views/TopBarView.swift
import SwiftUI
import Kingfisher

struct TopBarView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var notificationVM = NotificationViewModel()
    
    @Binding var isShowingMessagesView: Bool
    
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
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(Capsule())
            .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
            
            Spacer()
            
            // ───────────── Message and Notification Icons ─────────────
            HStack(spacing: 16) {
                // NEW: Message icon button
                Button(action: {
                    isShowingMessagesView = true
                }) {
                    Image(systemName: "message")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
                
                // Notification Bell with Button and fullScreenCover
                Button(action: {
                    showingNotifications.toggle()
                }) {
                    NotificationBell(unreadCount: notificationVM.unreadCount)
                        .foregroundColor(.primary)
                }
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
