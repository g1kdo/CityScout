//
//  GoogleMapViewRepresentable.swift
//  CityScout
//
//  Created by Umuco Auca on 31/07/2025.
//


import SwiftUI
import GoogleMaps
import CoreLocation

struct GoogleMapViewRepresentable: UIViewRepresentable {
    
    let userLocation: CLLocation
    let destinationCoordinate: CLLocationCoordinate2D
    let markerTitle: String
    @Binding var travelTime: String
    
    // Stores the currently drawn polyline to prevent duplicates.
    @State private var polyline: GMSPolyline?
    
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: destinationCoordinate.latitude,
                                             longitude: destinationCoordinate.longitude,
                                             zoom: 15.0)
        let options = GMSMapViewOptions()
        options.camera = camera
        options.frame = .zero
        let mapView = GMSMapView.init(options: options)
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        
        fetchAndDrawRoute(from: userLocation.coordinate, to: destinationCoordinate, on: mapView)
        
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        uiView.clear()
        
        let marker = GMSMarker()
        marker.position = destinationCoordinate
        marker.title = markerTitle
        marker.map = uiView
        
        if !uiView.camera.target.isApproximatelyEqual(to: destinationCoordinate) {
            let newCamera = GMSCameraPosition.camera(withTarget: destinationCoordinate, zoom: uiView.camera.zoom)
            uiView.animate(to: newCamera)
        }
        
        fetchAndDrawRoute(from: userLocation.coordinate, to: destinationCoordinate, on: uiView)
    }
    
    private func fetchAndDrawRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, on mapView: GMSMapView) {
        let originString = "\(origin.latitude),\(origin.longitude)"
        let destinationString = "\(destination.latitude),\(destination.longitude)"
        
        //let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(originString)&destination=\(destinationString)&mode=driving"
        
        let apiKey = Secrets.googleMapsAPIKey
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(originString)&destination=\(destinationString)&mode=driving&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to fetch directions: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            // ⬇️ Add this line to see the raw response from the API
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Received JSON: \(jsonString)")
            }
            print("Requesting directions from: \(origin.latitude),\(origin.longitude)")
            print("Requesting directions to: \(destination.latitude),\(destination.longitude)")

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let routes = json["routes"] as? [[String: Any]],
                   let route = routes.first,
                   let overviewPolyline = route["overview_polyline"] as? [String: String],
                   let points = overviewPolyline["points"],
                   let legs = route["legs"] as? [[String: Any]],
                   let firstLeg = legs.first,
                   let duration = firstLeg["duration"] as? [String: Any],
                   let durationText = duration["text"] as? String {
                    
                    // ⬇️ This is the key change to fix the unwrapping error
                    if let path = GMSPath(fromEncodedPath: points) {
                        DispatchQueue.main.async {
                            self.polyline = GMSPolyline(path: path)
                            self.polyline?.strokeColor = .systemBlue
                            self.polyline?.strokeWidth = 5.0
                            self.polyline?.map = mapView
                            
                            self.travelTime = durationText
                            
                            let bounds = GMSCoordinateBounds(path: path)
                            mapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 50.0))
                        }
                    } else {
                        print("Failed to decode polyline string.")
                    }
                } else {
                    print("Could not parse directions data.")
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
            }
        }.resume()
    }
}
