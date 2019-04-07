//
//  MapScreen.swift
//  Pika Park
//
//  Created by 张正 on 2019/4/6.
//  Copyright © 2019 JackZhang. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapScreen: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var adressLabel: UILabel!
    
    let locationManager = CLLocationManager()
    let regionMeters: Double = 10000
    var previousLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 5.
        checkLocationServices()
    }
    
    
    // 3.
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    //7.
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionMeters, longitudinalMeters: regionMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    
    
    // 2.
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            // setup our location manager
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            // show alert letting the user know they have to turn this on
        }
    }
    
    // 4.
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() { // device-level location permissions
        case .authorizedWhenInUse:
            // Do Map Stuff
            startTrackingUserLocation()
        case .denied:
            // show alert instructing them how to turn on permission
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            // show alert letting user know maybe "parental control" is activated
            break
        case .authorizedAlways:
            break
        @unknown default:
            fatalError()
        }
    }
    
    func startTrackingUserLocation() {
        // 6.
        mapView.showsUserLocation = true
        centerViewOnUserLocation()
        locationManager.startUpdatingLocation()
        // 11.2
        previousLocation = getCenterLocation(for: mapView)
    }
    
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func getDirections() {
        guard let location = locationManager.location?.coordinate else {
            //TODO: inform user we don't have their current location
            return
        }
        // 12.1
        let request = createDirectionsRequest(from: location)
        // 12.3
        let directions = MKDirections(request: request)
        //12.4
        directions.calculate { [unowned self] (response, error) in
            //TODO: handel error if needed
            guard let response = response else { return } // TODO: show response not available in alert
            
            for route in response.routes {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true) // resize the view of the map to fit the route
            }
        }
    }
    // 12.2
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        let destinationCoordinate       = getCenterLocation(for: mapView).coordinate
        let startingLocation            = MKPlacemark(coordinate: coordinate)
        let destination                 = MKPlacemark(coordinate: destinationCoordinate)
        
        let request                     = MKDirections.Request()
        request.source                  = MKMapItem(placemark: startingLocation)
        request.destination             = MKMapItem(placemark: destination)
        request.transportType           = .automobile // automobile by default, can let user select
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    
    @IBAction func goButtonTapped(_ sender: UIButton) {
        getDirections()
    }
}

// 1.
extension MapScreen: CLLocationManagerDelegate {
// 8.
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        // We'll be back
//        guard let location = locations.last else { return } // guard
//        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
//        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regionMeters, longitudinalMeters: regionMeters)
//        mapView.setRegion(region, animated: true)
//    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // We'll be back
        checkLocationAuthorization()
    }
}

// 9.
extension MapScreen: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterLocation(for: mapView)
        // 10.1
        let geoCoder = CLGeocoder()
        
        // 11.5
        guard let previousLocation = self.previousLocation else { return }
        
        
        // 11.1
        guard center.distance(from: previousLocation) > 50 else { return }
        self.previousLocation = center
        
        geoCoder.cancelGeocode() // clean up the geocodes for performance
        
        // 10.2 guards are for unrelated error handling
        geoCoder.reverseGeocodeLocation(center) {[weak self] (placemarks, error) in
            guard let self = self else { return }
            
            if let _ = error {
                // TODO: show alert informing user
                return
            }
            
            guard let placemark = placemarks?.first else {
                // TODO: show alert informing user
                return
            }
            
            // 11.3
            let streetNumber = placemark.subThoroughfare ?? "" // nil coalescing
            let streetName = placemark.thoroughfare ?? "" // nil coalescing
            
            // 11.4 Closure, Async, main thread blah blah...
            DispatchQueue.main.async {
                self.adressLabel.text = "\(streetNumber) \(streetName)"
            }
        }
    }
    
    // 12.5
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .lightGray
        
        return renderer
    }
}
