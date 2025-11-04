//
//  MessagesView.swift
//  CityScout
//
//  Created by Umuco Auca on 20/09/2025.
//

import SwiftUI
import Kingfisher
import Combine

struct MessagesView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var messageVM: MessageViewModel
    @EnvironmentObject var homeVM: HomeViewModel

    @State private var searchText: String = ""
    @State private var isShowingChatView: Bool = false
    @State private var selectedChat: Chat?
    @State private var isFindingNewChatPartner: Bool = false
    @State private var cancellables = Set<AnyCancellable>()

    var filteredChats: [Chat] {
        
        let currentUserId = authVM.signedInUser?.id ?? ""
        if searchText.isEmpty {
            return messageVM.chats
        } else {
            return messageVM.chats.filter { chat in
                (chat.getPartnerDisplayName(currentUserId: currentUserId)).localizedCaseInsensitiveContains(searchText) ||
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
                .padding(.top, 10)

                MessageSearchBarView(searchText: $searchText, placeholder: "Search for chats & messages")
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
            homeVM.$transcribedText
                        .dropFirst() // Don't use the initial value
                        .filter { _ in self.homeVM.isListeningToSpeech == false } // Only act after listening stops
                        .sink { newText in // No capture list needed for struct
                            guard !newText.isEmpty else { return }
                            
                            self.searchText = newText
                            self.homeVM.transcribedText = ""
                        }
                        .store(in: &cancellables)
        }
        .onDisappear {
            cancellables.removeAll()
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

    // Helper to determine the user-friendly preview string
    private var lastMessagePreview: String {
        guard let lastMessage = chat.lastMessage else {
            return "No messages yet."
        }

        // Check if the message was sent by the current user
        let isSentByMe = lastMessage.senderId == authVM.signedInUser?.id
        let prefix = isSentByMe ? "You: " : ""
        
        // 🎯 Logic for rich media message types
        if lastMessage.imageUrl != nil {
            return prefix + "Image 🖼️"
        }
        
        if lastMessage.audioUrl != nil {
            return prefix + "Voice Message 🎤"
        }
        
        // Add more media types here (e.g., if lastMessage.videoURL != nil, return "Video 🎥")
        
        // Fallback to text, trimming it for a clean display
        if let text = lastMessage.text, !text.isEmpty {
            return prefix + text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Fallback if message exists but has no content (e.g., failed to send text)
        return "Message sent."
    }

    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            // Profile Picture (No change)
            let currentUserId = authVM.signedInUser?.id ?? ""
            KFImage(chat.getPartnerProfilePictureURL(currentUserId: currentUserId ?? ""))
                .placeholder { Image(systemName: "person.circle.fill").resizable().foregroundColor(.secondary) }
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            
            // Name and Last Message
            VStack(alignment: .leading, spacing: 4) {
                // Top Row: Name and Time
                HStack {
                    Text(chat.getPartnerDisplayName(currentUserId: currentUserId) ?? "Unknown User")
                        .font(.headline)
                        .fontWeight(chat.hasUnreadMessages(for: authVM.signedInUser?.id) ? .bold : .regular)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(formattedTime(from: chat.lastUpdated?.dateValue() ?? Date()))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Bottom Row: Latest Message and Unread Badge
                HStack {
                    // 🎯 USE THE NEW COMPUTED PROPERTY HERE
                    Text(lastMessagePreview)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Unread Count Badge (No change)
                    if let userId = authVM.signedInUser?.id, let unreadCount = chat.unreadCount?[userId], unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.caption2).bold()
                            .foregroundColor(.white)
                            .frame(minWidth: 20)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .background(Capsule().fill(Color.blue))
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .listRowInsets(EdgeInsets())
        .background(Color(.systemBackground))
    }


    private func formattedTime(from date: Date) -> String {
        let calendar = Calendar.current
        
        // 1. Check if the message is from Today
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short // e.g., 5:30 PM
            formatter.dateStyle = .none
            return formatter.string(from: date)
        }
        
        // 2. Check if the message is from Yesterday
        else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        
        // 3. Check if the message is from this week (last 7 days)
        // We check if it's within the current calendar week but not today/yesterday.
        else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()), date > weekAgo {
            let formatter = DateFormatter()
            // Use the weekday format (e.g., Monday, Tuesday)
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
        
        // 4. Message is older than 7 days (show the full date)
        else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short // e.g., 10/7/25 or 7/10/25
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}

// Helper extension (assumes Chat is a class/struct you have)
extension Chat {
    func hasUnreadMessages(for userId: String?) -> Bool {
        guard let userId = userId, let unread = unreadCount?[userId] else { return false }
        return unread > 0
    }
}
