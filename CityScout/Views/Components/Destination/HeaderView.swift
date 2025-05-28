//
//  HeaderView.swift
//  CityScout
//
//  Created by Umuco Auca on 28/05/2025.
//


import SwiftUI

struct HeaderView: View {
    @Environment(\.dismiss) var dismiss // To dismiss the current presentation
    let title: String
    var showBackButton: Bool = true // Option to show/hide back button

    var body: some View {
        HStack {
            if showBackButton {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(5)
                        .background(Circle().fill(Color(.systemGray6)).frame(width: 44, height: 44))
                }
            } else {

                Spacer()
                    .frame(width: 44)
            }

            Spacer()

            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Spacer()


            Spacer()
                .frame(width: 44)
        }
        .padding(.horizontal)
    }
}

#Preview {
    HeaderView(title: "Popular Places")
}

#Preview {
    HeaderView(title: "Favorite Places", showBackButton: false)
}
