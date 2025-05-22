import SwiftUI

struct DestinationDetailView: View {
    let destination: Destination
    @State private var showFullDescription = false

    var body: some View {
        VStack(spacing: 0) {
            // 1. Top image and nav bar overlay
            ZStack(alignment: .top) {
                Image(destination.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 350)
                    .clipped()

                // Custom nav bar
                HStack {
                    Button(action: { /* pop navigation */ }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                    Text("Details")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    NotificationBell(unreadCount: 0)
                        .padding()
                }
                .padding(.top, safeAreaTop())
            }

            // 2. Content ScrollView
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Title and avatar
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(destination.name)
                                .font(.title2).bold()
                            Text(destination.location)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        // Reuse AvatarViewLocal or AsyncAvatar
                        AvatarViewLocal(imageName: "LocalAvatarImage", size: 44)
                    }

                    // Stats row
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
                            Text("(\(destination.participantAvatars.count * 37))") // sample count
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("$59/Person")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#24BAEC"))
                    }

                    // Gallery Thumbnails
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(destination.participantAvatars, id: \.self)
                            { img in
                                Image(img)
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // About Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About Destination")
                            .font(.headline)
                        Text(shortDescription)
                            .font(.body)
                            .foregroundColor(.gray)
                        if !showFullDescription {
                            Button("Read More") { showFullDescription = true }
                                .font(.subheadline).foregroundColor(Color(hex: "#FF7029"))
                        }
                    }

                    // Book Now Button
                    Button(action: { /* book action */ }) {
                        Text("Book Now")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#24BAEC"))
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -4)
                )
                .offset(y: -24)
            }
        }
        .ignoresSafeArea(edges: .top)
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
}

#Preview {
    DestinationDetailView(destination: Destination(
        name: "Nyandungu Eco Park",
        imageName: "Nyandungu",
        rating: 4.7,
        location: "Kigali, Nyandungu",
        participantAvatars: ["Nyandungu","Nyandungu","Nyandungu","Nyandungu","Nyandungu","Nyandungu","Nyandungu",    "Nyandungu","Nyandungu","Nyandungu"],
        description: "You will get a complete travel package on the beaches. Packages in the form of airline tickets, recommended Hotel rooms, Transportation, Have you ever been on holiday to the Greek ETC..."
    ))
}
