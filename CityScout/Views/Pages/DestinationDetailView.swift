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
            
            // "Details" text at the top, mimicking the image
            Text("Details")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, safeAreaTop() + 10) // Adjust padding to match image
                .frame(maxWidth: .infinity, alignment: .center) // Center the text


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
                            // Assuming 'LocalAvatarImage' is the image of the person
                            Image("LocalAvatarImage") // Replace with actual image name if different
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                        }

                        // Info row: location, rating, price
                        HStack(spacing: 8) { // Reduced spacing
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.subheadline) // Adjust font size
                                    .foregroundColor(.gray) // Adjust color
                                Text(destination.location)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            // Removed spacer here to keep elements close
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", destination.rating))
                                    .font(.subheadline)
                                Text("(\(2498))") // Hardcoded 2498 as per image
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer() // Push price to the right
                            Text("$59/Person")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "#24BAEC"))
                        }

                        // Gallery thumbnails
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // Assuming your 'img1', 'img2', etc., are the images for the thumbnails
                                ForEach(0..<min(destination.participantAvatars.count, 5), id: \.self) { index in
                                    Image(destination.participantAvatars[index])
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(12)
                                }
                                if destination.participantAvatars.count > 5 {
                                    let more = destination.participantAvatars.count - 5
                                    Text("+\(more)")
                                        .font(.subheadline).bold()
                                        .frame(width: 60, height: 60)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                        .foregroundColor(.black) // Ensure text is visible
                                }
                            }
                            .padding(.vertical, 8) // This padding looks good
                        }

                        // About section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About Destination")
                                .font(.headline)
                            Text(showFullDescription ? (destination.description ?? "") : shortDescription)
                                .font(.body)
                                .foregroundColor(.gray)
                            if !showFullDescription && (destination.description ?? "").count > 200 { // Only show "Read More" if description is actually truncated
                                Button("Read More") { showFullDescription = true }
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "#FF7029")) // Keeping existing color
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
        .ignoresSafeArea() // Ignore safe area for the whole ZStack to allow image to go to very top
    }

    private var shortDescription: String {
        let text = destination.description ?? "No description available."
        // Using a hardcoded length for truncation based on the image's appearance
        if text.count > 150 && !showFullDescription { // Adjusted truncation length
            let idx = text.index(text.startIndex, offsetBy: 150)
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
        imageName: "EcoPark", // Changed to a more generic name for preview image
        rating: 4.7,
        location: "Kigali, Nyandungu",
        participantAvatars: ["thumb1","thumb2","thumb3","thumb4","thumb5","thumb6"], // Example image names
        description: "You will get a complete travel package on the beaches, including airline tickets, recommended hotel rooms, transportation, and everything you need for your holiday to the Greek Islands, for example. Explore the stunning landscapes and diverse wildlife that make this eco park a truly unique destination. Perfect for nature lovers and adventurers alike."
    ))
}
