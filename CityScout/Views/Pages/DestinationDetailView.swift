//
//  DestinationDetailView.swift
//  CityScout
//
//  Created by Umuco Auca on 20/09/2025.
//

import SwiftUI
import Kingfisher

// Define a common constant for the small screen header height
private let kHeaderHeightFactor: CGFloat = 0.5

struct DestinationDetailView: View {
    // MARK: - Properties
    let destination: Destination
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var bookingVM = BookingViewModel(messageVM: MessageViewModel())
    @StateObject private var favoritesVM = FavoritesViewModel(homeViewModel: HomeViewModel())
    @StateObject private var locationManager = LocationManager()
    
    @EnvironmentObject var messageVM: MessageViewModel

    @State private var showBookingSheet = false
    @State private var showGalleryOverlay = false
    @State private var selectedImageIndex = 0
    @State private var showOnMapView = false
    
    @State private var isShowingFacilitatorChat: Bool = false
    @State private var facilitatorChat: Chat?

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    // MARK: - Body
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // MARK: - Large Screen Layout (e.g., iPad Landscape)
                HStack(spacing: 0) {
                                    // 1. Header Image (left side) - Ensure it fills the height
                                    HeaderImageView(imageUrl: destination.imageUrl)
                                        .frame(width: UIScreen.main.bounds.width * 0.5)
                                        .clipped() // Ensure it respects the frame
                    
                    // 2. Details Card (right side)
                    DetailsCard(
                        destination: destination,
                        onBookNow: { showBookingSheet = true },
                        onImageTapped: { index in
                            self.selectedImageIndex = index
                            withAnimation(.easeInOut) {
                                self.showGalleryOverlay = true
                            }
                        },
                        isShowingFacilitatorChat: $isShowingFacilitatorChat,
                        facilitatorChat: $facilitatorChat
                    )
                    .environmentObject(messageVM)
                    .environmentObject(authVM)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGroupedBackground))
                }
                .overlay(alignment: .topLeading) {
                                    // Header buttons on top of the image
                                    HeaderNavButtons(
                                        isFavorite: favoritesVM.isFavorite(destination: .local(destination)),
                                        onDismiss: { dismiss() },
                                        onToggleFavorite: {
                                        Task { await favoritesVM.toggleFavorite(destination: .local(destination)) }
                                        },
                                        onViewOnMap: {
                                            showOnMapView = true
                                        }
                                    )
                                    // Confine buttons to the image area, and use the existing padding from HeaderNavButtons
                                    .frame(width: UIScreen.main.bounds.width * 0.5, alignment: .top)
                                    .padding(.top, 0) // Remove any extra padding if needed, rely on HeaderNavButtons internal padding
                                }
                                .ignoresSafeArea(.all, edges: .top)
                if showGalleryOverlay {
                    FullScreenGalleryView(
                        imageUrls: destination.galleryImageUrls ?? [],
                        isPresented: $showGalleryOverlay,
                        selectedImageIndex: selectedImageIndex
                    )
                    .transition(.opacity.animation(.easeInOut))
                }
                
            } else {
                // MARK: - Small Screen Layout (iPhone/iPad Portrait)
                ZStack {
                    ZStack {
                        // 1. Apply .top alignment to fix the image position
                        HeaderImageView(imageUrl: destination.imageUrl)
                            .offset(y: 0) // Keep offset at 0
                            .ignoresSafeArea(.all, edges: .top) // Ensure it fills the notch area
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // <-- FIX IS HERE
                        
                        VStack {
                            Spacer() // This pushes the DetailsCard to the bottom
                            DetailsCard(
                                destination: destination,
                                onBookNow: { showBookingSheet = true },
                                onImageTapped: { index in
                                    self.selectedImageIndex = index
                                    withAnimation(.easeInOut) {
                                        self.showGalleryOverlay = true
                                    }
                                },
                                isShowingFacilitatorChat: $isShowingFacilitatorChat,
                                facilitatorChat: $facilitatorChat
                            )
                            .environmentObject(messageVM)
                            .environmentObject(authVM)
                        }
                        
                        // 2. Adjust HeaderNavButtons alignment and padding for the top
                        HeaderNavButtons(
                            isFavorite: favoritesVM.isFavorite(destination: .local(destination)),
                            onDismiss: { dismiss() },
                            onToggleFavorite: {
                            Task { await favoritesVM.toggleFavorite(destination: .local(destination)) }
                            },
                            onViewOnMap: {
                                showOnMapView = true
                            }
                        )
                    }
                    .blur(radius: showGalleryOverlay ? 20 : 0)

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
            }
        }
        // MARK: - Common Modifiers
        .navigationBarHidden(true)
        .onAppear {
            favoritesVM.subscribeToFavorites(for: authVM.user?.uid)
        }
        .fullScreenCover(isPresented: $showBookingSheet) {
            BookingView(destination: destination)
                .environmentObject(authVM)
                .environmentObject(bookingVM)
        }
        .fullScreenCover(isPresented: $showOnMapView) {
            OnMapView(mapType: .destination(destination))
                .environmentObject(locationManager)
        }
        .navigationDestination(isPresented: $isShowingFacilitatorChat) {
            if let chat = facilitatorChat {
                ChatView(chat: chat)
                    .environmentObject(messageVM)
                    .environmentObject(authVM)
            }
        }
    }
}

