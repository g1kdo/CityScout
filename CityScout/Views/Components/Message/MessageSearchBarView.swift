//
//  MessageSearchBarView.swift
//  CityScout
//
//  Created by Umuco Auca on 04/11/2025.
//

import SwiftUI

struct MessageSearchBarView: View {
    @Binding var searchText: String
    let placeholder: String
    
    // The initializer is simplified as we removed microphone and search actions
    init(searchText: Binding<String>, placeholder: String = "Search for chats & messages") {
        _searchText = searchText
        self.placeholder = placeholder
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField(placeholder, text: $searchText)
                .font(.body)
                .foregroundColor(.primary)
                .autocorrectionDisabled() 

            // Clear button
            if !searchText.isEmpty {
                Button(action: {
                    searchText = "" // Clear text
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 15)
        .background(Color(.systemGray5)) // Light gray background
        .cornerRadius(12)
        .padding(.horizontal) // Padding from the screen edges
    }
}
