//
//  OnMapView.swift
//  CityScout
//
//  Created by Umuco Auca on 31/07/2025.
//

//
//  OnMapView.swift
//  CityScout
//
//  Created by Umuco Auca on 31/07/2025.
//

//
//  OnMapView.swift
//  CityScout
//
//  Created by Umuco Auca on 31/07/2025.
//

import SwiftUI
import GoogleMaps
import CoreLocation
import Kingfisher // Import Kingfisher

struct OnMapView: View {
    @Environment(\.dismiss) private var dismiss
    let destination: Destination // This will now receive an object that might only have 'location' set

    @State private var showingMapSheet = false
    @State private var destinationCoordinate: CLLocationCoordinate2D? = nil // State to store geocoded coordinate
    @State private var showingGeocodeErrorAlert = false // Added for error handling feedback

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // MARK: - 1. Main Background Image (Full Screen) using Kingfisher
                DestinationBackgroundImageView(imageUrl: destination.imageUrl, geometry: geometry)
                    .ignoresSafeArea(.all)

                // MARK: - 2. Dark Overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea(.all)

                // MARK: - 3. Top Navigation Bar
                TopNavigationBar(destinationName: destination.name) {
                    dismiss()
                }
                .padding(.horizontal, 20)
                .padding(.top, safeAreaTop() + 10) // Apply top padding for safe area

                // MARK: - Bubble Cards
                BubbleCard(imageName: "LaHotelImage", title: "La-Hotel", distance: "2.09 mi", bubblePosition: CGPoint(x: 0.75, y: 0.25), pointerHeightOffset: 60)
                BubbleCard(imageName: "LemonGardenImage", title: "Lemon Garden", distance: "2.09 mi", bubblePosition: CGPoint(x: 0.35, y: 0.55), pointerHeightOffset: 65)

                // MARK: - Bottom Information Card
                BottomInformationCard(destination: destination, action: {
//                    if let lat = destination.latitude, let lon = destination.longitude {
//                        // If coordinates are provided in the Destination, use them directly
//                        self.destinationCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
//                        showingMapSheet = true
//                    } else {
                        // Otherwise, geocode the location string
                        geocodeAddress(address: destination.location) { coordinate in
                            if let coordinate = coordinate {
                                self.destinationCoordinate = coordinate
                                showingMapSheet = true
                            } else {
                                print("Could not geocode address: \(destination.location)")
                                self.showingGeocodeErrorAlert = true // Show alert on failure
                            }
                    }
                })
                .padding(.horizontal, 20)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingMapSheet) {
            if let coordinate = destinationCoordinate {
                // Now presenting the container view, which includes the dismiss button
                GoogleMapViewContainer(coordinate: coordinate, markerTitle: destination.name)
            } else {
                Text("Map location not available.")
                    .presentationDetents([.medium, .large]) // Give the sheet some detents
            }
        }
        .alert("Location Not Found", isPresented: $showingGeocodeErrorAlert) {
            Button("OK") { }
        } message: {
            Text("We could not find the exact location for \(destination.name). Please check the address or try again later.")
        }
    }

    // MARK: - Geocoding function
    private func geocodeAddress(address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            guard let placemark = placemarks?.first, let location = placemark.location else {
                print("Geocoding error: \(error?.localizedDescription ?? "Unknown error") for address: \(address)")
                completion(nil)
                return
            }
            completion(location.coordinate)
        }
    }

    // MARK: - Helper Functions for safe area
    private func safeAreaTop() -> CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return 0
        }
        return window.safeAreaInsets.top
    }

    private func safeAreaBottom() -> CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return 0
        }
        return window.safeAreaInsets.bottom
    }
}

// MARK: - Extracted Subviews

// Background Image View using Kingfisher
struct DestinationBackgroundImageView: View {
    let imageUrl: String
    let geometry: GeometryProxy

    var body: some View {
        KFImage(URL(string: imageUrl))
            .resizable()
            .placeholder {
                Color.gray.opacity(0.1) // Placeholder while loading
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .fade(duration: 0.25) // Smooth fade-in
            .cancelOnDisappear(true) // Cancel download if view disappears
            .scaledToFill()
            .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
            .clipped()
            .overlay(
                // Optional: A subtle gradient overlay at the bottom for text readability
                LinearGradient(gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.3)]), startPoint: .center, endPoint: .bottom)
            )
    }
}

// Top Navigation Bar
struct TopNavigationBar: View {
    let destinationName: String
    let dismissAction: () -> Void

    var body: some View {
        VStack {
            HStack {
                Button(action: dismissAction) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .padding(13)
                        .background(Circle().fill(Color.black.opacity(0.3)))
                }

                Spacer()

                Text(destinationName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }
            Spacer() // Pushes the HStack to the top
        }
    }
}

// Bottom Information Card
struct BottomInformationCard: View {
    let destination: Destination
    let action: () -> Void

    var body: some View {
        VStack {
            Spacer() // Pushes the content to the bottom
            VStack(alignment: .leading, spacing: 16) {
                // Title and Rating Row
                HStack {
                    Text(destination.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 14))

                        Text(String(format: "%.1f", destination.rating))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }

                // Location and Time Row
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))

