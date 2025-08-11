import SwiftUI
import Kingfisher

struct DestinationDetailView: View {
    let destination: Destination
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var bookingVM = BookingViewModel()
    @StateObject private var favoritesVM = FavoritesViewModel()

    @State private var showFullDescription = false
    @State private var showBookingSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content including header image and details
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header Image with overlaid buttons
                    headerImageView
                    
                    // Details Panel that overlaps the image
                    detailsView
                        .offset(y: -40)
                }
            }
            
            // Floating "Book Now" button at the bottom
            bookNowButton
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .onAppear {
            favoritesVM.subscribeToFavorites(for: authVM.user?.uid)
        }
    }

    // MARK: - Subviews

    private var headerImageView: some View {
        ZStack(alignment: .top) {
            KFImage(URL(string: destination.imageUrl))
                .placeholder { Color.secondary.opacity(0.2) }
                .resizable()
                .scaledToFill()
                .frame(height: 400)
                .clipped()
                .overlay(
                    LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.5)]), startPoint: .center, endPoint: .bottom)
                )

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline.bold())
                        .foregroundColor(.primary)
                        .padding(12)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Button {
                    Task { await favoritesVM.toggleFavorite(destination: destination) }
                } label: {
                    Image(systemName: favoritesVM.isFavorite(destination: destination) ? "bookmark.fill" : "bookmark")
                        .font(.headline.bold())
                        .foregroundColor(favoritesVM.isFavorite(destination: destination) ? Color(hex: "#FF7029") : .primary)
                        .padding(12)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.top, 50)
        }
    }

    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title, Location, and Avatar
            HStack {
                VStack(alignment: .leading) {
                    Text(destination.name)
                        .font(.title).bold()
                    Text(destination.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                KFImage(URL(string: destination.participantAvatars?.first ?? ""))
                    .placeholder { Image(systemName: "person.circle.fill").resizable().foregroundColor(.secondary) }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            }

            // Info Row (Rating, Price)
            HStack(spacing: 24) {
                DetailInfoRow(icon: "star.fill", text: "\(String(format: "%.1f", destination.rating)) (\(Int.random(in: 500...2500)) Reviews)", color: .yellow)
                DetailInfoRow(icon: "dollarsign.circle.fill", text: "$\(String(format: "%.0f", destination.price))/Person", color: .green)
                Spacer()
            }

            // Gallery
            if let avatars = destination.participantAvatars, !avatars.isEmpty {
                VStack(alignment: .leading) {
                    Text("Gallery").font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(avatars, id: \.self) { imageUrl in
                                KFImage(URL(string: imageUrl))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
            }

            // About Destination
            VStack(alignment: .leading, spacing: 8) {
                Text("About Destination").font(.headline)
                Text(destination.description ?? "No description available.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(showFullDescription ? nil : 4)
                
                if (destination.description ?? "").count > 150 {
                    Button(showFullDescription ? "Read Less" : "Read More") {
                        withAnimation(.easeInOut) {
                            showFullDescription.toggle()
                        }
                    }
                    .foregroundColor(Color(hex: "#FF7029"))
                    .font(.subheadline.bold())
                }
            }
            
            // Spacer to create space for the floating button
            Spacer().frame(height: 80)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedCorners(radius: 40, corners: [.topLeft, .topRight]))
    }

    private var bookNowButton: some View {
        Button {
            showBookingSheet = true
        } label: {
            Text("Book Now")
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "#24BAEC"))
                .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
        .background(
            // Gradient background for the button area to make it stand out
            LinearGradient(gradient: Gradient(colors: [Color(.systemBackground).opacity(0), Color(.systemBackground)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .sheet(isPresented: $showBookingSheet) {
            BookingView(destination: destination)
                .environmentObject(authVM)
                .environmentObject(bookingVM)
        }
    }
}

// MARK: - Helper Views

private struct DetailInfoRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

private struct RoundedCorners: Shape {
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
