import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color(hex: "#24BAEC"))
            .cornerRadius(10)
        }
        .disabled(disabled || isLoading)
    }
}


