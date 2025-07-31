import SwiftUI

struct DestinationDetailView: View {
    let destination: Destination
    @EnvironmentObject var authVM: AuthenticationViewModel // Needed for userId
    @StateObject private var bookingVM = BookingViewModel() // StateObject for booking logic

    @State private var showFullDescription = false
    @State private var showBookingSheet = false // State to control the booking sheet presentation
    @State private var showOnMapView = false // New state for showing OnMapView

    private let detailCornerRadius: CGFloat = 24
    private let headerHeight: CGFloat = 350

    var body: some View {
        ZStack(alignment: .top) {
            // 1. Fullscreen header image (now dynamic)
            AsyncImage(url: URL(string: destination.imageUrl)) { phase in
                switch phase {
                case .empty:
                    Color.gray.opacity(0.1)
                        .frame(width: UIScreen.main.bounds.width, height: headerHeight)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width, height: headerHeight)
                        .clipped()
                case .failure:
                    Color.gray
                        .frame(width: UIScreen.main.bounds.width, height: headerHeight)
                @unknown default:
                    EmptyView()
                }
            }
            .ignoresSafeArea(edges: .top)
            .onTapGesture {
                showOnMapView = true // Present OnMapView when image is tapped
            }
            
            // "Details" text at the top, mimicking the image
            Text("Details")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, safeAreaTop() + 10)
                .frame(maxWidth: .infinity, alignment: .center)

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
                            // Assuming 'participantAvatars' now contains URLs
                            if let firstAvatarUrl = destination.participantAvatars?.first, let url = URL(string: firstAvatarUrl) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 44, height: 44)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .frame(width: 44, height: 44)
                                            .foregroundColor(.gray)
                                            .clipShape(Circle())
                                    }
                                }
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(.gray)
                                    .clipShape(Circle())
                            }
                        }

                        // Gallery thumbnails
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                if let avatars = destination.participantAvatars {
                                    ForEach(avatars, id: \.self) { imageUrl in
                                        AsyncImage(url: URL(string: imageUrl)) { phase in
                                            if let image = phase.image {
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 60, height: 60)
                                                    .cornerRadius(12)
                                            } else {
                                                Color.gray.opacity(0.2)
                                                    .frame(width: 60, height: 60)
                                                    .cornerRadius(12)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }

                        // About section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About Destination")
                                .font(.headline)
                            Text(showFullDescription ? (destination.description ?? "No description available.") : shortDescription)
                                .font(.body)
                                .foregroundColor(.gray)
                            if !showFullDescription && (destination.description ?? "").count > 150 {
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
                Button(action: {
                    showBookingSheet = true // Present the booking sheet
                }) {
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
        .ignoresSafeArea() // Ensure the ZStack ignores safe areas for header image
        .sheet(isPresented: $showBookingSheet) {
            // Present the BookingView as a sheet
            BookingView(destination: destination)
                .environmentObject(authVM) // Pass authVM to BookingView
                .environmentObject(bookingVM) // Pass bookingVM to BookingView
        }
        .fullScreenCover(isPresented: $showOnMapView) {
            OnMapView(destination: destination) // Present OnMapView as a full-screen cover
        }
    }

    private var shortDescription: String {
        let text = destination.description ?? "No description available."
        if text.count > 150 {
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

// Shape to round specific corners (Existing, keep this)
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