// MARK: - Details Card (Modified)
private struct DetailsCard: View {
    let destination: Destination
    let onBookNow: () -> Void
    let onImageTapped: (Int) -> Void
    
    @State private var showFullDescription = false
    
    @EnvironmentObject var messageVM: MessageViewModel
    @EnvironmentObject var authVM: AuthenticationViewModel
    @Binding var isShowingFacilitatorChat: Bool
    @Binding var facilitatorChat: Chat?
    
    @State private var showTooltip = false
    
    // NEW: Environment variable for size class
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        // Removed GeometryReader as it's not strictly necessary here and can be simplified
        ScrollView(.vertical, showsIndicators: false) {
            // Only add the spacer on the small screen layout to push content down below the header image
            if horizontalSizeClass != .regular {
                            // Add the height of the image (65%) minus the height of the curved card top (e.g., 40pts)
                            Spacer().frame(height: UIScreen.main.bounds.height * kHeaderHeightFactor - 40)
                        }
            
            VStack(alignment: .leading, spacing: 20) {
                // ... (Content remains the same)
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(destination.name).font(.title2).bold()
                        HStack(spacing: 4) { // NEW: Combined location and new button
                            Text(destination.location).font(.subheadline).foregroundColor(.secondary)
                            if let facilitatorId = destination.partnerId, facilitatorId != authVM.signedInUser?.id {
                                Image(systemName: "headphones.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Color(hex: "#24BAEC"))
                                    .onTapGesture {
                                        Task {
                                            self.facilitatorChat = await messageVM.startNewChat(with: facilitatorId)
                                            self.isShowingFacilitatorChat = true
                                        }
                                    }
                                    .onLongPressGesture(minimumDuration: 0.5) { // NEW: Add long-press gesture
                                        withAnimation {
                                            self.showTooltip = true
                                        }
                                    }
                                    .popover(isPresented: $showTooltip, arrowEdge: .top) { // NEW: Popover for tooltip
                                        Text("Message Partner")
                                            .font(.caption)
                                            .padding(8)
                                            .foregroundColor(.primary)
                                            .cornerRadius(8)
                                            .presentationCompactAdaptation(.popover)
                                    }
                            }
                        }
                    }
                    Spacer()
                    HStack(spacing: -12) {
                        if let avatars = destination.participantAvatars {
                            ForEach(avatars.prefix(3), id: \.self) { imageUrl in
                                AvatarImageView(imageUrl: imageUrl)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                            }
                            if avatars.count > 3 {
                                Text("+\(avatars.count - 3)")
                                    .font(.caption)
                                    .frame(width: 32, height: 32)
                                    .background(Color.secondary.opacity(0.3))
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                
                InfoRow(destination: destination)

                if let imageUrls = destination.galleryImageUrls, !imageUrls.isEmpty {
                    GalleryView(imageUrls: imageUrls, onImageTapped: onImageTapped)
                }

                AboutView(description: destination.description, showFullDescription: $showFullDescription)
                
                BookNowButton(action: onBookNow)
                
                Color.clear.frame(height: 50)
            }
            .padding(24)
            .background(Color(.systemBackground))
            // Only clip the top corners for the small screen layout
            .clipShape(horizontalSizeClass != .regular ? RoundedCorners(radius: 40, corners: [.topLeft, .topRight]) : RoundedCorners(radius: 0, corners: []))
        }
    }
}


// MARK: - Header Image View (Updated)
private struct HeaderImageView: View {
    let imageUrl: String
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        GeometryReader { geometry in
            KFImage(URL(string: imageUrl))
                .placeholder { Color.secondary.opacity(0.2) }
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .ignoresSafeArea()
        }
        // Small screen: Set height to kHeaderHeightFactor (e.g., 65% of screen height)
        .frame(height: horizontalSizeClass != .regular ? UIScreen.main.bounds.height * kHeaderHeightFactor : nil)
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
                
                HStack(spacing: 12) {
                    HeaderButton(iconName: "mappin.and.ellipse", action: onViewOnMap)
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
    let onImageTapped: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gallery")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(imageUrls.indices, id: \.self) { index in
                        Button {
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
private struct FullScreenGalleryView: View {
    let imageUrls: [String]
    @Binding var isPresented: Bool
    @State var selectedImageIndex: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()

            TabView(selection: $selectedImageIndex) {
                ForEach(imageUrls.indices, id: \.self) { index in
                    Image(imageUrls[index])
                        .resizable()
                        .scaledToFit()
                        .tag(index)
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
