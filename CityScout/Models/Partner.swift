//
//  Partner.swift
//  CityScout
//
//  Created by Umuco Auca on 20/09/2025.
//

//import Foundation
//import FirebaseFirestore
//
//struct Partner: Codable, Identifiable {
//    @DocumentID var id: String?
//    let name: String
//    let profilePictureURL: URL?
//    let partnerDisplayName: String?
//    let partnerEmail: String
//    
//    //Status
//    var isOnline: Bool? = false
//    var lastSeen: Timestamp?
//    
//}


import Foundation
import FirebaseFirestore

struct Partner: Codable, Identifiable {
    @DocumentID var id: String? // Will hold the Firebase Auth UID after activation
    
    // Core Pre-created Fields (Required for initial lookup)
    let partnerEmail: String
    
    // Fields collected during the first "Sign In" / Activation
    var partnerDisplayName: String?
    var phoneNumber: String?
    var location: String? 
    var profilePictureURL: URL?
    
    // Secure Credential Fields (Set only upon activation)
    var sessionKeyHash: String? // Hashed auto-generated key
    var sessionKeySalt: String? // Salt used for hashing
    
    // Status
    let name: String

    var isOnline: Bool? = false
    var lastSeen: Timestamp?
    
    // Helper to check if the partner account is fully activated in Firebase Auth
    var isActivated: Bool {
        return id != nil && sessionKeyHash != nil
    }
}


