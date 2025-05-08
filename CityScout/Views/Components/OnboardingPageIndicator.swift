import SwiftUI

struct OnboardingPageIndicator: View {
    let pageCount: Int
    let currentIndex: Int

    // MARK: – Your style constants
    private let selectedWidth: CGFloat      = 24
    private let leftNeighborWidth: CGFloat  = 16
    private let rightNeighborWidth: CGFloat = 8
    private let farWidth: CGFloat           = 8
    private let height: CGFloat             = 8
    private let activeColor      = Color(hex: "#24BAEC")
    private let inactiveOpacity: Double = 0.2

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { idx in
                // 1) Compute width with a special case for the first page
                let width: CGFloat = {
                    if idx == currentIndex {
                        // the “current” dot
                        return selectedWidth

                    // a dot immediately to the left
                    } else if idx == currentIndex - 1 {
                        return leftNeighborWidth

                    // a dot immediately to the right
                    } else if idx == currentIndex + 1 {
                        // FIRST PAGE only: treat its sole neighbor as a “left neighbor”
                        if currentIndex == 0 {
                            return leftNeighborWidth
                        } else {
                            return rightNeighborWidth
                        }

                    // everything else
                    } else {
                        return farWidth
                    }
                }()

                Capsule()
                    .fill(activeColor
                            .opacity(idx == currentIndex ? 1 : inactiveOpacity))
                    .frame(width: width, height: height)
                    .cornerRadius(height/2)
            }
        }
    }
}
