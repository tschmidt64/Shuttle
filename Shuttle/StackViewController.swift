//
//  StackViewController.swift
//  Pods
//
//  Created by Taylor Schmidt on 5/1/16.
//
//

import Foundation
import UIKit
import MapKit


class StackViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapTableStack: UIStackView!
    @IBOutlet weak var toolbar: UIView!
    @IBOutlet weak var stopsSegmentedControl: UISegmentedControl!
    @IBOutlet weak var dividerHeightConstraintHigh: NSLayoutConstraint!
    @IBOutlet weak var dividerHeightConstraintLow: NSLayoutConstraint!
    @IBOutlet weak var dividerHigh: UIView!
    @IBOutlet weak var dividerLow: UIView!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    
    var activitySpinnerView: UIActivityIndicatorView?
    
    @IBAction func refreshButtonPress(_ sender: AnyObject) {
        getDataFromBuses()
    }
    
    var userLocButton: MKUserTrackingBarButtonItem!
    var showListButton: UIBarButtonItem!
    var tableHidden = false
    var containsSegmentControl = true
    
    /* Timer Fields */
    var startTime = TimeInterval() // start stopwatch timer

    
    var route: Route = Route(routeNum: 0, nameShort: "", nameLong: "")
    var stopAnnotation: MKAnnotation?
    var curStops: [Stop] = []
    var selectedStop: Stop?
    var locationManager = CLLocationManager()
    var userLocation: CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Route \(route.routeNum)"
        dividerHeightConstraintHigh.constant = 1/UIScreen.main.scale//enforces it to be a true 1 pixel line
        dividerHeightConstraintLow.constant = 1/UIScreen.main.scale//enforces it to be a true 1 pixel line

        // Get's coordinates for stops and buses
        setupTableView()
        setupMap()
        setupLocationManager()
        generateCoordinates()
        sortAndSetStops()
        selectedStop = curStops.first
        initBusAnnotations()
        addRoutePolyline()
        setupToolbar()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        StopsSegmentedControlChoose(self)
    }
    
    // Hide the navController toolbar when leaving
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isToolbarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkLocationAuthorizationStatus()
    }
    
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view: MKAnnotationView
        if(annotation is StopAnnotation) {
            let ann = annotation as! StopAnnotation
            view = MKAnnotationView(annotation: ann, reuseIdentifier: "stop")
            //view.pinTintColor = MKPinAnnotationView.greenPinColor()
            let image = UIImage(named: ann.img)
            view.image = image
        } else if (annotation is BusAnnotation) {
            let ann = annotation as! BusAnnotation
            view = MKAnnotationView(annotation: ann, reuseIdentifier: "bus")
            //view.pinTintColor = MKPinAnnotationView.redPinColor()
            // ROTATE IMAGE
            // READ EXTENSION DOWN BELOW, GOT FROM:
            // http://stackoverflow.com/questions/27092354/rotating-uiimage-in-swift
            //TODO I think all the buses look like they are moving backward, so might need to adjust the orientation modifier (+10) more
            let image = UIImage(named: ann.img)
            view.image = image
        } else {
            return nil
        }
        view.canShowCallout = true
        return view
    }
    
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polyRenderer = MKPolylineRenderer(overlay: overlay)
//            polyRenderer.strokeColor = UIColor(red: 0.5703125, green: 0.83203125, blue: 0.63671875, alpha: 0.8)
            polyRenderer.strokeColor = UIColor(red: 49/255, green: 131/255, blue: 255/255, alpha: 1)
            polyRenderer.lineWidth = 4
            return polyRenderer
        } else {
            let polyRenderer = MKPolygonRenderer(overlay: overlay)
            return polyRenderer 
        }
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {
            if view.annotation is StopAnnotation {
                view.superview?.bringSubview(toFront: view)
            } else {
                view.superview?.sendSubview(toBack: view)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if let ann = (mapView.annotations.filter { $0 is StopAnnotation }.first as! StopAnnotation?) {
            if let view = mapView.view(for: ann) {
                view.superview?.bringSubview(toFront: view)
            }
        }
    }
    
    func initBusAnnotations() {
        DispatchQueue.main.async(execute: {
            guard let stop = self.selectedStop else {
                print("ERROR: initBusAnnotations selectedStop was nil")
                return
            }
            let lat = stop.location.latitude
            let lon = stop.location.longitude
            let stopName = stop.name
            
            let coord: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            self.stopAnnotation = StopAnnotation(coordinate: coord, title: "Stop at " + stopName, subtitle: "", img: "Bus-Stop.png")
            guard let annotation = self.stopAnnotation else {
                print("ERROR: annotation = nil")
                return
            }
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.mapView.addAnnotation(annotation as! StopAnnotation)
            
            let distances = self.route.busDistancesFromStop(stop)
            for (_, bus) in self.route.busesOnRoute {
                if(self.containsNextStop(bus.nextStopId)) {
                    //TODO not sure if orientaiton passing is cool here
                    var distanceMiles: Double? = nil
                    if let distanceMeters = distances[bus.busId] {
                        distanceMiles = distanceMeters * 0.000621371
                    }
                    let annotation: BusAnnotation
                    if distanceMiles != nil {
                        annotation = BusAnnotation(coordinate: bus.location,
                            title: "\(String(format: "%.2f", distanceMiles!)) miles to stop",
                            subtitle: "",
                            img: "Bus-Circle.png",
                            orientation: 0,
                            busId: bus.busId)
                    } else {
                        annotation = BusAnnotation(coordinate: bus.location,
                            title: "Bus \(self.route.routeNum)",
                            subtitle: "Distance Unkown",
                            img: "Bus-Circle.png",
                            orientation: 0,
                            busId: bus.busId)
                    }
                    
                    //print("bus  latitude: \(bus.location.latitude), bus longitude: \(bus.location.longitude)")
                    
                    print("ADDING ANNOTATION")
                    self.mapView.addAnnotation(annotation)
                }
            }
            self.centerMapOnLocation(CLLocation(latitude: lat, longitude: lon), animated: true) //consider centering on stop instead
        })
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // scroll to top
        updateMapView()
        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .none, animated: true)
        // Update selected stop for newly selected tableViewCell
        selectedStop = self.curStops[(indexPath as NSIndexPath).row]
        updateStopAnnotation()
        // Update the bus locations
        // getDataFromBuses()
        updateBusAnnotations()
    }
    
    func updateStopAnnotation() {
        if stopAnnotation != nil { mapView.removeAnnotations(mapView.annotations.filter {$0 is StopAnnotation}) }
        DispatchQueue.main.async {
            guard let stop = self.selectedStop else {
                print("ERROR: updateStopAnnotation selectedStop was nil")
                return
            }
            let lat = stop.location.latitude
            let lon = stop.location.longitude
            let stopName = stop.name
            
            let coord: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            self.stopAnnotation = StopAnnotation(coordinate: coord, title: "Stop at " + stopName, subtitle: "", img: "Bus-Stop.png")
            guard let annotation = self.stopAnnotation else {
                print("ERROR: annotation = nil")
                return
            }
            self.mapView.addAnnotation(annotation as! StopAnnotation)
        }
        
    }
 
    func updateMapView() {
        guard let stop = selectedStop else {
            print("ERROR: stop was nil")
            return
        }
        addRoutePolyline()
        let location = CLLocation(latitude: stop.location.latitude, longitude: stop.location.longitude)
        centerMapOnLocation(location, animated: true)
    }
    
    func containsNextStop(_ nextStopId: String) -> Bool {
        if(nextStopId == "") {
            print("ERROR: No next stop id")
            return true;
        }
        
        for stop in curStops {
            if(nextStopId == stop.stopId) {
                print("Found next stop")
                return true;
            }
        }
        print("Next stop not in stops")
        return false;
    }
    
    @IBAction func StopsSegmentedControlChoose(_ sender: AnyObject) {
        if stopsSegmentedControl.selectedSegmentIndex == 1 {
            print("selected 1")
            route.generateStopCoords(1)
            route.generateRouteCoords(1)
        } else {
            print("selected 0")
            route.generateStopCoords(0)
            route.generateRouteCoords(0)
        }
        initBusAnnotations()
        // Sort newly assigned stops
        sortAndSetStops()
        // Select first stop on new segment
        selectedStop = curStops.first
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
        tableView(tableView, didSelectRowAt: indexPath)
        DispatchQueue.main.async {
            self.tableView.reloadData();
        }
    }


    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = manager.location {
            userLocation = loc.coordinate
        } else {
            print("ERROR: Failed to update user location")
        }
    }
    
    func updateBusAnnotations() {
        guard let stop = self.selectedStop else {
            print("ERROR: selectedStop is nil")
            return
        }
        let selectedAnn = mapView.selectedAnnotations
        for ann in selectedAnn { mapView.deselectAnnotation(ann, animated: true) }
        let distances = self.route.busDistancesFromStop(stop)
        var annArr: [BusAnnotation] = []
        for annotation in ((self.mapView.annotations.filter() { $0 is BusAnnotation }) as! [BusAnnotation]) {
            let id = annotation.busId
            if let bus = self.route.busesOnRoute[id] {
                var distanceMiles: Double? = nil
                if let distanceMeters = distances[id] {
                    distanceMiles = distanceMeters * 0.000621371
                    annotation.title = "\(String(format: "%.2f", distanceMiles!)) miles to stop"
                } else {
                    annotation.title = "Distance unknown"
                }
                if annotation.coordinate.latitude != bus.location.latitude
                    || annotation.coordinate.longitude != bus.location.longitude {
                    annotation.coordinate = bus.location
                    annArr.append(annotation)
                }
            } else {
                print("ERROR: no bus found for id = \(id)")
            }
        }
        self.mapView.addAnnotations(annArr)
    }
 
    func getDataFromBuses() {
        
        self.updateStopwatch()
        self.startTime = Date.timeIntervalSinceReferenceDate
        DispatchQueue.global(qos: .default).async {
            self.route.refreshBuses {
                print("=== BUSES UPDATED ===")
                self.updateBusAnnotations()
            }
        }
    }

    func centerMapOnLocation(_ location: CLLocation, animated: Bool) {
        // This zooms over the user and the stop as an alternative.
        // It doesn't seem to always show the stop though; sometimes it is covered up
        // so I commented it out and am now just using the whole route
        //        var coords: [CLLocationCoordinate2D]
        //        if let stopAn = stopAnnotation, userLoc = userLocation {
        //            coords = [userLoc, stopAn.coordinate]
        //        } else {
        //            print("HERE BITCH")
        //            coords = route.routeCoords
        //        }
        // Get bus coords
        let buses = Array(route.busesOnRoute.values)
        let busCoords = buses.map { $0.location }
        var coords = busCoords + route.routeCoords
        let polyline = MKPolyline(coordinates: &coords, count: coords.count)
        let routeRegion = polyline.boundingMapRect
        mapView.setVisibleMapRect(routeRegion, edgePadding: UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0), animated: animated)
    }

    
    func sortAndSetStops() {
        // Sort stops by distance from user
        if self.route.stops.isEmpty {
            print("======== Self.route.stops is empty =========")
        }
        self.curStops = self.route.stops.sorted {
            if let uCoord = self.locationManager.location?.coordinate {
                let uLoc = CLLocation(latitude: uCoord.latitude, longitude: uCoord.longitude)
                let stop0 = CLLocation(latitude: $0.location.latitude, longitude: $0.location.longitude)
                let stop1 = CLLocation(latitude: $1.location.latitude, longitude: $1.location.longitude)
                return stop0.distance(from: uLoc) < stop1.distance(from: uLoc)
            } else {
                print("RETURNING FALSE")
                return false
            }
        }
        
    }
    
    
    
    func generateCoordinates() {
        if(route.routeNum == 640 || route.routeNum == 642 ) {
            containsSegmentControl = false
            toolbar.isHidden = true
            dividerLow.isHidden = true
            dividerHigh.isHidden = true
            print("BEFORE")
            print(route.stops)
            route.generateStopCoords(0)
            route.generateRouteCoords(0)
            print(route.stops)
            print("AFTER")
            //do this because these routes only have on direction, so need to be set on 0
//            StopsSegmentedControl.hidden = true
//            self.navBar.removeFromSuperview()
//            self.tableView.contentInset = UIEdgeInsets(top: -44.0, left: 0.0, bottom: 0.0, right: 0.0)
        }
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        tableView.backgroundView = blurEffectView
        tableView.separatorEffect = UIVibrancyEffect(blurEffect: blurEffect)
    }
    
    func setupMap() {
        mapView.delegate = self
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    func setupToolbar() {
        userLocButton = MKUserTrackingBarButtonItem(mapView: mapView)
        userLocButton.customView?.tintColor = UIColor(red: 112/255, green: 183/255, blue: 132/255, alpha: 1)
        if tableHidden {
            showListButton = UIBarButtonItem(title: "Show Stops", style: .plain, target: self, action: Selector.buttonTapped)
        } else {
            showListButton = UIBarButtonItem(title: "Hide Stops", style: .plain, target: self, action: Selector.buttonTapped)
        }
        showListButton.tintColor = UIColor(red: 112/255, green: 183/255, blue: 132/255, alpha: 1)
        navigationController?.isToolbarHidden = false
        let flexL = UIBarButtonItem(barButtonSystemItem: .flexibleSpace , target: self, action: nil)
        let flexR = UIBarButtonItem(barButtonSystemItem: .flexibleSpace , target: self, action: nil)
        toolbarItems = [userLocButton, flexL, showListButton, flexR]
        
    }
    
    func showListTapped(_ sender: UIBarButtonItem) {
        self.tableHidden = !self.tableHidden
        
        UIView.animate(withDuration: 0.2, animations: {
            self.tableView.isHidden = self.tableHidden
            self.toolbar.isHidden = self.containsSegmentControl ? self.tableHidden : true
            self.dividerHigh.isHidden = self.containsSegmentControl ? self.tableHidden : true
            self.dividerLow.isHidden = self.containsSegmentControl ? self.tableHidden : true
//            self.view.layoutIfNeeded()
        }) 
        setupToolbar()
        print("Button Pressed")
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StackCell", for: indexPath)
        
        let curStopCoord = curStops[(indexPath as NSIndexPath).row].location
        let curStopLoc = CLLocation(latitude: curStopCoord.latitude, longitude: curStopCoord.longitude)
        let userLoc: CLLocation?
        if let userCoord = self.locationManager.location?.coordinate {
            userLoc = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
            let distanceMeters = curStopLoc.distance(from: userLoc!)
            let distanceMiles = distanceMeters * 0.000621371
            cell.detailTextLabel!.text = String(format: "%.2f", distanceMiles) + " mi"
        } else {
            cell.detailTextLabel!.text = ""
        }
        let name:String = curStops[(indexPath as NSIndexPath).row].name
        cell.textLabel!.text = name
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.curStops.count
    }
    
    func addRoutePolyline() {
        print("ADDING POLY")
        print(route.routeCoords.count)
        let polyline = MKPolyline(coordinates: &route.routeCoords, count: route.routeCoords.count)
        mapView.removeOverlays(mapView.overlays)
        mapView.add(polyline)
    }
 
    func updateStopwatch() {
        let currentTime = Date.timeIntervalSinceReferenceDate
        
        //Find the difference between current time and start time.
        
        var elapsedTime: TimeInterval = currentTime - startTime
        //        print(elapsedTime)
        
        //calculate the minutes in elapsed time.
        
        let minutes = UInt32(elapsedTime / 60.0)
        
        elapsedTime -= (TimeInterval(minutes) * 60)
        
        //calculate the seconds in elapsed time.
        
        let seconds = UInt32(elapsedTime)
        
        elapsedTime -= TimeInterval(seconds)
        
        //add the leading zero for minutes, seconds and millseconds and store them as string constants
        /*
         let strMinutes = String(format: "%02d", minutes)
         let strSeconds = String(format: "%02d", seconds)
         
         print(strMinutes)
         print(strSeconds)
         */
    }

    
}

private extension Selector {
    static let buttonTapped = #selector(StackViewController.showListTapped(_:))
}
    
