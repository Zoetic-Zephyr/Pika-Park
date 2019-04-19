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
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var centerButton: UIButton!
    @IBOutlet weak var pinImg: UIImageView!
    
    
    
    let locationManager = CLLocationManager()
    let regionMeters: Double = 1000
    var previousLocation: CLLocation?
    
    // let geoCoder = CLGeocoder() duplicate code below
    // 13.1
    var directionsArray: [MKDirections] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 5.
        checkLocationServices()
        viewStyling()
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
        // 13.3
        resetMapView(withNew: directions)
        
        addDestinationAnnotation() // to add a pin on map at selected destination
        
        //12.4
        directions.calculate { [unowned self] (response, error) in
            //TODO: handel error if needed
            guard let response = response else { return } // TODO: show response not available in alert
            
            for route in response.routes {
                let steps = route.steps // tableView for displaying the direction steps, extend beyond the tutorial
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true) // resize the view of the map to fit the route
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 50.0, left: 50.0, bottom: 50.0, right: 50.0), animated: true)
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
        request.requestsAlternateRoutes = false
        
        return request
    }
    
    // 13.2
    func resetMapView(withNew directions: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map{ $0.cancel() }
        directionsArray.removeAll()
    }
    
    func viewStyling() {
        goButton.layer.cornerRadius = 5
        adressLabel.layer.masksToBounds = true
        adressLabel.layer.cornerRadius = 10
    }

    func addDestinationAnnotation() {
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.subtitle = "Your Destination"
        destinationAnnotation.coordinate = getCenterLocation(for: mapView).coordinate
        mapView.addAnnotation(destinationAnnotation)
    }
    
    
    @IBAction func goButtonTapped(_ sender: UIButton) {
        pinImg.alpha = 0.0 //can also animate pin to drop down to map
        adressLabel.alpha = 0.0
        getDirections()
    }
    
    @IBAction func centerButtonTapped(_ sender: UIButton) {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        centerViewOnUserLocation()
        pinImg.alpha = 1.0
        adressLabel.alpha = 1.0
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
        guard center.distance(from: previousLocation) > 10 else { return }
        self.previousLocation = center
        
        // 12.6
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
        renderer.strokeColor = UIColor(red: 0.4352941176, green: 0.5529411765, blue: 0.9882352941, alpha: 1.0)
        renderer.lineWidth = 2.0
        
        return renderer
    }
}
