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

// Helper structure to hold the name and photo URL for a single user
struct ChatParticipant: Codable, Identifiable {
    /*@DocumentID*/
    var id: String?
    var displayName: String
    var profilePictureURL: URL?
    
    // Conforming to Codable requires defining an initializer from Decoder
    // if you use optional properties that may not exist in Firestore.
    // For simplicity, we assume standard decoding here.
}

struct Chat: Identifiable, Codable {
    @DocumentID var id: String?
    
    // Map storing metadata for BOTH participants, keyed by their user ID.
    var userMetadata: [String: ChatParticipant]?
    
    var lastMessage: Message?
    var participants: [String] = []
    var lastUpdated: Timestamp?
    var unreadCount: [String: Int]?
    var mutedBy: [String: Bool]?
    
    // Removed: partnerId, partnerDisplayName, partnerProfilePictureURL
    
    // MARK: - Helper Functions
    
    func getPartnerId(currentUserId: String) -> String? {
        return participants.first(where: { $0 != currentUserId })
    }
    
    func getPartnerDisplayName(currentUserId: String) -> String {
        guard let partnerId = getPartnerId(currentUserId: currentUserId),
              let partnerData = userMetadata?[partnerId] else {
            return "Unknown User"
        }
        return partnerData.displayName
    }
    
    func getPartnerProfilePictureURL(currentUserId: String) -> URL? {
        guard let partnerId = getPartnerId(currentUserId: currentUserId),
              let partnerData = userMetadata?[partnerId] else {
            return nil
        }
        return partnerData.profilePictureURL
    }
}
