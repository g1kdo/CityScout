//
//  LocationManager.swift
//  CityScout
//
//  Created by Umuco Auca on 17/07/2025.
//



import Foundation
import CoreLocation 

// LocationManager handles all CoreLocation interactions,
// including requesting authorization and providing location updates.
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager() // The CoreLocation manager
    @Published var authorizationStatus: CLAuthorizationStatus // Current authorization status
    @Published var lastKnownLocation: CLLocation? // The last fetched location
    @Published var locationString: String? // Human-readable location string (e.g., "Kigali, Rwanda")
    @Published var isLoadingLocation: Bool = false // Indicates if location is being fetched
    @Published var locationError: String? // Stores any errors during location fetching

    // Add an explicit call to start updating location in the `init`
    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        locationManager.distanceFilter = 100
        
        // Start updating location if permission is already granted
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdatingLocation()
        }
    }

    // Requests "When In Use" location authorization from the user.
    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    // Starts fetching the current location.
    func startUpdatingLocation() {
        isLoadingLocation = true
        locationError = nil // Clear previous errors
        locationManager.startUpdatingLocation() // Begin continuous location updates
        print("LocationManager: Started updating location.")
    }

    // Stops fetching location. Call this when you have the location or leave the view.
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        isLoadingLocation = false
        print("LocationManager: Stopped updating location.")
    }

    // MARK: - CLLocationManagerDelegate

    // Called when the authorization status changes.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        print("LocationManager: Authorization status changed to \(authorizationStatus.rawValue)")

        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // If authorized, start updating location if not already doing so
            if !isLoadingLocation { // Prevent multiple starts if already loading
                 startUpdatingLocation()
            }
        case .denied, .restricted:
            locationError = "Location access denied. Please enable it in Settings."
            isLoadingLocation = false
            stopUpdatingLocation() // Stop if access is denied
        case .notDetermined:
            // Authorization not yet determined, do nothing specific here.
            break
        @unknown default:
            locationError = "Unknown location authorization status."
            isLoadingLocation = false
            stopUpdatingLocation()
        }
    }

    // Called when new location data is available.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return } // Get the most recent location
        self.lastKnownLocation = location
        print("LocationManager: Received new location: \(location.coordinate.latitude), \(location.coordinate.longitude)")

        // Reverse geocode to get a human-readable address string
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            if let placemark = placemarks?.first {
                // Construct a readable location string
                let city = placemark.locality ?? ""
                let country = placemark.country ?? ""
                if !city.isEmpty && !country.isEmpty {
                    self.locationString = "\(city), \(country)"
                } else if !city.isEmpty {
                    self.locationString = city
                } else if !country.isEmpty {
                    self.locationString = country
                } else {
                    self.locationString = "Unknown Location"
                }
                print("LocationManager: Reverse geocoded location: \(self.locationString ?? "N/A")")
            } else if let error = error {
                self.locationError = "Failed to get location name: \(error.localizedDescription)"
                print("LocationManager: Reverse geocoding error: \(error.localizedDescription)")
            }
            // Stop updating location once we have a valid string, or if an error occurred.
            self.stopUpdatingLocation()
        }
    }

    // Called when location fetching fails.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoadingLocation = false
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationError = "Location access denied by user."
            case .locationUnknown:
                locationError = "Location is currently unknown."
            case .network:
                locationError = "Network error while fetching location."
            default:
                locationError = "Location error: \(error.localizedDescription)"
            }
        } else {
            locationError = "An unknown location error occurred: \(error.localizedDescription)"
        }
        print("LocationManager: Location fetching failed with error: \(error.localizedDescription)")
        stopUpdatingLocation() // Stop on error
    }
}
