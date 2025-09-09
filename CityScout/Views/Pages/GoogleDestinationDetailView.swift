//
//  GoogleDestinationDetailView.swift
//  CityScout
//
//  Created by Umuco Auca on 03/09/2025.
//

import SwiftUI
import GooglePlaces
import Kingfisher

struct GoogleDestinationDetailView: View {
    // MARK: - Properties
    let googleDestination: GoogleDestination
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var favoritesVM = FavoritesViewModel()
    @StateObject private var locationManager = LocationManager()
    
    @State private var showGalleryOverlay = false
    @State private var selectedImageIndex = 0
    
    @State private var showOnMapView = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Main ZStack to contain all content layers
            ZStack {
                // Layer 1: The full-screen background image, with a vertical offset
                GooglePlacesImageView(photoMetadata: googleDestination.photoMetadata)
                    .offset(y: -200) // Pushes the image up slightly
                
                // Layer 2: The details card, pushed to the bottom of the screen
                VStack {
                    Spacer() // Pushes the content to the bottom
                    GoogleDetailsCard(
                        googleDestination: googleDestination,
                        onImageTapped: { index in
                            self.selectedImageIndex = index
                            withAnimation(.easeInOut) {
                                self.showGalleryOverlay = true
                            }
                        }
                    )
                }
                
                // Layer 3: The header buttons, positioned at the top
                HeaderNavButtons(
                    isFavorite: favoritesVM.isFavorite(destination: .google(googleDestination, sessionToken: nil)),
                    onDismiss: { dismiss() },
                    onToggleFavorite: {
                        Task { await favoritesVM.toggleFavorite(destination: .google(googleDestination, sessionToken: nil)) }
                    },
                    onViewOnMap: { showOnMapView = true }
                )
            }
            .blur(radius: showGalleryOverlay ? 20 : 0) // Dims and blurs the background
            
            // --- TOPMOST LAYER FOR GALLERY ---
            if showGalleryOverlay {
                FullScreenGalleryView(
                    photoMetadata: googleDestination.galleryImageUrls!,
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
        .fullScreenCover(isPresented: $showOnMapView) {
            OnMapView(mapType: .googleDestination(googleDestination))
                .environmentObject(locationManager)
        }
    }
}

// MARK: - Corrected Google Details Card
private struct GoogleDetailsCard: View {
    let googleDestination: GoogleDestination
    let onImageTapped: (Int) -> Void
    
    @State private var showFullDescription = false
    @Environment(\.openURL) var openURL
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header section with name and location
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(googleDestination.name).font(.title2).bold()
                        Text(googleDestination.location).font(.subheadline).foregroundColor(.secondary)
                    }
                    Spacer()
                    // No participant avatars for Google Destinations
                }
                
                // Info row
                GoogleInfoRow(googleDestination: googleDestination)
                
                // Gallery section
                if let photoMetadata = googleDestination.galleryImageUrls, !photoMetadata.isEmpty {
                    GalleryView(photoMetadata: photoMetadata, onImageTapped: onImageTapped)
                }
                
                // Description section
                if let description = googleDestination.description {
                    AboutView(description: description, showFullDescription: $showFullDescription)
                }
                
                // Website button
                if let websiteURL = googleDestination.websiteURL, let url = URL(string: websiteURL) {
                    Link("Visit Website", destination: url)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#24BAEC"))
                        .cornerRadius(16)
                }
                
                // Add some padding to prevent the scroll view from cutting off the bottom content
                Color.clear.frame(height: 50)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .clipShape(RoundedCorners(radius: 40, corners: [.topLeft, .topRight]))
        }
        .frame(height: UIScreen.main.bounds.height * 0.6)
    }
}

// MARK: - Google Info Row
private struct GoogleInfoRow: View {
    let googleDestination: GoogleDestination
    
    var body: some View {
        HStack {
            if let rating = googleDestination.rating {
                DetailInfoRow(icon: "star.fill", text: "\(String(format: "%.1f", rating))", color: .yellow)
            }
            Spacer()
            if let priceLevel = googleDestination.priceLevel {
                if priceLevel <= 0 {
                    DetailInfoRow(icon: "dollarsign", text: "Free", color: .green)
                } else {
                    DetailInfoRow(icon: "dollarsign", text: String(repeating: "$", count: priceLevel), color: .green)
                }
            } else {
                DetailInfoRow(icon: "dollarsign", text: "N/A", color: .secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Gallery View for Google Places
private struct GalleryView: View {
    let photoMetadata: [GMSPlacePhotoMetadata]
    let onImageTapped: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gallery")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(photoMetadata.indices, id: \.self) { index in
                        Button {
                            onImageTapped(index)
                        } label: {
                            GooglePlaceImageLoader(photoMetadata: photoMetadata[index])
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
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
        
        // MARK: - New Image Loader View
        // This view fetches the UIImage from GMSPlacePhotoMetadata
        private struct GooglePlaceImageLoader: View {
            let photoMetadata: GMSPlacePhotoMetadata?
            @State private var image: UIImage? = nil
            
            var body: some View {
                Group {
                    if let uiImage = image {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        // Placeholder while image is loading
                        Color.secondary.opacity(0.1)
                    }
                }
                .onAppear {
                    fetchImage()
                }
            }
            
            private func fetchImage() {
                guard let metadata = photoMetadata else { return }
                
                GMSPlacesClient.shared().loadPlacePhoto(metadata) { (photo, error) in
                    if let error = error {
                        print("Error loading place photo: \(error.localizedDescription)")
                        return
                    }
                    
                    if let photo = photo {
                        self.image = photo
                    }
                }
            }
        }
        
        // --- UPDATED HELPER VIEW ---
        // This is the full-screen gallery view with the corrected dismiss logic.
        private struct FullScreenGalleryView: View {
            let photoMetadata: [GMSPlacePhotoMetadata]
            @Binding var isPresented: Bool
            @State var selectedImageIndex: Int
            
            var body: some View {
                ZStack {
                    Color.black.opacity(0.8).ignoresSafeArea()
                    
                    TabView(selection: $selectedImageIndex) {
                        ForEach(photoMetadata.indices, id: \.self) { index in
                            // Use the new GooglePlaceImageLoader here
                            GooglePlaceImageLoader(photoMetadata: photoMetadata[index])
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
