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
    
    var userLocButton: MKUserTrackingBarButtonItem!
    var showListButton: UIBarButtonItem!
    var tableHidden = false
    var containsSegmentControl = true
    
    /* Timer Fields */
    var startTime = NSTimeInterval() // start stopwatch timer

    
    var route: Route = Route(routeNum: 0, nameShort: "", nameLong: "")
    var stopAnnotation: MKAnnotation?
    var curStops: [Stop] = []
    var selectedStop: Stop?
    var locationManager = CLLocationManager()
    var userLocation: CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dividerHeightConstraintHigh.constant = 1/UIScreen.mainScreen().scale//enforces it to be a true 1 pixel line
        dividerHeightConstraintLow.constant = 1/UIScreen.mainScreen().scale//enforces it to be a true 1 pixel line

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
        tableView.reloadData()
    }
    
    // Hide the navController toolbar when leaving
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.toolbarHidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        checkLocationAuthorizationStatus()
    }
    
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
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
    
    
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
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
    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        for view in views {
            if view.annotation is StopAnnotation {
                view.superview?.bringSubviewToFront(view)
            } else {
                view.superview?.sendSubviewToBack(view)
            }
        }
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if let ann = (mapView.annotations.filter { $0 is StopAnnotation }.first as! StopAnnotation?) {
            if let view = mapView.viewForAnnotation(ann) {
                view.superview?.bringSubviewToFront(view)
            }
        }
    }
    
    func initBusAnnotations() {
        dispatch_async(dispatch_get_main_queue(), {
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

    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // scroll to top
        updateMapView()
        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .None, animated: true)
        // Update selected stop for newly selected tableViewCell
        selectedStop = self.curStops[indexPath.row]
        updateStopAnnotation()
        // Update the bus locations
        getDataFromBuses()
    }
    
    func updateStopAnnotation() {
        if stopAnnotation != nil { mapView.removeAnnotations(mapView.annotations.filter {$0 is StopAnnotation}) }
        dispatch_async(dispatch_get_main_queue()) {
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
    
    func containsNextStop(nextStopId: String) -> Bool {
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
    
    @IBAction func StopsSegmentedControlChoose(sender: AnyObject) {
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
        self.tableView.reloadData();
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Bottom)
        tableView(tableView, didSelectRowAtIndexPath: indexPath)
        
    }


    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = manager.location {
            userLocation = loc.coordinate
        } else {
            print("ERROR: Failed to update user location")
        }
    }
 
    func getDataFromBuses() {
        
        self.updateStopwatch()
        self.startTime = NSDate.timeIntervalSinceReferenceDate()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.route.refreshBuses()
            print("BUS DATA REFRESHED")
            guard let stop = self.selectedStop else {
                print("ERROR: selectedStop is nil")
                return
            }
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
            dispatch_async(dispatch_get_main_queue()) {
                self.mapView.addAnnotations(annArr)
            }
        }
    }

    func centerMapOnLocation(location: CLLocation, animated: Bool) {
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
        self.curStops = self.route.stops.sort {
            if let uCoord = self.locationManager.location?.coordinate {
                let uLoc = CLLocation(latitude: uCoord.latitude, longitude: uCoord.longitude)
                let stop0 = CLLocation(latitude: $0.location.latitude, longitude: $0.location.longitude)
                let stop1 = CLLocation(latitude: $1.location.latitude, longitude: $1.location.longitude)
                return stop0.distanceFromLocation(uLoc) < stop1.distanceFromLocation(uLoc)
            } else {
                print("RETURNING FALSE")
                return false
            }
        }
        
    }
    
    
    
    func generateCoordinates() {
        if(route.routeNum == 640 || route.routeNum == 642 ) {
            containsSegmentControl = false
            toolbar.hidden = true
            dividerLow.hidden = true
            dividerHigh.hidden = true
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
        tableView.backgroundColor = .clearColor()
        let blurEffect = UIBlurEffect(style: .Light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        tableView.backgroundView = blurEffectView
        tableView.separatorEffect = UIVibrancyEffect(forBlurEffect: blurEffect)
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
        showListButton = UIBarButtonItem(title: "Hide Stops", style: .Plain, target: self, action: Selector.buttonTapped)
        showListButton.tintColor = UIColor(red: 112/255, green: 183/255, blue: 132/255, alpha: 1)
        navigationController?.toolbarHidden = false
        let flexL = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace , target: self, action: nil)
        let flexR = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace , target: self, action: nil)
        toolbarItems = [userLocButton, flexL, showListButton, flexR]
        
    }
    
    func showListTapped(sender: UIBarButtonItem) {
        self.tableHidden = !self.tableHidden
        
        UIView.animateWithDuration(0.2) {
            self.tableView.hidden = self.tableHidden
            self.toolbar.hidden = self.containsSegmentControl ? self.tableHidden : true
            self.dividerHigh.hidden = self.containsSegmentControl ? self.tableHidden : true
            self.dividerLow.hidden = self.containsSegmentControl ? self.tableHidden : true
//            self.view.layoutIfNeeded()
        }
        print("Button Pressed")
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("StackCell", forIndexPath: indexPath)
        
        let curStopCoord = curStops[indexPath.row].location
        let curStopLoc = CLLocation(latitude: curStopCoord.latitude, longitude: curStopCoord.longitude)
        let userLoc: CLLocation?
        if let userCoord = self.locationManager.location?.coordinate {
            userLoc = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
            let distanceMeters = curStopLoc.distanceFromLocation(userLoc!)
            let distanceMiles = distanceMeters * 0.000621371
            cell.detailTextLabel!.text = String(format: "%.2f", distanceMiles) + " mi"
        } else {
            cell.detailTextLabel!.text = ""
        }
        let name:String = curStops[indexPath.row].name
        cell.textLabel!.text = name
        return cell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.curStops.count
    }
    
    func addRoutePolyline() {
        print("ADDING POLY")
        print(route.routeCoords.count)
        let polyline = MKPolyline(coordinates: &route.routeCoords, count: route.routeCoords.count)
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlay(polyline)
    }
 
    func updateStopwatch() {
        let currentTime = NSDate.timeIntervalSinceReferenceDate()
        
        //Find the difference between current time and start time.
        
        var elapsedTime: NSTimeInterval = currentTime - startTime
        //        print(elapsedTime)
        
        //calculate the minutes in elapsed time.
        
        let minutes = UInt32(elapsedTime / 60.0)
        
        elapsedTime -= (NSTimeInterval(minutes) * 60)
        
        //calculate the seconds in elapsed time.
        
        let seconds = UInt32(elapsedTime)
        
        elapsedTime -= NSTimeInterval(seconds)
        
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
    