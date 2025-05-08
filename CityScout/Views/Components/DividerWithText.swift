import SwiftUI

struct DividerWithText: View {
    let text: String

    var body: some View {
        HStack {
            Capsule().frame(height: 1).foregroundColor(.gray.opacity(0.5))
            Text(text)
                .font(.footnote)
                .foregroundColor(.gray)
            Capsule().frame(height: 1).foregroundColor(.gray.opacity(0.5))
        }
    }
}
