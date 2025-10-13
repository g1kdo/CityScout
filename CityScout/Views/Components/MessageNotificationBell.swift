//
//  MessageNotificationBell.swift
//  CityScout
//
//  Created by Umuco Auca on 13/10/2025.
//


import SwiftUI

struct MessageNotificationBell: View {
    let unreadCount: Int

    var body: some View {
        ZStack {
            // Message icon centered
            Image(systemName: "message")
                .font(.system(size: 20))
                .foregroundColor(.primary)
            
        }
        .overlay(alignment: .topTrailing) {
            if unreadCount > 0 {
                Text(unreadCount > 99 ? "99+" : "\(unreadCount)")
                    .font(.caption2).bold()
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Circle().fill(Color.red))
                    .offset(x: 8, y: -8)
            }
        }
    }
}
