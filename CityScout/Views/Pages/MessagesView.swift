//
//  MessagesView.swift
//  CityScout
//
//  Created by Umuco Auca on 20/09/2025.
//

import SwiftUI
import Kingfisher

struct MessagesView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var messageVM: MessageViewModel
    @EnvironmentObject var homeVM: HomeViewModel

    @State private var searchText: String = ""
    @State private var isShowingChatView: Bool = false
    @State private var selectedChat: Chat?
    @State private var isFindingNewChatPartner: Bool = false

    var filteredChats: [Chat] {
        if searchText.isEmpty {
            return messageVM.chats
        } else {
            return messageVM.chats.filter { chat in
                (chat.partnerDisplayName ?? "").localizedCaseInsensitiveContains(searchText) ||
                (chat.lastMessage?.text ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 15) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .background(Circle().fill(Color(.systemGray6)).frame(width: 40, height: 40))
                    }
                    Spacer()

                    Text("Messages")
                        .font(.headline)
                        .fontWeight(.bold)

                    Spacer()

                    Button(action: {
                        self.isFindingNewChatPartner = true
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)

                SearchBarView(searchText: $searchText, placeholder: "Search for chats & messages", isMicrophoneActive: homeVM.isListeningToSpeech) {
                    // Action on search tapped
                } onMicrophoneTapped: {
                    homeVM.handleMicrophoneTapped()
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 15)
            .background(Color(.secondarySystemGroupedBackground))

            ScrollView {
                LazyVStack(spacing: 0) {
                    if messageVM.isLoading {
                        ProgressView("Loading chats...")
                            .padding()
                    } else if let errorMessage = messageVM.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    } else if filteredChats.isEmpty && !searchText.isEmpty {
                        Text("No chats found for \"\(searchText)\"")
                            .foregroundColor(.secondary)
                            .padding()
                    } else if filteredChats.isEmpty {
                        Text("You have no active chats.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(filteredChats) { chat in
                                                   VStack(spacing: 0) { // Wrap ChatRow and Divider in a VStack
                                                       ChatRow(chat: chat)
                                                           .onTapGesture {
                                                               self.selectedChat = chat
                                                               self.isShowingChatView = true
                                                           }
                                                       
                                                       // Aesthetic and Subtle Line (Divider)
                                                       Divider()
                                                           .padding(.leading, 80) // ⬅️ Start the line after the profile picture (50px image + 15px spacing + ~15px margin)
                                                           .padding(.trailing)
                                                   }
                                               }
                    }
                }
            }
            .background(Color(.systemBackground))
        }
        .navigationBarHidden(true)
        .onAppear {
            messageVM.subscribeToChats()
        }
        .navigationDestination(isPresented: $isShowingChatView) {
            if let chat = selectedChat {
                ChatView(chat: chat)
                    .environmentObject(messageVM)
                    .environmentObject(authVM)
            }
        }
        .fullScreenCover(isPresented: $isFindingNewChatPartner) {
            FindUsersView { user in
                Task {
                    self.selectedChat = await messageVM.startNewChat(with: user.id!)
                    if self.selectedChat != nil {
                        self.isShowingChatView = true
                    }
                }
                self.isFindingNewChatPartner = false
            }
            .environmentObject(homeVM)
        }
    }
}


private struct ChatRow: View {
    let chat: Chat
    @EnvironmentObject var authVM: AuthenticationViewModel

    var body: some View {
        // Adjust alignment to .center for better vertical alignment with the picture
        HStack(alignment: .center, spacing: 15) { // ⬅️ Changed .top to .center
            // Profile Picture (No change needed here)
            KFImage(chat.partnerProfilePictureURL)
                .placeholder { Image(systemName: "person.circle.fill").resizable().foregroundColor(.secondary) }
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
           
            // Name and Last Message
            VStack(alignment: .leading, spacing: 4) { // ⬅️ Added spacing for the text
                // Top Row: Name and Time/Unread Badge (Re-arranging for a common pattern)
                HStack {
                    Text(chat.partnerDisplayName ?? "Unknown User")
                        .font(.headline)
                        .fontWeight(chat.hasUnreadMessages(for: authVM.signedInUser?.id) ? .bold : .regular) // Bold name if unread
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(formattedTime(from: chat.lastUpdated?.dateValue() ?? Date()))
                        .font(.subheadline) // Slightly larger time font
                        .foregroundColor(.secondary)
                }
                
                // Bottom Row: Latest Message and Unread Badge (Moving badge to the side)
                HStack {
                    Text(chat.lastMessage?.text ?? "No messages yet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1) // ⬅️ Changed limit to 1 for a cleaner look
                    
                    Spacer()
                    
                    // Unread Count Badge
                    if let userId = authVM.signedInUser?.id, let unreadCount = chat.unreadCount?[userId], unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.caption2).bold()
                            .foregroundColor(.white)
                            .frame(minWidth: 20) // Ensure a minimum width for single-digit badges
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .background(Capsule().fill(Color.blue)) // ⬅️ Using Blue and Capsule for a more modern look (common in Telegram/WhatsApp)
                    }
                }
            }
            // Removed redundant padding and relying on the overall padding
        }
        .padding(.horizontal)
        .padding(.vertical, 10) // ⬅️ Consistent padding
        // Added helper for unread check
        .listRowInsets(EdgeInsets()) // Ensure it fills the full width in a List/ScrollView
        .background(Color(.systemBackground)) // Set a background color for consistency
    }

    private func formattedTime(from date: Date) -> String {
        // You might want to extend this logic to show "Yesterday" or the date for older messages
        let formatter = DateFormatter()
        formatter.timeStyle = .short // e.g., 5:30 PM
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

// Helper extension (assumes Chat is a class/struct you have)
extension Chat {
    func hasUnreadMessages(for userId: String?) -> Bool {
        guard let userId = userId, let unread = unreadCount?[userId] else { return false }
        return unread > 0
    }
}
