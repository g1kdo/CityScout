//
//  OnMapView.swift
//  CityScout
//
//  Created by Umuco Auca on 31/07/2025.
//

import SwiftUI
import GoogleMaps
import CoreLocation
import Kingfisher
import GooglePlaces

enum MapType {
    case destination(Destination)
    case googleDestination(GoogleDestination)
    
    var name: String {
        switch self {
        case .destination(let dest):
            return dest.name
        case .googleDestination(let dest):
            return dest.name
        }
    }
    
    var location: String {
        switch self {
        case .destination(let dest):
            return dest.location
        case .googleDestination(let dest):
            return dest.location
        }
    }
    
    var coordinate: CLLocationCoordinate2D? {
        switch self {
        case .destination(let dest):
            if let lat = dest.latitude, let lon = dest.longitude {
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
            return nil
        case .googleDestination(let dest):
            // Safely unwrap the optional latitude and longitude properties
            if let lat = dest.latitude, let lon = dest.longitude {
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
            return nil // Return nil if either latitude or longitude is missing
        }
    }
    
    var imageUrl: String? {
        switch self {
        case .destination(let dest):
            return dest.imageUrl
        case .googleDestination(let dest):
            return nil
        }
    }
    
    var photoMetadata: GMSPlacePhotoMetadata? {
            switch self {
            case .destination:
                return nil
            case .googleDestination(let dest):
                return dest.photoMetadata // Return the metadata object
            }
        }
    
    var rating: Double? {
        switch self {
        case .destination(let dest):
            return dest.rating
        case .googleDestination(let dest):
            return dest.rating
        }
    }
    
    var participantAvatars: [String]? {
        switch self {
        case .destination(let dest):
            return dest.participantAvatars
        case .googleDestination:
            // Google destinations do not have participant avatars
            return nil
        }
    }
}

// MARK: - New data model for recommended places
struct RecommendedPlace: Identifiable {
    let id = UUID()
    var name: String
    var distance: String
    var photoReference: String?
    var imageUrl: String?
    var position: CGPoint
    var coordinate: CLLocationCoordinate2D
}

struct OnMapView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var locationManager: LocationManager
    let mapType: MapType

    @State private var showingMapSheet = false
    @State private var destinationCoordinate: CLLocationCoordinate2D? = nil
    @State private var showingGeocodeErrorAlert = false
    @State private var travelTime: String = "Calculating..."
    @State private var travelMode: String = "Car"
    @State private var travelTimes: [String: String] = [:]
    
    // 💡 State variables for nearby places
    @State private var recommendedPlaces: [RecommendedPlace] = []
    @State private var selectedPlaceCoordinate: CLLocationCoordinate2D? = nil
    @State private var selectedPlaceName: String = ""
    @State private var showingPermissionAlert = false
    
    @State private var mapDataIsReady = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let imageUrl = mapType.imageUrl {
                    DestinationBackgroundImageView(imageUrl: imageUrl, geometry: geometry)
                        .ignoresSafeArea(.all)
                } else if let photoMetadata = mapType.photoMetadata {
                    GooglePlacesImageView(photoMetadata: photoMetadata)
                        .scaledToFill()
                        .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
                        .clipped()
                        .overlay(
                            LinearGradient(gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.3)]), startPoint: .center, endPoint: .bottom)
                        )
                        .ignoresSafeArea(.all)
                } else {
                    // Fallback for GoogleDestination without an imageUrl
                    Color.gray.ignoresSafeArea(.all)
                }
                
                Color.black.opacity(0.3)
                    .ignoresSafeArea(.all)

                TopNavigationBar(destinationName: mapType.name) {
                    dismiss()
                }
                .padding(.horizontal, 20)
                .padding(.top)

                ForEach(recommendedPlaces) { place in
                    Button(action: {
                        self.selectedPlaceCoordinate = place.coordinate
                        self.selectedPlaceName = place.name
                        self.mapDataIsReady = true
                    }) {
                        BubbleCard(
                            title: place.name,
                            distance: place.distance,
                            imageUrl: place.imageUrl,
                            bubblePosition: place.position,
                            pointerHeightOffset: place.position.y == 0.25 ? 60 : 65
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                BottomInformationCard(mapType: mapType, travelTime: travelTime, travelMode: travelMode, action: {
                    mapDataIsReady = true
                })
                .padding(.horizontal, 20)
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $mapDataIsReady) {
            GoogleMapViewContainer(
                destinationCoordinate: destinationCoordinate,
                markerTitle: mapType.name,
                userLocation: locationManager.lastKnownLocation,
                travelTime: $travelTime
            )
        }
        .alert("Location Not Found", isPresented: $showingGeocodeErrorAlert) {
            Button("OK") { }
        } message: {
            Text("We could not find the exact location for \(mapType.name). Please check the address or try again later.")
        }
        .onAppear {
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestLocationAuthorization()
            } else if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                self.showingPermissionAlert = true
            } else {
                fetchDestinationAndNearbyPlaces()
            }
        }
        .onChange(of: locationManager.authorizationStatus) { newStatus in
            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                self.showingPermissionAlert = false
                fetchDestinationAndNearbyPlaces()
            } else if newStatus == .denied || newStatus == .restricted {
                self.showingPermissionAlert = true
            }
        }
        .alert("Location Access Required", isPresented: $showingPermissionAlert) {
            Button("OK") {}
        } message: {
            Text("Please enable location services in Settings to view your current location and nearby places.")
        }
    }
    
    private func fetchDestinationAndNearbyPlaces() {
        if let coordinate = mapType.coordinate {
            self.destinationCoordinate = coordinate
            fetchFilteredNearbyPlaces(for: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        } else {
            geocodeAddress(address: mapType.location) { coordinate in
                if let coordinate = coordinate {
                    self.destinationCoordinate = coordinate
                    fetchFilteredNearbyPlaces(for: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
                } else {
                    self.showingGeocodeErrorAlert = true
                }
            }
        }
    }
    
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
    
    private func fetchFilteredNearbyPlaces(for destinationLocation: CLLocation) {
        let apiKey = Secrets.googleMapsAPIKey
        let placeTypes = "hospital|restaurant|park|tourist_attraction"
        
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(destinationLocation.coordinate.latitude),\(destinationLocation.coordinate.longitude)&radius=5000&type=\(placeTypes)&rankby=prominence&key=\(apiKey)"
        
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            print("Invalid Places URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to fetch nearby places: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = json["results"] as? [[String: Any]] {
                       
                    let filteredResults = results.filter { place in
                        return true
                    }
                    
                    let topTwoPlaces = Array(filteredResults.prefix(2))
                    var places: [RecommendedPlace] = []
                    let bubblePositions: [CGPoint] = [
                        CGPoint(x: 0.75, y: 0.25),
                        CGPoint(x: 0.35, y: 0.55)
                    ]
                    
                    for (index, placeData) in topTwoPlaces.enumerated() {
                        guard let name = placeData["name"] as? String,
                              let geometry = placeData["geometry"] as? [String: Any],
                              let location = geometry["location"] as? [String: Any],
                              let lat = location["lat"] as? Double,
                              let lon = location["lng"] as? Double else {
                            continue
                        }
                        
                        let placeLocation = CLLocation(latitude: lat, longitude: lon)
                        let distanceInMeters = destinationLocation.distance(from: placeLocation)
                        let distanceInMiles = String(format: "%.1f mi from \(self.mapType.name)", distanceInMeters * 0.000621371)
                        
                        let photoRef = (placeData["photos"] as? [[String: Any]])?.first?["photo_reference"] as? String
                        
                        let photoUrlString: String?
                        if let photoRef = photoRef {
                            photoUrlString = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=\(photoRef)&key=\(apiKey)"
                        } else {
                            photoUrlString = nil
                        }
                        
                        let newPlace = RecommendedPlace(
                            name: name,
                            distance: distanceInMiles,
                            photoReference: photoRef,
                            imageUrl: photoUrlString,
                            position: bubblePositions[index],
                            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        )
                        
                        places.append(newPlace)
                    }
                    
                    DispatchQueue.main.async {
                        self.recommendedPlaces = places
                    }
                }
            } catch {
                print("JSON parsing error for places: \(error.localizedDescription)")
            }
        }.resume()
    }

    
    // MARK: - New function to fetch photos 🖼️
    private func fetchPhotosForPlaces() {
        // 💡 Trigger a view update with a new array
        var updatedPlaces = recommendedPlaces
        for (index, place) in updatedPlaces.enumerated() {
            guard let photoRef = place.photoReference else { continue }

            let apiKey = Secrets.googleMapsAPIKey
            let photoUrlString = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=\(photoRef)&key=\(apiKey)"
            
            // This is a more robust way to update the state.
            updatedPlaces[index].imageUrl = photoUrlString
        }
        
        // 💡 Set the state property to a new array instance, which triggers a view refresh.
        self.recommendedPlaces = updatedPlaces
    }
    
    // MARK: - Helper Functions for safe area (No change, keeping for completeness)
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

