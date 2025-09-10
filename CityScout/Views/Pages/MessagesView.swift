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
    @StateObject private var viewModel = MessageViewModel()
    @EnvironmentObject var homeVM: HomeViewModel

    @State private var searchText: String = ""
    @State private var isShowingChatView: Bool = false
    @State private var selectedChat: Chat?
    @State private var isFindingNewChatPartner: Bool = false

    var filteredChats: [Chat] {
        if searchText.isEmpty {
            return viewModel.chats
        } else {
            return viewModel.chats.filter { chat in
                (chat.partnerDisplayName ?? "").localizedCaseInsensitiveContains(searchText) ||
                (chat.lastMessage?.text ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Main Header and Search Bar
                VStack(spacing: 15) {
                    HStack(spacing: 15) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }

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
                    
                    SearchBarView(searchText: $searchText, placeholder: "Search for chats & messages")
                }
                .padding(.top, 10)
                .padding(.bottom, 15)
                .background(Color(.secondarySystemGroupedBackground))

                ScrollView {
                    LazyVStack(spacing: 0) {
                        if viewModel.isLoading {
                            ProgressView("Loading chats...")
                                .padding()
                        } else if let errorMessage = viewModel.errorMessage {
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
                                ChatRow(chat: chat)
                                    .onTapGesture {
                                        self.selectedChat = chat
                                        self.isShowingChatView = true
                                    }
                            }
                        }
                    }
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.subscribeToChats()
            }
            .navigationDestination(isPresented: $isShowingChatView) {
                if let chat = selectedChat {
                    ChatView(chat: chat)
                        .environmentObject(viewModel)
                        .environmentObject(authVM)
                }
            }
            .fullScreenCover(isPresented: $isFindingNewChatPartner) {
                FindUsersView { user in
                    Task {
                        self.selectedChat = await viewModel.startNewChat(with: user.id!)
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
}

private struct ChatRow: View {
    let chat: Chat
    @EnvironmentObject var authVM: AuthenticationViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            KFImage(chat.partnerProfilePictureURL)
                .placeholder { Image(systemName: "person.circle.fill").resizable().foregroundColor(.secondary) }
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                HStack {
                    Text(chat.partnerDisplayName ?? "Unknown User")
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    if let userId = authVM.signedInUser?.id, let unreadCount = chat.unreadCount?[userId], unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.caption2).bold()
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.red))
                    }
                    Text(formattedTime(from: chat.lastUpdated?.dateValue() ?? Date()))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text(chat.lastMessage?.text ?? "No messages yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private func formattedTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

