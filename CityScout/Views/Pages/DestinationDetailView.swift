import SwiftUI

struct DestinationDetailView: View {
    let destination: Destination
    @State private var showFullDescription = false
    private let detailCornerRadius: CGFloat = 24
    private let headerHeight: CGFloat = 350

    var body: some View {
        ZStack(alignment: .top) {
            // 1. Fullscreen header image
            Image(destination.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width, height: headerHeight)
                .clipped()
                .ignoresSafeArea(edges: .top)

            // Navigation bar overlay with title
            HStack {
                Button(action: { /* pop navigation */ }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(Color.black.opacity(0.3)))
                }
                Spacer()
                Text("Details")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: { /* bookmark action */ }) {
                    Image(systemName: "bookmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(Color.black.opacity(0.3)))
                }
            }
            .padding(.horizontal)
            .padding(.top, safeAreaTop())

            // 2. Detail content panel overlapping image
            VStack(spacing: 0) {
                Spacer().frame(height: headerHeight - detailCornerRadius)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title & avatar
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(destination.name)
                                    .font(.title2).bold()
                                Text(destination.location)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            AvatarViewLocal(imageName: "LocalAvatarImage", size: 44)
                        }

                        // Info row: location, rating, price
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.and.ellipse")
                                Text(destination.location)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", destination.rating))
                                    .font(.subheadline)
                                Text("(\(destination.participantAvatars.count))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text("$59/Person")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "#24BAEC"))
                        }

                        // Gallery thumbnails with +N
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                let items = destination.participantAvatars.prefix(4)
                                ForEach(Array(items), id: \.self) { img in
                                    Image(img)
                                        .resizable()
                                        .aspectRatio(1, contentMode: .fill)
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(12)
                                }
                                if destination.participantAvatars.count > 4 {
                                    let more = destination.participantAvatars.count - 4
                                    Text("+\(more)")
                                        .font(.subheadline).bold()
                                        .frame(width: 60, height: 60)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.vertical, 8)
                        }

                        // About section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About Destination")
                                .font(.headline)
                            Text(showFullDescription ? (destination.description ?? "") : shortDescription)
                                .font(.body)
                                .foregroundColor(.gray)
                            if !showFullDescription {
                                Button("Read More") { showFullDescription = true }
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "#FF7029"))
                            }
                        }

                        Spacer().frame(height: 0)
                    }
                    .padding()
                    .background(
                        Color.white
                            .clipShape(RoundedCorners(radius: detailCornerRadius, corners: [.topLeft, .topRight]))
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -4)
                }

                // Book Now button outside container
                Button(action: { /* book action */ }) {
                    Text("Book Now")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#24BAEC"))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                .padding(.bottom, safeAreaBottom())
            }
        }
    }

    private var shortDescription: String {
        let text = destination.description ?? "No description available."
        if text.count > 200 && !showFullDescription {
            let idx = text.index(text.startIndex, offsetBy: 200)
            return String(text[..<idx]) + "..."
        }
        return text
    }

    private func safeAreaTop() -> CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
    }

    private func safeAreaBottom() -> CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0
    }
}

// Shape to round specific corners
struct RoundedCorners: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    DestinationDetailView(destination: Destination(
        name: "Nyandungu Eco Park",
        imageName: "Nyandungu",
        rating: 4.7,
        location: "Kigali, Nyandungu",
        participantAvatars: ["img1","img2","img3","img4","img5","img6"],
        description: "You will get a complete travel package on the beaches..."
    ))
}
