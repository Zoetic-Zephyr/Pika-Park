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

import RevealingSplashView
import SwiftMessages

class MapScreen: UIViewController, UISearchBarDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var adressLabel: UILabel!
    @IBOutlet weak var findParkingButton: UIButton!
    @IBOutlet weak var centerButton: UIButton!
    @IBOutlet weak var pinImg: UIImageView!
    @IBOutlet weak var navigateButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var searchImg: UIImageView!
    @IBOutlet weak var whiteBlob: UIImageView!
    
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var walkLabel: UILabel!
    
    @IBOutlet weak var lessPriceButton: UIButton!
    @IBOutlet weak var morePriceButton: UIButton!
    
    @IBOutlet weak var lessWalkButton: UIButton!
    @IBOutlet weak var moreWalkButton: UIButton!
    
    
    let locationManager = CLLocationManager()
    let regionMeters: Double = 1000
    var previousLocation: CLLocation?
    
    // let geoCoder = CLGeocoder() duplicate code below
    // 13.1
    var directionsArray: [MKDirections] = []
    
    var parkingLocationDegrees: [Double] = [0.0,0.0] // received coordinates of parking spot, in format of double(latitude, longitude)
    var parkingCoordinate2D: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0.0, 0.0)
    var waiting: Int = 1
    
    var userPrice: Int = 2
    var userWalk: Int = 100
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Initialize a revealing Splash with with the iconImage, the initial size and the background color
        let revealingSplashView = RevealingSplashView(iconImage: UIImage(named: "pikachu2")!,iconInitialSize: CGSize(width: 600*2/5, height: 590*2/5), backgroundColor: UIColor(red:0.0, green:0.0, blue:0.0, alpha:1.0))
        
        //Adds the revealing splash view as a sub view
        self.view.addSubview(revealingSplashView)
        
        revealingSplashView.animationType = SplashAnimationType.swingAndZoomOut
        
        //Starts animation
        revealingSplashView.startAnimation(){
            print("Splash Screen Completed")
        }
        
        // 5.
        checkLocationServices()
        viewStyling()
    }
    
    // navigation controller is no longer needed
    // the two overrides below are to hide the navigation bar on MapScreen, and show it on PreferenceScreen
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        self.navigationController?.setNavigationBarHidden(true, animated: false)
//    }
//
//    override func viewDidDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        self.navigationController?.setNavigationBarHidden(false, animated: true)
//    }
    // end two overrides
    
    
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
    
    func getDirections(destinationCoordinate2D: CLLocationCoordinate2D) {
        guard let userCoordinate2D = locationManager.location?.coordinate else {
            // inform user we don't have their current location
            return
        }
        // 12.1
        let request = createDirectionsRequest(from: userCoordinate2D, to: destinationCoordinate2D)
        // 12.3
        let directions = MKDirections(request: request)
        // 13.3
        resetMapView(withNew: directions)
        
        addDestinationAnnotation(at: destinationCoordinate2D) // to add a pin on map at selected destination
        
        //12.4
        directions.calculate { [unowned self] (response, error) in
            //TODO: handel error if needed
            guard let response = response else { return } // TODO: show response not available in alert
            
            for route in response.routes {
//                let steps = route.steps // create an additional tableView for displaying the direction steps, extend beyond the tutorial
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true) // resize the view of the map to fit the route
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 50.0, left: 50.0, bottom: 50.0, right: 50.0), animated: true)
            }
        }
    }
    
    // 12.2
    func createDirectionsRequest(from userCoordinate2D: CLLocationCoordinate2D, to destinationCoordinate2D: CLLocationCoordinate2D) -> MKDirections.Request {
//        let destinationCoordinate       = getCenterLocation(for: mapView).coordinate
        let startingLocation            = MKPlacemark(coordinate: userCoordinate2D)
        let destination                 = MKPlacemark(coordinate: destinationCoordinate2D)
        
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
        findParkingButton.layer.cornerRadius = 5
        findParkingButton.layer.shadowColor = UIColor.black.cgColor
        findParkingButton.layer.shadowOffset = CGSize(width: 0.0, height: 4.0)
        findParkingButton.layer.masksToBounds = false
        findParkingButton.layer.shadowRadius = 1.0
        findParkingButton.layer.shadowOpacity = 0.2
        
        navigateButton.layer.cornerRadius = 5
        navigateButton.alpha = 0.0  // navi button should appear only after receiving parking coordinates from backend
        navigateButton.isEnabled = false
        navigateButton.layer.shadowColor = UIColor.black.cgColor
        navigateButton.layer.shadowOffset = CGSize(width: 0.0, height: 4.0)
        navigateButton.layer.masksToBounds = false
        navigateButton.layer.shadowRadius = 1.0
        navigateButton.layer.shadowOpacity = 0.2
        
        centerButton.layer.cornerRadius = 0.5 * centerButton.bounds.size.width
        centerButton.layer.shadowColor = UIColor.black.cgColor
        centerButton.layer.shadowOffset = CGSize(width: 0.0, height: 4.0)
        centerButton.layer.masksToBounds = false
        centerButton.layer.shadowRadius = 1.0
        centerButton.layer.shadowOpacity = 0.1
        
        searchButton.layer.cornerRadius = 5
        
        adressLabel.layer.masksToBounds = true  // for lables to have rounded corners, conflict with shadow...
        adressLabel.layer.cornerRadius = 5
        adressLabel.layer.shadowColor = UIColor.black.cgColor
        adressLabel.layer.shadowOffset = CGSize(width: 0.0, height: 4.0)
//        adressLabel.layer.masksToBounds = false
        adressLabel.layer.shadowRadius = 1.0
        adressLabel.layer.shadowOpacity = 0.1
        adressLabel.adjustsFontSizeToFitWidth = true
        
        whiteBlob.layer.shadowColor = UIColor.black.cgColor
        whiteBlob.layer.shadowOffset = CGSize(width: 0.0, height: 4.0)
        whiteBlob.layer.masksToBounds = false
        whiteBlob.layer.shadowRadius = 1.0
        whiteBlob.layer.shadowOpacity = 0.1
        
        lessPriceButton.alpha = 0.0
        lessWalkButton.alpha = 0.0
    }

    func addDestinationAnnotation(at destinationCoordinate2D: CLLocationCoordinate2D) {
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.title = "Your Spot"
//        destinationAnnotation.coordinate = getCenterLocation(for: mapView).coordinate
        destinationAnnotation.coordinate = destinationCoordinate2D
        mapView.addAnnotation(destinationAnnotation)
    }
    
    // resond to user tap "search" button
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Ignore user
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        // Activity Indicator
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.style = UIActivityIndicatorView.Style.gray
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        self.view.addSubview(activityIndicator)
        
        // Hide Keyboard
        searchBar.resignFirstResponder()
        // Hide SearchBar
        dismiss(animated: true, completion: nil)
        
        pinImg.alpha = 0.0
        
        // Create the Search Request
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchBar.text
        // Start the search
        let activeSearch = MKLocalSearch(request: searchRequest)
        
        activeSearch.start { (response, error) in
            
            activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            
            if response == nil {
                print("Error")
            } else {
                // Remove Annotations
                self.mapView.removeAnnotations(self.mapView.annotations)
                
                // Get data
                let latitude = response?.boundingRegion.center.latitude
                let longitude = response?.boundingRegion.center.longitude
                
                // Create anootation
                let annotation = MKPointAnnotation()
                annotation.title = searchBar.text
                annotation.coordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
                self.mapView.addAnnotation(annotation)
                
                // Zoom in annotation
                let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude!, longitude!)
                let span = MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                let region = MKCoordinateRegion(center: coordinate, span: span)
                self.mapView.setRegion(region, animated: true)
            }
            
        }
    }
    
    func fetchParkingData(destinationX: Double, destinationY: Double, price: Int, eDistance: Double, currentX: Double, currentY: Double) {
        let url = URL(string: "http://10.20.64.21:8080/\(destinationX)/\(destinationY)/\(price)/\(eDistance)/\(currentX)/\(currentY)")!
        
        URLSession.shared.dataTask(with: url) { data, response, error
            in
            guard let data = data else {
                print(error?.localizedDescription ?? "Unknown error")
                return
            }
            let results = String(data: data, encoding: String.Encoding.utf8) ?? "Unable to parse JSON response.\n"
            self.parkingLocationDegrees[0] = Double(results.split(separator: ",")[0])!
            self.parkingLocationDegrees[1] = Double(results.split(separator: ",")[1])!
            self.waiting = 0
            }.resume()
    }
    
    static func failCentered() {
        let messageView: MessageView = MessageView.viewFromNib(layout: .centeredView)
        messageView.configureBackgroundView(width: 250)
        messageView.configureContent(title: "Oops!", body: "Pikachu couldn't find you any parking spots here...", iconImage: UIImage(named: "pikachu-fail"), iconText: nil, buttonImage: nil, buttonTitle: "Never mind") { _ in
            SwiftMessages.hide()
        }
        messageView.backgroundView.backgroundColor = UIColor.init(white: 0.97, alpha: 1)
        messageView.backgroundView.layer.cornerRadius = 10
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .center
        config.duration = .forever
        config.dimMode = .blur(style: .dark, alpha: 1, interactive: true)
        config.presentationContext  = .window(windowLevel: UIWindow.Level.statusBar)
        SwiftMessages.show(config: config, view: messageView)
    }
    
    static func successTop() {
        let success = MessageView.viewFromNib(layout: .cardView)
        success.configureTheme(.success)
        success.configureDropShadow()
        success.configureContent(title: "Pika!", body: "Pikachu find you a spot")
        success.button?.isHidden = true
        var successConfig = SwiftMessages.defaultConfig
        successConfig.presentationStyle = .top
        successConfig.presentationContext = .window(windowLevel: UIWindow.Level.normal)
        SwiftMessages.show(config: successConfig, view: success)
    }
    
