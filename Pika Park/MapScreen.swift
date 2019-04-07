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
        
        // 13.
        guard let previousLocation = self.previousLocation else { return }
        
        
        // 11.1
        guard center.distance(from: previousLocation) > 50 else { return }
        self.previousLocation = center
        
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
            
            // 12. Closure, Async, main thread blah blah...
            DispatchQueue.main.async {
                self.adressLabel.text = "\(streetNumber) \(streetName)"
            }
        }
    }
}
