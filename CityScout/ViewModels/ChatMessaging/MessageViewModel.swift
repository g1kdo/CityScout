//
//  MessageViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 20/09/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

import Combine

@MainActor
class MessageViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var typingStatus: Set<String> = [] // User IDs of people who are typing
    @Published var users: [SignedInUser] = [] // NEW: For finding new chat partners
    
    private var db = Firestore.firestore()
    public var messagesListener: ListenerRegistration?
    private var chatsListener: ListenerRegistration?
    
    init() {
        subscribeToChats()
    }

    deinit {
        messagesListener?.remove()
        chatsListener?.remove()
    }
    
    // MARK: - Chat Management
    
    func subscribeToChats() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Remove existing listener to prevent duplicates
        chatsListener?.remove()
        
        chatsListener = db.collection("chats")
            .whereField("participants", arrayContains: userId)
            .order(by: "lastUpdated", descending: true)
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to fetch chats: \(error.localizedDescription)"
                    print("Error fetching chats: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    self.chats = []
                    return
                }

                self.chats = documents.compactMap { doc -> Chat? in
                    // FIX: This was the source of the "Initializer for conditional binding" error.
                    // The doc.data(as:) call already handles this correctly.
                    do {
                        let chat = try doc.data(as: Chat.self)
                        return chat
                    } catch {
                        print("Error decoding chat document: \(error.localizedDescription)")
                        return nil
                    }
                }
            }
    }
    
    // MARK: - Message Management
    
    func subscribeToMessages(chatId: String) {
        messagesListener?.remove()
        
        messagesListener = db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching messages: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    self.messages = []
                    return
                }
                
                self.messages = documents.compactMap { doc in
                    try? doc.data(as: Message.self)
                }
                
                // Mark messages as read for the current user
                Task {
                    await self.markAllMessagesAsRead(chatId: chatId)
                }
            }
    }
    
    func sendMessage(chatId: String, text: String, recipientId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
              
        // FIX: Corrected the Message initializer to match the model.
        // It now includes `receiverId`, `imageUrl`, and `isRead` with correct types.
        let newMessage = Message(
            senderId: userId,
            receiverId: recipientId,
            text: text,
            timestamp: Timestamp(date: Date()),
            imageUrl: nil, // Provided a default value
            isRead: false // Provided a default value
        )
        
        do {
            try db.collection("chats").document(chatId).collection("messages").addDocument(from: newMessage)
        } catch {
            print("Error sending message: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Utility Functions
    
    func markAllMessagesAsRead(chatId: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let chatRef = db.collection("chats").document(chatId)
        
        do {
            try await chatRef.updateData([
                "unreadCount.\(userId)": 0
            ])
        } catch {
            print("Error marking messages as read: \(error.localizedDescription)")
        }
    }

    // FIX: New function to create a new chat or find an existing one
    func startNewChat(with recipientId: String) async -> String {
        guard let userId = Auth.auth().currentUser?.uid,
              let currentUserDisplayName = Auth.auth().currentUser?.displayName,
              let currentUserProfilePictureURL = Auth.auth().currentUser?.photoURL else {
            return ""
        }
        
        let chatRef = db.collection("chats")
        let chatQuery = chatRef.whereField("participants", in: [ [userId, recipientId], [recipientId, userId] ])
        
        do {
            let snapshot = try await chatQuery.getDocuments()
            if let existingChat = snapshot.documents.first {
                print("Chat already exists with ID: \(existingChat.documentID)")
                return existingChat.documentID
            } else {
                print("No existing chat found. Creating a new one.")
                let newChatRef = chatRef.document()
                
                // Fetch the partner's display name and profile picture for the new Chat document
                let partnerDoc = try await db.collection("users").document(recipientId).getDocument()
                let partnerDisplayName = partnerDoc.data()?["displayName"] as? String ?? "Unknown User"
                let partnerProfilePictureURLString = partnerDoc.data()?["profilePictureURL"] as? String
                
                let initialData: [String: Any] = [
                    "participants": [userId, recipientId],
                    "lastUpdated": Timestamp(date: Date()),
                    // Create a full `lastMessage` object with all the required properties
                    "lastMessage": [
                        "senderId": userId,
                        "receiverId": recipientId,
                        "text": "Say hello!",
                        "timestamp": Timestamp(date: Date()),
                        "imageUrl": nil,
                        "isRead": false
                    ],
                    "partnerId": recipientId,
                    "partnerDisplayName": partnerDisplayName,
                    "partnerProfilePictureURL": partnerProfilePictureURLString,
                    "unreadCount": [
                        userId: 0,
                        recipientId: 1
                    ]
                ]
                
                try await newChatRef.setData(initialData)
                print("New chat created with ID: \(newChatRef.documentID)")
                return newChatRef.documentID
            }
        } catch {
            print("Error creating or finding chat: \(error.localizedDescription)")
            return ""
        }
    }
    
    // NEW: Function to fetch all users for starting a new chat
    func fetchUsers() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let usersSnapshot = try await db.collection("users").getDocuments()
            self.users = usersSnapshot.documents.compactMap { doc -> SignedInUser? in
                if let user = try? doc.data(as: SignedInUser.self), user.id != currentUserId {
                    return user
                }
                return nil
            }
        } catch {
            self.errorMessage = "Failed to fetch users: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