//    static func successCentered() {
//        let messageView: MessageView = MessageView.viewFromNib(layout: .centeredView)
//        messageView.configureBackgroundView(width: 250)
//        messageView.configureContent(title: "Pika!", body: "Pikachu find you a spot", iconImage: UIImage(named: "pikachu-success"), iconText: nil, buttonImage: nil, buttonTitle: "Show route") { _ in
//            SwiftMessages.hide()
//        }
//        messageView.backgroundView.backgroundColor = UIColor.init(white: 0.97, alpha: 1)
//        messageView.backgroundView.layer.cornerRadius = 10
//        var config = SwiftMessages.defaultConfig
//        config.presentationStyle = .center
//        config.duration = .forever
//        config.dimMode = .blur(style: .dark, alpha: 1, interactive: true)
//        config.presentationContext  = .window(windowLevel: UIWindow.Level.statusBar)
//        SwiftMessages.show(config: config, view: messageView)
//    }
    
    
    @IBAction func findParkingButtonTapped(_ sender: UIButton) {
        mapView.removeAnnotations(mapView.annotations)
        pinImg.alpha = 0.0 //can also animate pin to drop down to map
        adressLabel.alpha = 0.0
        searchImg.alpha = 0.0
        searchButton.isEnabled = false
        
        UIView.animate(withDuration: 0.2) {
            self.findParkingButton.alpha = 0.0
        }
        findParkingButton.isEnabled = false
        
        UIView.animate(withDuration: 0.4) {
            self.navigateButton.alpha = 1.0
        }
        navigateButton.isEnabled = true
        
        whiteBlob.alpha = 0.0
        
        priceLabel.alpha = 0.0
        lessPriceButton.alpha = 0.0
        lessPriceButton.isEnabled = false
        morePriceButton.alpha = 0.0
        morePriceButton.isEnabled = false
        
        walkLabel.alpha = 0.0
        lessWalkButton.alpha = 0.0
        lessWalkButton.isEnabled = false
        moreWalkButton.alpha = 0.0
        moreWalkButton.isEnabled = false
        
        let destinationCoordinate2D = getCenterLocation(for: mapView).coordinate
        let destinationX = destinationCoordinate2D.latitude
        let destinationY = destinationCoordinate2D.longitude
        
        guard let userCoordinate2D = locationManager.location?.coordinate else {
            // inform user we don't have their current location
            return
        }
        
        let currentX = Double(userCoordinate2D.latitude)
        let currentY = Double(userCoordinate2D.longitude)
        
        let price = self.userPrice
        let eDistance = Double(self.userWalk) / 1000
        
        fetchParkingData(destinationX: destinationX, destinationY: destinationY, price: price, eDistance: eDistance, currentX: currentX, currentY: currentY)
        
        //A function check whether we get response
        while waiting == 1 {
//            print("Waiting...")
        }
        
        waiting = 1
        
        if self.parkingLocationDegrees[0] == -999.0 {
            MapScreen.failCentered()
            centerButtonTapped(centerButton)   // error in this line
        } else {
            MapScreen.successTop()
//            MapScreen.successCenter()
        }
        
        print("Check it out! I've got latitude:", NSString(format: "%.10f", (self.parkingLocationDegrees)[0]), "longitude:", NSString(format: "%.10f", (self.parkingLocationDegrees)[1]))
        
        self.parkingCoordinate2D = CLLocationCoordinate2DMake(self.parkingLocationDegrees[0], self.parkingLocationDegrees[1])
        getDirections(destinationCoordinate2D: self.parkingCoordinate2D)
    }
    
    @IBAction func centerButtonTapped(_ sender: UIButton) {
        sender.pulsate()    // pulse animation
        
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        centerViewOnUserLocation()
        pinImg.alpha = 1.0
        adressLabel.alpha = 1.0
        searchImg.alpha = 1.0
        searchButton.isEnabled = true
        
        navigateButton.alpha = 0.0 // hide navi button
        navigateButton.isEnabled = false
        
        findParkingButton.alpha = 1.0  // show findParking button
        findParkingButton.isEnabled = true
        
        whiteBlob.alpha = 1.0
        
        priceLabel.alpha = 1.0
        if self.userPrice == 20 {
            morePriceButton.alpha = 0.0
            morePriceButton.isEnabled = false
            lessPriceButton.alpha = 1.0
            lessPriceButton.isEnabled = true
        } else if self.userPrice == 2 {
            morePriceButton.alpha = 1.0
            morePriceButton.isEnabled = true
            lessPriceButton.alpha = 0.0
            lessPriceButton.isEnabled = false
        } else{
            morePriceButton.alpha = 1.0
            morePriceButton.isEnabled = true
            lessPriceButton.alpha = 1.0
            lessPriceButton.isEnabled = true
        }
        
        walkLabel.alpha = 1.0
        if self.userWalk == 600 {
            moreWalkButton.alpha = 0.0
            moreWalkButton.isEnabled = false
            lessWalkButton.alpha = 1.0
            lessWalkButton.isEnabled = true
        } else if self.userWalk == 100 {
            moreWalkButton.alpha = 1.0
            moreWalkButton.isEnabled = true
            lessWalkButton.alpha = 0.0
            lessWalkButton.isEnabled = false
        } else{
            moreWalkButton.alpha = 1.0
            moreWalkButton.isEnabled = true
            lessWalkButton.alpha = 1.0
            lessWalkButton.isEnabled = true
        }
        
        self.parkingLocationDegrees = [0.0, 0.0]    // reset parking coordinates
        
//        MapScreen.successCentered()
//        MapScreen.failCentered()
    }
    @IBAction func navigateButtonTapped(_ sender: UIButton) {
//        let destinationCoordinate = getCenterLocation(for: mapView).coordinate // this should not be the current center location!
        let regionDistance: CLLocationDistance = 1000
        let regionSpan = MKCoordinateRegion(center: self.parkingCoordinate2D, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        
        let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)]
        let placemark = MKPlacemark(coordinate: self.parkingCoordinate2D)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "The spot, just for you!"
        mapItem.openInMaps(launchOptions: options)
    }
    
    @IBAction func searchButtonTapped(_ sender: UIButton) {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        present(searchController, animated: true, completion: nil)
    }
    
    @IBAction func lessPriceButtonTapped(_ sender: UIButton) {
        sender.pulsate2()
        
        morePriceButton.alpha = 1.0
        morePriceButton.isEnabled = true
        
        if self.userPrice > 0{
            if self.userPrice > 5 {
                self.userPrice += -5
            } else {
                self.userPrice += -3
            }
            priceLabel.text = String(self.userPrice) + " $/hr"
        }
        if self.userPrice == 2{
            lessPriceButton.alpha = 0.0
            lessPriceButton.isEnabled = false
        }
    }
    
    @IBAction func morePriceButtonTapped(_ sender: UIButton) {
        sender.pulsate2()
        
        lessPriceButton.alpha = 1.0
        lessPriceButton.isEnabled = true
        
        if self.userPrice < 20{
            if self.userPrice > 2 {
                self.userPrice += 5
            } else {
                self.userPrice += 3
            }
            priceLabel.text = String(self.userPrice) + " $/hr"
        }
        if self.userPrice == 20 {
            morePriceButton.alpha = 0.0
            morePriceButton.isEnabled = false
        }
    }

    @IBAction func lessWalkButtonTapped(_ sender: UIButton) {
        sender.pulsate2()
        
        moreWalkButton.alpha = 1.0
        moreWalkButton.isEnabled = true
        if self.userWalk > 100 {
            self.userWalk += -100
            walkLabel.text = String(self.userWalk) + "m walk"
        }
        if self.userWalk == 100{    // no less walk
            lessWalkButton.alpha = 0.0
            lessWalkButton.isEnabled = false
        }
    }
    
    @IBAction func moreWalkButtonTapped(_ sender: UIButton) {
        sender.pulsate2()
        
        lessWalkButton.alpha = 1.0
        lessWalkButton.isEnabled = true
        if self.userWalk < 600 {
            self.userWalk += 100
            walkLabel.text = String(self.userWalk) + "m walk"
        }
        if self.userWalk == 600{    // no more walk
            moreWalkButton.alpha = 0.0
            moreWalkButton.isEnabled = false
        }
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