// DestinationBackgroundImageView (No change)
struct DestinationBackgroundImageView: View {
    let imageUrl: String
    let geometry: GeometryProxy

    var body: some View {
        KFImage(URL(string: imageUrl))
            .resizable()
            .placeholder {
                Color.gray.opacity(0.1)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .fade(duration: 0.25)
            .cancelOnDisappear(true)
            .scaledToFill()
            .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
            .clipped()
            .overlay(
                LinearGradient(gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.3)]), startPoint: .center, endPoint: .bottom)
            )
    }
}

// TopNavigationBar (No change)
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
            Spacer()
        }
    }
}

// MARK: - Bottom Information Card (MODIFIED)
struct BottomInformationCard: View {
    let mapType: MapType
    let travelTime: String
    let travelMode: String
    let action: () -> Void
    
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(mapType.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 14))
                        if let rating = mapType.rating {
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                HStack {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                            Text(mapType.location)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "car.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                            Text(locationManager.lastKnownLocation != nil ? travelTime : "Loading...")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                }
                HStack {
                    HStack(spacing: -8) {
                        if let avatars = mapType.participantAvatars {
                            ForEach(0..<min(3, avatars.count), id: \.self) { index in
                                MapImageView(imageUrl: avatars[index])
                            }
                            if avatars.count > 3 {
                                Circle()
                                    .fill(Color.gray.opacity(0.8))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: 2)
                                    )
                                    .overlay(
                                        Text("+\(avatars.count - 3)")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                    }
                    Spacer()
                }

                Button(action: action) {
                    Text("See On The Map")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            locationManager.lastKnownLocation != nil ?
                            AnyView(LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.4, green: 0.8, blue: 1.0),
                                    Color(red: 0.2, green: 0.7, blue: 0.95)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            : AnyView(Color.gray.opacity(0.5))
                        )
                        .cornerRadius(12)
                }
                .disabled(locationManager.lastKnownLocation == nil)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.75))
            )
        }
    }
}

