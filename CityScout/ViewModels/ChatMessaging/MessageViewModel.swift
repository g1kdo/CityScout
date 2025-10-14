//
//  MessageViewModel.swift
//  CityScout
//
//  Created by Umuco Auca on 20/09/2025.
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
    
    // MARK: - Pagination Properties
    private var messagesBatchSize: Int = 20
    private var lastDocument: DocumentSnapshot?
    @Published var canLoadMoreMessages = true
    
    // Voice Recording
    private var audioRecorder: AudioRecorder?
    @Published var isRecording = false
    @Published var audioDuration: TimeInterval = 0
    private var recordingTimer: Timer?
    
    // In-memory cache for audio data
    private var audioCache: [String: Data] = [:]

    private var db = Firestore.firestore()
    private var storage = FirebaseStorage.Storage.storage()
    public var messagesListener: ListenerRegistration?
    private var chatsListener: ListenerRegistration?
    
    @Published var totalUnreadCount: Int = 0
    @Published var partnerStatus: UserStatus?
    private var partnerStatusListener: ListenerRegistration?
    
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
        
        chatsListener?.remove()
        
        chatsListener = db.collection("chats")
            .whereField("participants", arrayContains: userId)
            .order(by: "lastUpdated", descending: true)
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                self.isLoading = false
                
                // --- NEW: Exit if the update is from a local write ---
                // This stops the recursion after an update is applied by this client.
                if querySnapshot?.metadata.hasPendingWrites == true {
                    // The document change will still be processed below, but we won't trigger
                    // another updateChatPartnerInfo call.
                    // However, a simpler/safer approach is to let the loop run but skip the trigger.
                    // We'll proceed with the loop but only trigger the update if the change is NOT local.
                }
                
                if let error = error {
                    self.errorMessage = "Failed to fetch chats: \(error.localizedDescription)"
                    print("Error fetching chats: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    self.chats = []
                    self.totalUnreadCount = 0
                    return
                }

                // Determine if the snapshot contains an update that was NOT initiated locally
                        let isUpdateRemote = querySnapshot?.metadata.isFromCache == false && querySnapshot?.metadata.hasPendingWrites == false

                        self.chats = documents.compactMap { doc -> Chat? in
                            do {
                                var chat = try doc.data(as: Chat.self)
                                let chatId = doc.documentID // Capture the chat ID
                                
//                                if let lastMessage = chat.lastMessage {
//                                    // Check if the chat document is missing/incorrect metadata
//                                    let partnerIdFromMessage = (lastMessage.senderId == userId) ? lastMessage.receiverId : lastMessage.senderId
//                                    
//                                    if partnerIdFromMessage != chat.partnerId {
//                                        
//                                        // ⭐️ The fix is to only trigger the update if the metadata change
//                                        // didn't originate from a local write (i.e., another client made a change)
//                                        if isUpdateRemote {
//                                            print("Chat metadata is outdated. Updating partner info...")
//                                            Task {
//                                                // Use the captured chatId
//                                                await self.updateChatPartnerInfo(chatId: chatId, partnerId: partnerIdFromMessage)
//                                            }
//                                        } else {
//                                            // Print a different message for local updates to trace the loop
//                                            print("Chat metadata update detected (Local). Skipping recursive trigger.")
//                                        }
//                                    }
//                                }
                                return chat
                            } catch {
                                print("Error decoding chat document: \(error.localizedDescription)")
                                return nil
                            }
                        }
                        
                        self.calculateTotalUnreadCount(for: userId)
                    }
                }
    
    private func calculateTotalUnreadCount(for userId: String) {
            let count = self.chats.reduce(0) { total, chat in
                // Safely retrieve the unread count for the current user
                let unread = chat.unreadCount?[userId] ?? 0
                return total + unread
            }
            self.totalUnreadCount = count
        }
    
    // MARK: - User Status
    func subscribeToPartnerStatus(partnerId: String) {
        partnerStatusListener?.remove() // Remove any existing listener
        
        // Attempt to listen to the 'users' collection first
        let userDocRef = db.collection("users").document(partnerId)
        
        // Use a helper to check and subscribe to the correct document
        listenToPartnerDocument(for: partnerId, ref: userDocRef, isUserCollection: true)
    }

    private func listenToPartnerDocument(for partnerId: String, ref: DocumentReference, isUserCollection: Bool) {
        
        partnerStatusListener = ref.addSnapshotListener { [weak self] (documentSnapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error listening to partner status in \(isUserCollection ? "users" : "partners"): \(error.localizedDescription)")
                // If the listener fails completely, stop trying
                self.partnerStatus = nil
                return
            }
            
            guard let document = documentSnapshot else {
                self.partnerStatus = nil
                return
            }
            
            // 1. Check if the document exists
            if !document.exists {
                // If the document doesn't exist in 'users', try 'partners'
                if isUserCollection {
                    let partnerDocRef = self.db.collection("partners").document(partnerId)
                    // Remove the old listener and start a new one for the 'partners' collection
                    self.partnerStatusListener?.remove()
                    self.listenToPartnerDocument(for: partnerId, ref: partnerDocRef, isUserCollection: false)
                    return // Exit the current listener block
                } else {
                    // Document not found in 'users' OR 'partners'
                    self.partnerStatus = nil
                    return
                }
            }

            // 2. Document exists, attempt to decode the status
            do {
                // Firestore's decoding requires the fields to exist or be optional.
                // Assuming 'isOnline' and 'lastSeen' are now fields on both user/partner documents.
                let status = try document.data(as: UserStatus.self)
                
                // To be robust, ensure we actually got the data (it could still be nil even if the doc exists)
                if status.isOnline != nil || status.lastSeen != nil {
                     self.partnerStatus = status
                } else {
                    // Document exists but is missing the crucial status fields
                    self.partnerStatus = nil
                    print("Document for \(partnerId) is missing isOnline/lastSeen fields.")
                }
               
            } catch {
                // This catches the "missing data" or "decoding error" if the document is malformed
                print("Error decoding partner status in \(isUserCollection ? "users" : "partners"): \(error.localizedDescription)")
                self.partnerStatus = nil
            }
        }
    }
        
        func unsubscribeFromPartnerStatus() {
            partnerStatusListener?.remove()
            partnerStatusListener = nil
        }
    
    private func updateChatPartnerInfo(chatId: String, partnerId: String) async {
        let chatRef = db.collection("chats").document(chatId)
        
        do {
            try await db.runTransaction { (transaction, errorPointer) -> Void in
                let chatDocument: DocumentSnapshot
                
                do {
                    // 1. Read the current document state within the transaction
                    chatDocument = try transaction.getDocument(chatRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return
                }
                
                // 2. Perform the client-side check on the read document
                guard let chatData = chatDocument.data(),
                      let currentPartnerId = chatData["partnerId"] as? String else {
                    return // Document is empty or missing partnerId, skip update
                }
                
                // 3. ONLY proceed if the document's current partnerId is WRONG
                // This is the race condition safeguard
                if currentPartnerId != partnerId {
                    // 4. Update the fields
                    transaction.updateData([
                        "partnerId": partnerId,
                        // Optionally fetch and set other partner info here if needed
                    ], forDocument: chatRef)
                    
                    print("Successfully updated chat metadata via transaction.")
                }
            }
        } catch {
            print("Transaction failed with error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Message Management
    
    func subscribeToMessages(chatId: String) {
        messagesListener?.remove()
        
        let initialQuery = db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp", descending: true)
            .limit(to: messagesBatchSize)
        
        messagesListener = initialQuery.addSnapshotListener { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = "Failed to fetch messages: \(error.localizedDescription)"
                print("Error fetching messages: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                self.messages = []
                return
            }
            
            self.lastDocument = documents.last
            self.messages = documents.compactMap { doc in
                try? doc.data(as: Message.self)
            }.reversed()
            
            self.canLoadMoreMessages = documents.count >= self.messagesBatchSize
            
            Task {
                await self.markAllMessagesAsRead(chatId: chatId)
            }
        }
    }
    
    // MARK: - Pagination
    func loadMoreMessages(chatId: String) {
        guard let lastDocument = lastDocument, canLoadMoreMessages else { return }
        
        let nextQuery = db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp", descending: true)
            .start(afterDocument: lastDocument)
            .limit(to: messagesBatchSize)
        
        nextQuery.getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = "Failed to fetch older messages: \(error.localizedDescription)"
                print("Error fetching older messages: \(error.localizedDescription)")
                self.canLoadMoreMessages = false
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                self.canLoadMoreMessages = false
                return
            }
            
            if documents.isEmpty {
                self.canLoadMoreMessages = false
                return
            }
            
            let olderMessages = documents.compactMap { doc in
                try? doc.data(as: Message.self)
            }.reversed()
            
            self.messages.insert(contentsOf: olderMessages, at: 0)
            self.lastDocument = documents.last
            
            if documents.count < self.messagesBatchSize {
                self.canLoadMoreMessages = false
            }
        }
    }

    func sendMessage(chatId: String, text: String?, imageUrl: String? = nil, audioUrl: String? = nil, recipientId: String) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User not authenticated."
            return
        }
        
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
            self.errorMessage = "Failed to send message: \(error.localizedDescription)"
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
        guard let userId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User not authenticated."
            return
        }
        
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
        if let cachedData = audioCache[urlString] {
            return cachedData
        }

        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid audio URL."
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            audioCache[urlString] = data
            return data
        } catch {
            print("Error downloading audio file: \(error.localizedDescription)")
            self.errorMessage = "Failed to download audio file."
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
            
            audioRecorder = try AudioRecorder(url: audioFileName, settings: settings)
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
    
    func unmuteChat(chatId: String, forUser userId: String) async {
        let chatRef = db.collection("chats").document(chatId)
        do {
            try await chatRef.updateData([
                "mutedBy.\(userId)": FieldValue.delete()
            ])
        } catch {
            print("Error unmuting chat: \(error.localizedDescription)")
            self.errorMessage = "Failed to unmute chat."
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
        } catch {
            print("Error reporting user: \(error.localizedDescription)")
            self.errorMessage = "Failed to submit report."
        }
    }
    
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
        
        // --- Existing Chat Check ---
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
        
        // --- Dual-Collection Lookup for Recipient Info ---
        var partnerDisplayName: String = "Unknown User"
        var partnerProfilePictureURLString: String? = nil
        
        do {
            // 1. Try fetching from the "users" collection (Standard User)
            let userDoc = try await db.collection("users").document(recipientId).getDocument()
            
            if userDoc.exists {
                partnerDisplayName = userDoc.data()?["displayName"] as? String ?? "Unknown User (User)"
                partnerProfilePictureURLString = userDoc.data()?["profilePictureURL"] as? String
            } else {
                // 2. If not a User, try fetching from the "partners" collection (Partner)
                let partnerDoc = try await db.collection("partners").document(recipientId).getDocument()
                
                if partnerDoc.exists {
                    // Use the field name you specified for partners
                    partnerDisplayName = partnerDoc.data()?["partnerDisplayName"] as? String ?? "Unknown User (Partner)"
                    partnerProfilePictureURLString = partnerDoc.data()?["profilePictureURL"] as? String
                }
            }
        } catch {
            print("Error fetching user/partner data for new chat: \(error.localizedDescription)")
        }
        
        // --- Chat Creation ---
        do {
            let newChatRef = chatRef.document()
                
            // Create the initial message
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
                "partnerDisplayName": partnerDisplayName as Any, // Use the resolved name
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
            print("New chat created with ID: \(newChatRef.documentID) with partner name: \(partnerDisplayName)")
                
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

// MARK: - Helper Classes

// Simple Haptic Manager
class HapticManager {
    static let shared = HapticManager()
    private init() {}
    
    func play(feedback style: UIImpactFeedbackGenerator.FeedbackStyle) {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        #endif
    }
}

// AudioRecorder class
private class AudioRecorder {
    private var audioRecorder: AVAudioRecorder?
    private var audioURL: URL?

    init(url: URL, settings: [String: Any]) throws {
        self.audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        self.audioURL = url
    }

    func record() {
        self.audioRecorder?.record()
    }
    
    func stop() {
        self.audioRecorder?.stop()
    }
    
    var url: URL? {
        self.audioURL
    }
    
    var currentTime: TimeInterval {
        self.audioRecorder?.currentTime ?? 0
    }
}

struct UserStatus: Decodable, Identifiable {
    @DocumentID var id: String?
    var isOnline: Bool? = false
    var lastSeen: Timestamp? = Timestamp(date: Date())
}
