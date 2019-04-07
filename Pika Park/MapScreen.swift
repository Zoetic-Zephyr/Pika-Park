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
    
    let locationManager = CLLocationManager()
    let regionMeters: Double = 10000
    
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
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            // Do Map Stuff
            // 6.
            mapView.showsUserLocation = true
            centerViewOnUserLocation()
            break
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
    
    
}

// 1.
extension MapScreen: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // We'll be back
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // We'll be back
    }
}

