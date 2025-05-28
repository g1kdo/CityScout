//
//  ScheduledEvent.swift
//  CityScout
//
//  Created by Umuco Auca on 28/05/2025.
//


import SwiftUI
import Foundation

struct ScheduledEvent: Identifiable {
    let id = UUID()
    let date: Date
    let destination: Destination
}
