//
//  Message.swift
//  CityScout
//
//  Created by Umuco Auca on 20/09/2025.
//

import Foundation
import FirebaseFirestore


// MARK: - Message
struct Message: Identifiable, Codable, Equatable {
    // @DocumentID is crucial for automatically mapping the Firestore document ID to this property.
    @DocumentID var id: String?
    
    // The sender's user ID.
    let senderId: String
    
    // The recipient's user ID.
    let receiverId: String
    
    // The content of the message.
    let text: String
    
    // A Firestore Timestamp to ensure messages are ordered correctly.
    let timestamp: Timestamp
    
    // An optional URL for an image attachment.
    let imageUrl: String?
    
    // A flag to indicate if the message has been read by the recipient.
    var isRead: Bool
    
    // Conformance to Equatable for SwiftUI updates.
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Chat Conversation
// This model represents a list of messages, grouped by conversation partner.
// It will be used to display the main "Messages" list, similar to your UI mockup.
struct Chat: Identifiable, Codable {
    // The unique ID for the conversation, often a combination of two user IDs.
    @DocumentID var id: String?
    
    // The other user in the chat.
    let partnerId: String
    
    // The last message sent in the conversation.
    var lastMessage: Message?
    
    // The display name of the conversation partner.
    var partnerDisplayName: String
    
    // The URL of the partner's profile picture.
    var partnerProfilePictureURL: URL?
    
    // A list of participants in the chat.
    let participants: [String]
    
    // FIX: A map of unread messages for each user. This matches Firestore's structure.
    var unreadCount: [String: Int]?
}