// MARK: - BubbleCard Subview (No change)
struct BubbleCard: View {
    let title: String
    let distance: String
    let imageUrl: String?
    let bubblePosition: CGPoint
    let pointerHeightOffset: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                HStack(spacing: 12) {
                    if let url = imageUrl, let imageURL = URL(string: url) {
                        KFImage(imageURL)
                            .resizable()
                            .placeholder {
                                Color.gray.opacity(0.1)
                            }
                            .fade(duration: 0.25)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 50)
                            .cornerRadius(8)
                            .clipped()
                    } else {
                        // Placeholder for loading or no image
                        Color.gray.opacity(0.1)
                            .frame(width: 60, height: 50)
                            .cornerRadius(8)
                    }

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
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.6))
                )
                .frame(width: 200)
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

// MARK: - Custom Shape for Bubble Pointer (No change)
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

// MARK: - Google Map View Container (MODIFIED)
struct GoogleMapViewContainer: View {
    // ⬇️ Accept optionals to handle the nil case gracefully
    let destinationCoordinate: CLLocationCoordinate2D?
    let markerTitle: String
    let userLocation: CLLocation?
    @Binding var travelTime: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let destinationCoord = destinationCoordinate,
                let userLoc = userLocation {
                GoogleMapViewRepresentable(
                    userLocation: userLoc,
                    destinationCoordinate: destinationCoord,
                    markerTitle: markerTitle,
                    travelTime: $travelTime
                )
                .ignoresSafeArea()
            } else {
                Text("Error: Location data is missing.")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.red)
                    .presentationDetents([.medium, .large])
            }

            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.gray)
                    .padding(10)
                    .background(Circle().fill(Color.white.opacity(0.8)))
            }
            .padding(.top, 20)
            .padding(.leading, 20)
        }
    }
}


// Helper for comparing CLLocationCoordinate2D (No change)
extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return abs(lhs.latitude - rhs.latitude) < 1e-9 && abs(lhs.longitude - rhs.longitude) < 1e-9
    }

    func isApproximatelyEqual(to other: CLLocationCoordinate2D, tolerance: Double = 1e-6) -> Bool {
        return abs(self.latitude - other.latitude) < tolerance && abs(self.longitude - other.longitude) < tolerance
    }
}

// Avatar Image View Helper (No change)
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
