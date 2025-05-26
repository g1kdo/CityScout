//
//  ScheduledEvent 2.swift
//  CityScout
//
//  Created by Umuco Auca on 26/05/2025.
//

import SwiftUI
import Foundation

struct ScheduledEvent: Identifiable {
    let id = UUID()
    let date: Date
    let destination: Destination // This will now use your updated Destination model
}
