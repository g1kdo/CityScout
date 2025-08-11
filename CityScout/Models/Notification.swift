//
//  Notification.swift
//  CityScout
//
//  Created by Umuco Auca on 07/08/2025.
//


// Models/Notification.swift
import Foundation
import FirebaseFirestore

struct Notification: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool
    var isArchived: Bool
    var imageUrl: String?
    
    // Equatable conformance for SwiftUI to identify changes
    static func == (lhs: Notification, rhs: Notification) -> Bool {
        lhs.id == rhs.id
    }
}
