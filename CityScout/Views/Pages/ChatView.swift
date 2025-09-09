//
//  ChatView.swift
//  CityScout
//
//  Created by Umuco Auca on 20/09/2025.
//

import SwiftUI
import Kingfisher

struct ChatView: View {
    // FIX: The chat object must be passed into the view.
    let chat: Chat
    
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var authVM: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss

    @State private var messageText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header for the chat view.
            HStack(spacing: 15) {
                // FIX: Added a back button that uses the dismiss environment object
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                // NEW: Partner's profile picture and name
                KFImage(chat.partnerProfilePictureURL)
                    .placeholder { Image(systemName: "person.circle.fill").resizable().foregroundColor(.secondary) }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(chat.partnerDisplayName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if viewModel.typingStatus.contains(chat.partnerId) {
                        Text("Typing...")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        // Display the partner's status, e.g., "Online" or "Offline"
                        Text("Online")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()

                Menu {
                    Button("Mute Conversation", action: { /* TODO */ })
                    Button("Report User", role: .destructive, action: { /* TODO */ })
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))

            // Message List.
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            MessageRow(message: message, isFromCurrentUser: message.senderId == authVM.signedInUser?.id)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages) { _, newMessages in
                    if let lastMessageId = newMessages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastMessageId, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Message Input Field.
            MessageInputView(messageText: $messageText) {
                if !messageText.isEmpty {
                    // FIX: Safely unwrap optional values
                    if let chatId = chat.id {
                        viewModel.sendMessage(chatId: chatId, text: messageText, recipientId: chat.partnerId)
                        messageText = ""
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // FIX: Safely unwrap optional chat ID
            if let chatId = chat.id {
                viewModel.subscribeToMessages(chatId: chatId)
            }
        }
        .onDisappear {
            // FIX: Safely unwrap the optional listener before removing
            viewModel.messagesListener?.remove()
        }
    }
}

// A view for a single message.
private struct MessageRow: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    // FIX: Using the shared user and partner info from the view model
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var authVM: AuthenticationViewModel
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if isFromCurrentUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.text)
                        .padding(12)
                        .background(Color(hex: "#24BAEC"))
                        .foregroundColor(.white)
                        .cornerRadius(15, corners: [.topLeft, .topRight, .bottomLeft])
                    Text(formattedTime(from: message.timestamp.dateValue()))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                KFImage(authVM.signedInUser?.profilePictureAsURL)
                    .placeholder { Image(systemName: "person.circle.fill").resizable().foregroundColor(.secondary) }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 35, height: 35)
                    .clipShape(Circle())
            } else {
                KFImage(viewModel.chats.first(where: { $0.partnerId == message.senderId })?.partnerProfilePictureURL)
                    .placeholder { Image(systemName: "person.circle.fill").resizable().foregroundColor(.secondary) }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 35, height: 35)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(15, corners: [.topLeft, .topRight, .bottomRight])
                    Text(formattedTime(from: message.timestamp.dateValue()))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }
    
    private func formattedTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// The text input field and send button.
private struct MessageInputView: View {
    @Binding var messageText: String
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            TextField("Type a message...", text: $messageText)
                .textFieldStyle(.roundedBorder)
                .padding(.vertical, 8)
            
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .resizable()
                    .frame(width: 35, height: 35)
                    .foregroundColor(messageText.isEmpty ? .secondary : Color(hex: "#24BAEC"))
            }
            .disabled(messageText.isEmpty)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }
}
