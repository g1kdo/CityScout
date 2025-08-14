

import SwiftUI

struct SearchHeaderView: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let onCancelTapped: (() -> Void)?

    var body: some View {
        HStack {
        

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


