import SwiftUI
import Kingfisher

struct DestinationDetailView: View {
    // MARK: - Properties
    let destination: Destination
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var bookingVM = BookingViewModel()
    @StateObject private var favoritesVM = FavoritesViewModel()
    @StateObject private var locationManager = LocationManager()

    @State private var showBookingSheet = false
    
    // --- STATE VARIABLES FOR GALLERY ---
    @State private var showGalleryOverlay = false
    @State private var selectedImageIndex = 0
    @State private var showOnMapView = false

    // MARK: - Body
    var body: some View {
        ZStack {
            // This ZStack contains the main page content.
            ZStack {
                // Layer 1: The full-screen background image
                HeaderImageView(imageUrl: destination.imageUrl)
                    .offset(y: -200)
                
                // Layer 2: The details card and button, pushed to the bottom
                VStack {
                    Spacer()
                    DetailsCard(
                        destination: destination,
                        onBookNow: { showBookingSheet = true },
                        onImageTapped: { index in
                            // This closure is called from the GalleryView when a thumbnail is tapped.
                            self.selectedImageIndex = index
                            withAnimation(.easeInOut) {
                                self.showGalleryOverlay = true
                            }
                        }
                    )
                }
                
            HeaderNavButtons(
               isFavorite: favoritesVM.isFavorite(destination: destination),
               onDismiss: { dismiss() },
               onToggleFavorite: {
                 Task { await favoritesVM.toggleFavorite(destination: destination) }
                 },
                onViewOnMap: {
                showOnMapView = true
             }
        )
        }
      .blur(radius: showGalleryOverlay ? 20 : 0) // Dims and blurs the background

            // --- NEW TOPMOST LAYER FOR GALLERY ---
            // This appears on top of everything when showGalleryOverlay is true.
            if showGalleryOverlay {
                FullScreenGalleryView(
                    imageUrls: destination.galleryImageUrls ?? [],
                    isPresented: $showGalleryOverlay,
                    selectedImageIndex: selectedImageIndex
                )
                .transition(.opacity.animation(.easeInOut))
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .background(Color(.systemGroupedBackground))
        .onAppear {
                    favoritesVM.subscribeToFavorites(for: authVM.user?.uid)
                }
        .fullScreenCover(isPresented: $showBookingSheet) {
            BookingView(destination: destination)
                .environmentObject(authVM)
                .environmentObject(bookingVM)
        }
        .fullScreenCover(isPresented: $showOnMapView) {
                    OnMapView(destination: destination)
                        .environmentObject(locationManager)
                }
    }
}

// MARK: - Details Card (New Structure)
private struct DetailsCard: View {
    let destination: Destination
    let onBookNow: () -> Void
    // New closure to handle thumbnail taps
    let onImageTapped: (Int) -> Void
    
    @State private var showFullDescription = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                Spacer().frame(height: 300)
                
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(destination.name).font(.title2).bold()
                            Text(destination.location).font(.subheadline).foregroundColor(.secondary)
                        }
                        Spacer()
                       HStack(spacing: -12) {
                            if let avatars = destination.participantAvatars {
                                ForEach(avatars.prefix(3), id: \.self) { imageUrl in
                                    AvatarImageView(imageUrl: imageUrl)
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2)) // Use adaptive background for stroke
                                }
                                if avatars.count > 3 {
                                    Text("+\(avatars.count - 3)")
                                        .font(.caption)
                                        .frame(width: 32, height: 32)
                                        .background(Color.secondary.opacity(0.3)) // Replaced .gray
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                    

                    InfoRow(destination: destination)

                    // The GalleryView now receives the onImageTapped closure.
                    if let imageUrls = destination.galleryImageUrls, !imageUrls.isEmpty {
                        GalleryView(imageUrls: imageUrls, onImageTapped: onImageTapped)
                    }

                    AboutView(description: destination.description, showFullDescription: $showFullDescription)
                    
                    BookNowButton(action: onBookNow)
                        .padding(.bottom, 150)
                }
                .padding(24)
                .background(Color(.systemBackground))
                .clipShape(RoundedCorners(radius: 40, corners: [.topLeft, .topRight]))
            }
        }
    }
}


// MARK: - Header Image View
private struct HeaderImageView: View {
    let imageUrl: String

    var body: some View {
        KFImage(URL(string: imageUrl))
            .placeholder { Color.secondary.opacity(0.2) }
            .resizable()
            .scaledToFill()
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 2)
            .clipped()
            .ignoresSafeArea()
    }
}

