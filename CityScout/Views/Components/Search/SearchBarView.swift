//
//  SearchBarView.swift
//  CityScout
//
//  Created by Umuco Auca on 28/05/2025.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    let placeholder: String
    let onSearchTapped: (() -> Void)? // Optional action for when search icon is tapped
    let onMicrophoneTapped: (() -> Void)? // Optional action for when microphone icon is tapped

    init(searchText: Binding<String>, placeholder: String = "Search Places", onSearchTapped: (() -> Void)? = nil, onMicrophoneTapped: (() -> Void)? = nil) {
        _searchText = searchText
        self.placeholder = placeholder
        self.onSearchTapped = onSearchTapped
        self.onMicrophoneTapped = onMicrophoneTapped
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .onTapGesture {
                    onSearchTapped?()
                }

            TextField(placeholder, text: $searchText)
                .font(.body)
                .foregroundColor(.primary)
                .autocorrectionDisabled() // Often desired for search fields

            if !searchText.isEmpty {
                Button(action: {
                    searchText = "" // Clear text
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }

            // Microphone icon
            Button(action: {
                onMicrophoneTapped?() // Trigger microphone action
            }) {
                Image(systemName: "mic.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 15)
        .background(Color(.systemGray6)) // Light gray background
        .cornerRadius(12)
        .padding(.horizontal) // Padding from the screen edges
    }
}

#Preview {
    @State var text = ""
    return SearchBarView(searchText: $text)
}