                        Text(destination.location)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))

                        Text("45 Minutes") // Still hardcoded, consider making this dynamic if possible
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }

                // Avatar Row
                HStack {
                    HStack(spacing: -8) {
                        ForEach(0..<min(3, destination.participantAvatars?.count ?? 0), id: \.self) { index in
                            // Use the extracted helper view here
                            if let imageUrl = destination.participantAvatars?[index] {
                                MapImageView(imageUrl: imageUrl)
                            }
                        }

                        if let avatarCount = destination.participantAvatars?.count, avatarCount > 3 {
                            Circle()
                                .fill(Color.gray.opacity(0.8))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white, lineWidth: 2)
                                )
                                .overlay(
                                    Text("+\(avatarCount - 3)")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    Spacer()
                }

                // See On The Map Button
                Button(action: action) {
                    Text("See On The Map")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.4, green: 0.8, blue: 1.0),
                                    Color(red: 0.2, green: 0.7, blue: 0.95)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.75))
            )
        }
    }
}

// MARK: - BubbleCard Subview
struct BubbleCard: View {
    let imageName: String
    let title: String
    let distance: String
    let bubblePosition: CGPoint
    let pointerHeightOffset: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                HStack(spacing: 12) {
                    // Corrected usage for local image assets: Image(imageName)
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 50)
                        .cornerRadius(8)
                        .clipped()

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        Text(distance)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.6))
                )
                .frame(width: 180)
                .position(x: geometry.size.width * bubblePosition.x,
                          y: geometry.size.height * bubblePosition.y)

                BubblePointerShape()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 40, height: 50)
                    .offset(x: -20)
                    .position(x: geometry.size.width * bubblePosition.x,
                              y: (geometry.size.height * bubblePosition.y) + pointerHeightOffset)
            }
        }
    }
}

// MARK: - Custom Shape for Bubble Pointer
struct BubblePointerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let startPoint = CGPoint(x: rect.midX, y: rect.minY + 5)
        let midPoint1 = CGPoint(x: rect.midX, y: rect.maxY * 0.7)
        let endPointCircle = CGPoint(x: rect.midX, y: rect.maxY - 10)

        path.move(to: startPoint)
        path.addLine(to: midPoint1)

        let circleRadius: CGFloat = 8
        path.addArc(center: endPointCircle, radius: circleRadius, startAngle: .zero, endAngle: .degrees(360), clockwise: false)

        return path
    }
}

// MARK: - Google Map View Container (NEWLY ADDED)
struct GoogleMapViewContainer: View {
    let coordinate: CLLocationCoordinate2D
    let markerTitle: String
    @Environment(\.dismiss) var dismiss // Inject dismiss environment value

    var body: some View {
        ZStack(alignment: .topLeading) { // Align content to top-leading
            GoogleMapViewRepresentable(coordinate: coordinate, markerTitle: markerTitle)
                .ignoresSafeArea()

            Button(action: {
                dismiss() // Dismiss the sheet
            }) {
                Image(systemName: "xmark.circle.fill") // A clear dismiss icon
                    .font(.title)
                    .foregroundColor(.gray)
                    .padding(10)
                    .background(Circle().fill(Color.white.opacity(0.8)))
            }
            .padding(.top, 20) // Adjust padding for safe area
            .padding(.leading, 20)
        }
    }
}


// Helper for comparing CLLocationCoordinate2D (useful for updateUIView)
extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return abs(lhs.latitude - rhs.latitude) < 1e-9 && abs(lhs.longitude - rhs.longitude) < 1e-9
    }

    func isApproximatelyEqual(to other: CLLocationCoordinate2D, tolerance: Double = 1e-6) -> Bool {
        return abs(self.latitude - other.latitude) < tolerance && abs(self.longitude - other.longitude) < tolerance
    }
}

// MARK: - Avatar Image View Helper
struct MapImageView: View {
    let imageUrl: String

    var body: some View {
        KFImage(URL(string: imageUrl))
            .placeholder {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
            }
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))

    }
}


// MARK: - Preview Provider
//struct OnMapView_Previews: PreviewProvider {
//    static var previews: some View {
//        // Example 1: Destination with location string, relying on geocoding
//        OnMapView(destination: Destination(
//            name: "Kigali Convention Centre",
//            imageUrl: "https://via.placeholder.com/400x600/FF5733/FFFFFF?text=KCC", // Example image for Kingfisher
//            rating: 4.5,
//            location: "Kigali Convention Centre, KG 2 Roundabout, Kigali, Rwanda", // Geocodable address
//            participantAvatars: [
//                "https://i.pravatar.cc/150?img=1",
//                "https://i.pravatar.cc/150?img=2",
//                "https://i.pravatar.cc/150?img=3"
//            ],
//            description: "A prominent landmark and venue in Kigali.",
//            latitude: nil, // Explicitly nil to trigger geocoding
//            longitude: nil  // Explicitly nil to trigger geocoding
//        ))
//
//        // Example 2: Destination with pre-defined coordinates (if you have them)
//        OnMapView(destination: Destination(
//            name: "Nyandungu Eco Park",
//            imageUrl: "https://lh5.googleusercontent.com/p/AF1QipN38Xh1_x7eQ_m1-oX90qB-3X5e6Y_2lR8_j4w=w400-h300-k-no",
//            rating: 4.7,
//            location: "Kigali, Nyandungu Eco Park",
//            participantAvatars: [
//                "https://i.pravatar.cc/150?img=4",
//                "https://i.pravatar.cc/150?img=5",
//                "https://i.pravatar.cc/150?img=6",
//                "https://i.pravatar.cc/150?img=7"
//            ],
//            description: "A beautiful eco park in Kigali with diverse flora and fauna. Perfect for nature walks and relaxation.",
//            latitude: -1.9705, // Example coordinates for Nyandungu Eco Park
//            longitude: 30.1340
//        ))
//    }
//}
