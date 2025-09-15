//
//  Partner.swift
//  CityScout
//
//  Created by Umuco Auca on 20/09/2025.
//

import Foundation
import FirebaseFirestore

struct Partner: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    let profilePictureURL: URL?
    let partnerDisplayName: String?
    
    // Add any other partner-specific properties here
    // For example:
    // let businessName: String
    // let contactEmail: String
}

