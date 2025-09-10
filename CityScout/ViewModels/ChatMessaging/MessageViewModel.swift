//
//  MessageViewModel.swift
//  CityScout
// CityScout
// Created by Umuco Auca on 20/09/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import Combine
import AVFoundation
import PhotosUI
import SwiftUI

@MainActor
class MessageViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var typingStatus: Set<String> = [] // User IDs of people who are typing
    @Published var users: [SignedInUser] = [] // For finding new chat partners
    @Published var recommendedUsers: [SignedInUser] = [] // For proximity-based matching
    
    private var db = Firestore.firestore()
    private var storage = FirebaseStorage.Storage.storage()
    public var messagesListener: ListenerRegistration?
    private var chatsListener: ListenerRegistration?
    
    // NEW: Audio Recording Properties
    private var audioRecorder: AVAudioRecorder?
    @Published var isRecording = false
    @Published var audioDuration: TimeInterval = 0
    private var recordingTimer: Timer?
    
    // NEW: In-memory cache for audio data
    private var audioCache: [String: Data] = [:]

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
                    do {
                        var chat = try doc.data(as: Chat.self)
                        // This manual update is a quick fix to ensure the partner info is correct
                        // A better approach would be to have a Cloud Function update the partner info
                        // when a message is sent.
                        if let lastMessage = chat.lastMessage {
                            let partnerId = (lastMessage.senderId == userId) ? lastMessage.receiverId : lastMessage.senderId
                            if partnerId != chat.partnerId {
                                print("Chat metadata is outdated. Updating partner info...")
                                Task { await self.updateChatPartnerInfo(chatId: doc.documentID, partnerId: partnerId) }
                            }
                        }
                        
                        return chat
                    } catch {
                        print("Error decoding chat document: \(error.localizedDescription)")
                        return nil
                    }
                }
            }
    }
    
    // NEW: Update the Chat document with correct partner information
    private func updateChatPartnerInfo(chatId: String, partnerId: String) async {
        do {
            let partnerDoc = try await db.collection("users").document(partnerId).getDocument()
            let partnerDisplayName = partnerDoc.data()?["displayName"] as? String ?? "Unknown User"
            let partnerProfilePictureURLString = partnerDoc.data()?["profilePictureURL"] as? String
            
            try await db.collection("chats").document(chatId).updateData([
                "partnerId": partnerId,
                "partnerDisplayName": partnerDisplayName as Any,
                "partnerProfilePictureURL": partnerProfilePictureURLString as Any
            ])
        } catch {
            print("Error updating chat partner info: \(error.localizedDescription)")
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
    
    func sendMessage(chatId: String, text: String?, imageUrl: String? = nil, audioUrl: String? = nil, recipientId: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Determine the message type based on the content provided
        var messageType: Message.MessageType = .text
        if imageUrl != nil {
            messageType = .image
        } else if audioUrl != nil {
            messageType = .voice
        }
        
        let newMessage = Message(
            senderId: userId,
            receiverId: recipientId,
            text: text,
            timestamp: Timestamp(date: Date()),
            imageUrl: imageUrl,
            audioUrl: audioUrl,
            messageType: messageType,
            isRead: false
        )
        
        do {
            try db.collection("chats").document(chatId).collection("messages").addDocument(from: newMessage)
        } catch {
            print("Error sending message: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Advanced Messaging (Image & Voice)
    
    func uploadImageAndSendMessage(chatId: String, image: UIImage, recipientId: String) async {
        guard let userId = Auth.auth().currentUser?.uid, let imageData = image.jpegData(compressionQuality: 0.8) else {
            self.errorMessage = "Failed to convert image to data."
            return
        }

        let storageRef = storage.reference().child("chat_images/\(UUID().uuidString).jpg")
        
        do {
            _ = try await storageRef.putDataAsync(imageData)
            let downloadUrl = try await storageRef.downloadURL()
            await sendMessage(chatId: chatId, text: nil, imageUrl: downloadUrl.absoluteString, recipientId: recipientId)
        } catch {
            self.errorMessage = "Failed to upload image: \(error.localizedDescription)"
            print("Error uploading image: \(error.localizedDescription)")
        }
    }

    func uploadVoiceNoteAndSendMessage(chatId: String, audioUrl: URL, recipientId: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let storageRef = storage.reference().child("voice_notes/\(UUID().uuidString).m4a")
        
        do {
            _ = try await storageRef.putFileAsync(from: audioUrl)
            let downloadUrl = try await storageRef.downloadURL()
            await sendMessage(chatId: chatId, text: nil, audioUrl: downloadUrl.absoluteString, recipientId: recipientId)
        } catch {
            self.errorMessage = "Failed to upload voice note: \(error.localizedDescription)";
            print("Error uploading voice note: \(error.localizedDescription)")
        }
    }
    
    // NEW: Function to download audio and cache it
    func getAudioData(from urlString: String) async -> Data? {
        // Check cache first
        if let cachedData = audioCache[urlString] {
            return cachedData
        }

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            // Cache the downloaded data
            audioCache[urlString] = data
            return data
        } catch {
            print("Error downloading audio file: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Audio Recording
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            try audioSession.setActive(true)
            
            let audioFileName = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFileName, settings: settings)
            audioRecorder?.record()
            
            isRecording = true
            audioDuration = 0
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.audioDuration = self.audioRecorder?.currentTime ?? 0
            }
        } catch {
            self.errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        isRecording = false
        
        let audioURL = audioRecorder?.url
        audioRecorder = nil
        return audioURL
    }

    // MARK: - Chat Controls (Mute & Report)
    
    func muteChat(chatId: String, forUser userId: String) async {
        let chatRef = db.collection("chats").document(chatId)
        do {
            try await chatRef.updateData([
                "mutedBy.\(userId)": true
            ])
            print("Chat \(chatId) muted for user \(userId).")
        } catch {
            print("Error muting chat: \(error.localizedDescription)")
            self.errorMessage = "Failed to mute chat."
        }
    }
    
    // NEW: Report User Logic
    func reportUser(chatId: String, recipientId: String, reason: String) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "You must be logged in to report a user."
            return
        }
        
        let reportData: [String: Any] = [
            "reporterId": userId,
            "reportedUserId": recipientId,
            "chatId": chatId,
            "reason": reason,
            "timestamp": FieldValue.serverTimestamp(),
            "status": "pending"
        ]
        
        do {
            _ = try await db.collection("userReports").addDocument(data: reportData)
            print("User \(recipientId) reported successfully from chat \(chatId).")
            // You can add a success message or alert here
        } catch {
            print("Error reporting user: \(error.localizedDescription)")
            self.errorMessage = "Failed to submit report."
        }
    }
    
    // NEW: Delete a message for all users
    func deleteMessage(chatId: String, messageId: String) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "You must be logged in to delete a message."
            return
        }
        
        let db = Firestore.firestore()
        let messageRef = db.collection("chats").document(chatId).collection("messages").document(messageId)
        
        do {
            try await messageRef.delete()
            print("Message \(messageId) deleted successfully.")
            // Success feedback can be provided here
        } catch {
            print("Error deleting message: \(error.localizedDescription)")
            self.errorMessage = "Failed to delete message."
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

    func startNewChat(with recipientId: String) async -> Chat? {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User not logged in."
            return nil
        }
        
        let chatRef = db.collection("chats")
        
        // Check if a chat already exists between these two users
        let existingChatQuery = chatRef.whereField("participants", isEqualTo: [userId, recipientId])
        let existingChatQueryReversed = chatRef.whereField("participants", isEqualTo: [recipientId, userId])

        do {
            let snapshot = try await existingChatQuery.getDocuments()
            if let existingChatDoc = snapshot.documents.first {
                print("Chat already exists with ID: \(existingChatDoc.documentID)")
                return try? existingChatDoc.data(as: Chat.self)
            } else {
                let snapshotReversed = try await existingChatQueryReversed.getDocuments()
                if let existingChatDoc = snapshotReversed.documents.first {
                    print("Chat already exists with ID: \(existingChatDoc.documentID)")
                    return try? existingChatDoc.data(as: Chat.self)
                }
            }
        } catch {
            self.errorMessage = "Error checking for existing chat: \(error.localizedDescription)"
            return nil
        }
        
        // If no existing chat is found, create a new one
        do {
            let newChatRef = chatRef.document()
            
            // Fetch the partner's display name and profile picture for the new Chat document
            let partnerDoc = try await db.collection("users").document(recipientId).getDocument()
            let partnerDisplayName = partnerDoc.data()?["displayName"] as? String ?? "Unknown User"
            let partnerProfilePictureURLString = partnerDoc.data()?["profilePictureURL"] as? String
            
            let initialMessageText = "Say hello!"
            let initialMessage = Message(
                senderId: userId,
                receiverId: recipientId,
                text: initialMessageText,
                timestamp: Timestamp(date: Date()),
                imageUrl: nil,
                audioUrl: nil,
                messageType: .text,
                isRead: false
            )
            
            let initialData: [String: Any] = [
                "participants": [userId, recipientId],
                "lastUpdated": Timestamp(date: Date()),
                "lastMessage": try Firestore.Encoder().encode(initialMessage),
                "partnerId": recipientId,
                "partnerDisplayName": partnerDisplayName as Any,
                "partnerProfilePictureURL": partnerProfilePictureURLString as Any,
                "unreadCount": [
                    userId: 0,
                    recipientId: 1
                ],
                "mutedBy": [
                    userId: false,
                    recipientId: false
                ]
            ]
            
            try await newChatRef.setData(initialData)
            print("New chat created with ID: \(newChatRef.documentID)")
            
            // Re-fetch the new chat document to ensure the model is correct
            let newChatDoc = try await newChatRef.getDocument()
            return try? newChatDoc.data(as: Chat.self)
            
        } catch {
            print("Error creating new chat: \(error.localizedDescription)")
            self.errorMessage = "Error creating new chat."
            return nil
        }
    }
    
    // NEW: Function to fetch all users based on a relevance score
    func fetchRecommendedUsers() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let currentUserDoc = try await db.collection("users").document(currentUserId).getDocument()
            guard let currentUserData = currentUserDoc.data() else {
                errorMessage = "Could not find current user data."
                isLoading = false
                return
            }
            
            let currentUserInterests = currentUserData["selectedInterests"] as? [String] ?? []
            let currentUserEvents = currentUserData["scheduledEvents"] as? [String] ?? [] // Assuming event IDs are stored here
            
            let usersSnapshot = try await db.collection("users").getDocuments()
            
            var scoredUsers: [(user: SignedInUser, score: Int)] = []
            
            for doc in usersSnapshot.documents {
                if doc.documentID == currentUserId { continue }
                
                guard let otherUser = try? doc.data(as: SignedInUser.self) else { continue }
                
                var score = 0
                
                // Score based on shared interests
                if let otherUserInterests = otherUser.selectedInterests {
                    let commonInterests = Set(currentUserInterests).intersection(Set(otherUserInterests))
                    score += commonInterests.count * 2 // Weight interests more heavily
                }
                
                // Score based on shared events (simplified)
                if let otherUserEvents = otherUser.scheduledEvents {
                    let commonEvents = Set(currentUserEvents).intersection(Set(otherUserEvents))
                    score += commonEvents.count
                }
                
                if score > 0 {
                    scoredUsers.append((user: otherUser, score: score))
                }
            }
            
            // Sort by score in descending order
            let sortedUsers = scoredUsers.sorted { $0.score > $1.score }.map { $0.user }
            
            self.recommendedUsers = sortedUsers
            self.isLoading = false
            
            if self.recommendedUsers.isEmpty {
                self.errorMessage = "No matching users found based on your interests and plans."
            }
            
        } catch {
            self.errorMessage = "Failed to fetch recommended users: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    // NEW: Function to fetch all users (used for general search, to be replaced by recommended users)
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
