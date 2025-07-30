//
//  ScheduledEvent 2.swift
//  CityScout
//
//  Created by Umuco Auca on 30/07/2025.
//

import SwiftUI
import Foundation

struct ScheduledEvent: Identifiable, Codable {
    var id: String = UUID().uuidString // For Identifiable
    let date: Date
    let destination: Destination

    // Add a Custom Initializer if needed for decoding from Firestore
    // For direct Firestore document decoding, ensure all properties are Codable.
    // However, if fetching from a 'bookings' collection, you might need to map fields.
}
