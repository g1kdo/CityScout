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
    
    // The content of the message. This will be nil for image or voice messages.
    let text: String?
    
    // A Firestore Timestamp to ensure messages are ordered correctly.
    let timestamp: Timestamp
    
    // An optional URL for an image attachment.
    let imageUrl: String?
    
    // An optional URL for an audio file attachment (voice notes).
    let audioUrl: String?
    
    // NEW: Enum to define the message type for better rendering in the UI.
    // We will store this as a string in Firestore.
    enum MessageType: String, Codable {
        case text
        case image
        case voice
    }
    
    // The type of the message, defaults to .text.
    let messageType: MessageType
    
    // A flag to indicate if the message has been read by the recipient.
    var isRead: Bool
    
    // Conformance to Equatable for SwiftUI updates.
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}

struct Chat: Identifiable, Codable {
    // The unique ID for the conversation, often a combination of two user IDs.
    @DocumentID var id: String?
    
    // The other user in the chat.
    var partnerId: String? // FIX: Make optional to handle potential decoding issues.
    
    // The last message sent in the conversation.
    var lastMessage: Message? // FIX: Make optional for consistency.
    
    // The display name of the conversation partner.
    var partnerDisplayName: String? // FIX: Make optional for consistency.
    
    // The URL of the partner's profile picture.
    var partnerProfilePictureURL: URL? // FIX: Make optional for consistency.
    
    // A list of participants in the chat.
    var participants: [String] = []
    
    var lastUpdated: Timestamp?
    
    // FIX: A map of unread messages for each user. This matches Firestore's structure.
    var unreadCount: [String: Int]?
    
    // NEW: A map to track which user muted the chat.
    var mutedBy: [String: Bool]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case participants
        case lastUpdated
        case lastMessage
        case partnerId
        case partnerDisplayName
        case partnerProfilePictureURL
        case unreadCount
        case mutedBy
    }
}
