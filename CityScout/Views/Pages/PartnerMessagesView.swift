//
//  PartnerMessagesView.swift
//  CityScout
//
//  Created by Umuco Auca on 06/11/2025. // Updated date for Partner view
//

import SwiftUI
import Kingfisher
import Combine

struct PartnerMessagesView: View {
    // ⚠️ CHANGE 1: Use the dedicated Partner Authentication ViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var partnerAuthVM: PartnerAuthenticationViewModel // ⬅️ CHANGED
    @EnvironmentObject var messageVM: MessageViewModel
    @EnvironmentObject var homeVM: HomeViewModel // Assuming HomeViewModel might still be used for speech-to-text

    @State private var searchText: String = ""
    @State private var isShowingChatView: Bool = false
    @State private var selectedChat: Chat?
    // ⚠️ REMOVED: @State private var isFindingNewChatPartner: Bool = false (Partners only respond)
    @State private var cancellables = Set<AnyCancellable>()

    var filteredChats: [Chat] {
        
        // ⚠️ CHANGE 2: Use the Partner's ID for filtering and display logic
        let currentUserId = partnerAuthVM.signedInPartner?.id ?? "" // ⬅️ CHANGED
        
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
                    // Optional: You might keep the dismiss button if this view is presented as a sheet/modal
                    // or replace it with a profile button, depending on your partner UI flow.
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .background(Circle().fill(Color(.systemGray6)).frame(width: 40, height: 40))
                    }
                    Spacer()

                    Text("Client Chats") // ⬅️ Slight UI change for partner context
                        .font(.headline)
                        .fontWeight(.bold)

                    Spacer()

                    // ⚠️ REMOVED: Button to start a new chat (square.and.pencil)
                    // Replaced with an empty space or different button if needed
                    Spacer().frame(width: 40, height: 40) 
                }
                .padding(.horizontal)
                .padding(.top, 10)

                MessageSearchBarView(searchText: $searchText, placeholder: "Search clients & messages")
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
                        Text("No client chats found for \"\(searchText)\"")
                            .foregroundColor(.secondary)
                            .padding()
                    } else if filteredChats.isEmpty {
                        Text("You have no active client chats.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(filteredChats) { chat in
                             VStack(spacing: 0) {
                                 // ⚠️ CHANGE 3: Use PartnerChatRow to pass the correct VM
                                 PartnerChatRow(chat: chat) // ⬅️ CHANGED
                                     .environmentObject(partnerAuthVM) // ⬅️ NEW
                                     .onTapGesture {
                                         self.selectedChat = chat
                                         self.isShowingChatView = true
                                     }
                                 
                                 // Aesthetic and Subtle Line (Divider)
                                 Divider()
                                     .padding(.leading, 80)
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
            // The MessageViewModel's subscribeToChats uses Auth.auth().currentUser?.uid,
            // which should already be the authenticated Partner's ID if they signed in.
            messageVM.subscribeToChats() 
            
            homeVM.$transcribedText
                        .dropFirst()
                        .filter { _ in self.homeVM.isListeningToSpeech == false }
                        .sink { newText in
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
                // ⚠️ CHANGE 4: Route to PartnerChatView (when you create it)
                // For now, let's assume you'll create a modified ChatView named PartnerChatView
                // You may need to pass the partnerAuthVM here as well.
                ChatView(chat: chat) // <-- Will be PartnerChatView(chat: chat)
                    .environmentObject(messageVM)
                    .environmentObject(partnerAuthVM) // ⬅️ CHANGED
            }
        }
        // ⚠️ REMOVED: .fullScreenCover(isPresented: $isFindingNewChatPartner) logic
    }
}



private struct PartnerChatRow: View { // ⬅️ CHANGED NAME
    let chat: Chat
    // ⚠️ CHANGE 5: Use the dedicated Partner Authentication ViewModel
    @EnvironmentObject var partnerAuthVM: PartnerAuthenticationViewModel // ⬅️ CHANGED

    // Helper to determine the user-friendly preview string
    private var lastMessagePreview: String {
        guard let lastMessage = chat.lastMessage,
              // ⚠️ CHANGE 6: Safely get the current authenticated Partner's ID
              let currentPartnerId = partnerAuthVM.signedInPartner?.id else {
            return "No messages yet."
        }

        // Check if the message was sent by the current PARTNER
        // ⚠️ CHANGE 7: Check sender ID against the Partner's ID
        let isSentByMe = lastMessage.senderId == currentPartnerId
        let prefix = isSentByMe ? "You: " : ""
        
        // 🎯 Logic for rich media message types (remains the same)
        if lastMessage.imageUrl != nil {
            return prefix + "Image 🖼️"
        }
        
        if lastMessage.audioUrl != nil {
            return prefix + "Voice Message 🎤"
        }
        
        // Fallback to text
        if let text = lastMessage.text, !text.isEmpty {
            return prefix + text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return "Message sent."
    }

    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            // Profile Picture
            // ⚠️ CHANGE 8: Safely get the current authenticated Partner's ID
            let currentPartnerId = partnerAuthVM.signedInPartner?.id ?? ""
            
            // Note: chat.getPartnerProfilePictureURL still relies on the logic in Chat struct
            // to fetch the OTHER person's (the client's) picture/name, which is correct.
            KFImage(chat.getPartnerProfilePictureURL(currentUserId: currentPartnerId))
                .placeholder { Image(systemName: "person.circle.fill").resizable().foregroundColor(.secondary) }
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            
            // Name and Last Message
            VStack(alignment: .leading, spacing: 4) {
                // Top Row: Name and Time
                HStack {
                    // This fetches the Client's name (the chat partner)
                    Text(chat.getPartnerDisplayName(currentUserId: currentPartnerId) ?? "Unknown Client")
                        .font(.headline)
                        // ⚠️ CHANGE 9: Check unread messages for the Partner's ID
                        .fontWeight(chat.hasUnreadMessages(for: currentPartnerId) ? .bold : .regular)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(formattedTime(from: chat.lastUpdated?.dateValue() ?? Date()))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Bottom Row: Latest Message and Unread Badge
                HStack {
                    Text(lastMessagePreview)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Unread Count Badge
                    // ⚠️ CHANGE 10: Check unread count for the Partner's ID
                    if let userId = partnerAuthVM.signedInPartner?.id, let unreadCount = chat.unreadCount?[userId], unreadCount > 0 {
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

    // Helper function remains the same
    private func formattedTime(from date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()), date > weekAgo {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}

// NOTE: The Chat extension doesn't need to change as it relies on the passed userId.
