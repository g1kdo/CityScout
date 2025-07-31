//
//  GoogleMapViewRepresentable.swift
//  CityScout
//
//  Created by Umuco Auca on 31/07/2025.
//


import SwiftUI
import GoogleMaps

struct GoogleMapViewRepresentable: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D
    let markerTitle: String

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: coordinate.latitude, longitude: coordinate.longitude, zoom: 15.0)
        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {
        uiView.clear()
        let marker = GMSMarker()
        marker.position = coordinate
        marker.title = markerTitle
        marker.map = uiView

        // Only animate if the target coordinate actually changed significantly
        if !uiView.camera.target.isApproximatelyEqual(to: coordinate) {
             let newCamera = GMSCameraPosition.camera(withTarget: coordinate, zoom: uiView.camera.zoom)
             uiView.animate(to: newCamera)
        }
    }
}