// MARK: - Header Navigation Buttons
private struct HeaderNavButtons: View {
    let isFavorite: Bool
    let onDismiss: () -> Void
    let onToggleFavorite: () -> Void
    let onViewOnMap: () -> Void

    var body: some View {
        VStack {
            HStack {
                HeaderButton(iconName: "chevron.left", action: onDismiss)
                    .foregroundColor(.white)
                Spacer()
                
                Text("Details").font(.headline).foregroundColor(.white)
                
                Spacer()
                
                // New map button and existing favorite button in a single HStack
                HStack(spacing: 12) {
                    HeaderButton(iconName: "map.fill", action: onViewOnMap)
                        .foregroundColor(.white)
                    HeaderButton(iconName: isFavorite ? "bookmark.fill" : "bookmark", action: onToggleFavorite)
                        .foregroundColor(isFavorite ? .red : .white)
                    
                }
            }
            .padding(.horizontal)
            .padding(.top, 50)
            Spacer()
        }
    }
}




// MARK: - Info Row View
private struct InfoRow: View {
    let destination: Destination
    var body: some View {
        HStack {
            DetailInfoRow(icon: "mappin.and.ellipse", text: destination.location, color: .secondary)
            Spacer()
            DetailInfoRow(icon: "star.fill", text: "\(String(format: "%.1f", destination.rating)) (\(Int.random(in: 500...2500)))", color: .yellow)
            Spacer()
            DetailInfoRow(icon: "dollarsign", text: "\(String(format: "%.2f", destination.price))/Person", color: .green)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Gallery View
private struct GalleryView: View {
    let imageUrls: [String]
    // New closure property
    let onImageTapped: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gallery")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // We now iterate over the indices to pass the correct index on tap.
                    ForEach(imageUrls.indices, id: \.self) { index in
                        Button {
                            // Call the closure with the index of the tapped image.
                            onImageTapped(index)
                        } label: {
                            ZStack {
                                Color.secondary.opacity(0.1)
                                Image(imageUrls[index])
                                    .resizable()
                                    .scaledToFill()
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
    }
}


// MARK: - About View
private struct AboutView: View {
    let description: String?
    @Binding var showFullDescription: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About Destination").font(.headline)
            Text(description ?? "No description available.")
                .font(.subheadline).foregroundColor(.secondary)
                .lineLimit(showFullDescription ? nil : 3)
            
            if (description ?? "").count > 120 {
                Button(showFullDescription ? "Read Less" : "Read More") {
                    withAnimation(.easeInOut) { showFullDescription.toggle() }
                }
                .foregroundColor(Color(hex: "#FF7029")).font(.subheadline.bold())
            }
        }
    }
}

// MARK: - Book Now Button View
private struct BookNowButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Book Now")
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "#24BAEC"))
                .cornerRadius(16)
        }
    }
}


// MARK: - Reusable Helper Components
private struct HeaderButton: View {
    let iconName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.headline.bold())
                .padding(12)
                .background(.thinMaterial)
                .clipShape(Circle())
        }
    }
}

private struct DetailInfoRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(color)
            Text(text).font(.caption).foregroundColor(.secondary)
        }
    }
}

private struct RoundedCorners: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// --- UPDATED HELPER VIEW ---
// This is the full-screen gallery view with the corrected dismiss logic.
private struct FullScreenGalleryView: View {
    let imageUrls: [String]
    @Binding var isPresented: Bool
    @State var selectedImageIndex: Int

    var body: some View {
        // --- CHANGE IS HERE ---
        // The dismiss gesture is now on the ZStack itself.
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()

            TabView(selection: $selectedImageIndex) {
                ForEach(imageUrls.indices, id: \.self) { index in
                    Image(imageUrls[index])
                        .resizable()
                        .scaledToFit()
                        .tag(index)
                        // This empty gesture on the image itself
                        // prevents the ZStack's gesture from firing
                        // when the user taps or swipes the image.
                        .onTapGesture {}
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
        .onTapGesture {
            withAnimation(.easeInOut) {
                isPresented = false
            }
        }
    }
}
private struct AvatarImageView: View {
    let imageUrl: String?
    @State private var imageLoadFailed: Bool = false

    var body: some View {
        Group {
            if imageLoadFailed {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.secondary)
            } else {
                KFImage(URL(string: imageUrl ?? ""))
                    .onFailure { error in
                        print("Failed to load avatar image: \(error.localizedDescription)")
                        self.imageLoadFailed = true
                    }
                    .onSuccess { result in
                        self.imageLoadFailed = false
                    }
                    .placeholder {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.secondary)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
