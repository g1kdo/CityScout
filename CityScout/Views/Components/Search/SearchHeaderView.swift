//
//  SearchHeaderView.swift
//  CityScout
//
//  Created by Umuco Auca on 28/05/2025.
//


import SwiftUI

struct SearchHeaderView: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let onCancelTapped: (() -> Void)?

    var body: some View {
        HStack {
//            Button(action: {
//                dismiss()
//            }) {
//                Image(systemName: "chevron.left")
//                    .font(.headline)
//                    .foregroundColor(.primary)
//                    .padding(5)
//                    .background(Circle().fill(Color(.systemGray6)).frame(width: 44, height: 44))
//            }

            //Spacer()

            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Spacer()

            Button(action: {
                onCancelTapped?()
                dismiss()
            }) {
                Text("Cancel")
                    .font(.callout)
                    .foregroundColor(Color(hex: "#FF7029"))
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    SearchHeaderView(title: "Search", onCancelTapped: {})
}
