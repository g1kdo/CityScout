//
//  GoogleDestinationDetailView.swift
//  CityScout
//
//  Created by Umuco Auca on 03/09/2025.
//

import SwiftUI
import GooglePlaces
import Kingfisher

// Define a common constant for the small screen header height
private let kHeaderHeightFactor: CGFloat = 0.5

struct GoogleDestinationDetailView: View {
    // MARK: - Properties
    let googleDestination: GoogleDestination
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var favoritesVM = FavoritesViewModel(homeViewModel: HomeViewModel())
    @StateObject private var locationManager = LocationManager()
    
    // REMOVED: horizontalSizeClass is no longer needed
    
    @State private var showGalleryOverlay = false
    @State private var selectedImageIndex = 0
    @State private var showOnMapView = false

    // MARK: - Body
    var body: some View {
        // UPDATED: Removed Group and if/else logic to use ONE layout
        ZStack {
            ZStack {
                // Layer 1: The non-scrollable header image
                // Assuming GooglePlacesImageView is defined in its own file and sets its height using kHeaderHeightFactor
                GooglePlacesImageView(photoMetadata: googleDestination.photoMetadata)
                    .offset(y: 0)
                    .ignoresSafeArea(.all, edges: .top)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // Align to top

                // Layer 2: The scrollable card view
                // *** FIX 2 START: Add GeometryReader ***
                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: false) {
                        // This VStack wraps the spacer and the content
                        VStack(spacing: 0) {
                            // This spacer pushes the card content down to start below the header image
                            Spacer()
                                .frame(height: UIScreen.main.bounds.height * kHeaderHeightFactor - 40) // Use factor and account for rounded corner
                            
                            // The details card itself
                            GoogleDetailsCard(
                                googleDestination: googleDestination,
                                onImageTapped: { index in
                                    self.selectedImageIndex = index
                                    withAnimation(.easeInOut) {
                                        self.showGalleryOverlay = true
                                    }
                                }
                            )
                            // *** FIX 2: Apply background and minHeight to the card ***
                            .frame(maxWidth: .infinity) // Ensure it fills width
                            // Set minHeight to stretch background to bottom
                            .frame(minHeight: geometry.size.height - (UIScreen.main.bounds.height * kHeaderHeightFactor - 40))
                            .background(Color(.systemBackground))
                            .clipShape(RoundedCorners(radius: 40, corners: [.topLeft, .topRight]))
                        }
                    }
                    .ignoresSafeArea()
                } // *** FIX 2 END: End GeometryReader ***
                                
                // Layer 3: The header buttons, always on top
                GoogleHeaderNavButtons(
                    onDismiss: { dismiss() },
                    onViewOnMap: { showOnMapView = true }
                )
            }
            .blur(radius: showGalleryOverlay ? 20 : 0)

            // The gallery overlay
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
        .background(Color(.systemGroupedBackground))
        // MARK: - Common Modifiers
        .navigationBarHidden(true) // Hide navigation bar for all layouts
        .onAppear {
            favoritesVM.subscribeToFavorites(for: authVM.user?.uid)
        }
        .fullScreenCover(isPresented: $showOnMapView) {
            OnMapView(mapType: .googleDestination(googleDestination))
                .environmentObject(locationManager)
        }
    }
}

// MARK: - Google Details Card
private struct GoogleDetailsCard: View {
    let googleDestination: GoogleDestination
    let onImageTapped: (Int) -> Void

    @State private var showFullDescription = false
    @Environment(\.openURL) var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header section with name and location
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(googleDestination.name).font(.title2).bold()
                    Text(googleDestination.location).font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
            }

            // Info row
            GoogleInfoRow(googleDestination: googleDestination)

            // Gallery section
            if let photoMetadata = googleDestination.galleryImageUrls, !photoMetadata.isEmpty {
                GalleryView(photoMetadata: photoMetadata, onImageTapped: onImageTapped)
            }

            // Description section
            AboutView(showFullDescription: $showFullDescription)


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
            
            // Add padding at the bottom
            Color.clear.frame(height: 50)
        }
        .padding(24)
    }
}

// MARK: - Google Info Row
private struct GoogleInfoRow: View {
    let googleDestination: GoogleDestination
    
    var body: some View {
        HStack {
            DetailInfoRow(icon: "mappin.and.ellipse", text: googleDestination.location, color: .secondary)
            Spacer()
            if let rating = googleDestination.rating {
                DetailInfoRow(icon: "star.fill", text: "\(String(format: "%.1f", rating))", color: .yellow)
            }
            Spacer()
            if let priceLevel = googleDestination.priceLevel {
                if priceLevel <= 0 {
                    DetailInfoRow(icon: "dollarsign", text: "Free", color: .green)
                } else {
                    DetailInfoRow(icon: "dollarsign", text: "\(String(format: "%.2f", priceLevel))", color: .green)
                }
            } else {
                DetailInfoRow(icon: "dollarsign", text: "N/A", color: .green)
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
        
        
// MARK: - Google Header Navigation Buttons (Renamed for clarity)
private struct GoogleHeaderNavButtons: View {
    let onDismiss: () -> Void
    let onViewOnMap: () -> Void
    
    // REMOVED: horizontalSizeClass check
    
    var body: some View {
        VStack {
            HStack {
                HeaderButton(iconName: "chevron.left", action: onDismiss)
                    .foregroundColor(.white)
            
                Spacer()
                
                // UPDATED: Always show "Details" text
                Text("Details").font(.headline).foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 12) {
                    HeaderButton(iconName: "mappin.and.ellipse", action: onViewOnMap)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)
            // Use .top safe area inset for padding instead of a fixed 50pts
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
    @Binding var showFullDescription: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // New Disclaimer Section
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Disclaimer")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                Text("This destination is provided by Google Places. It is not part of our official, curated list of partners. We've included it to give you a wider range of options, but please note that booking and other services may not be available directly through our app.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
            
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
