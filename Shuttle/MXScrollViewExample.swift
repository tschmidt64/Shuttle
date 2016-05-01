//
//  MXScrollViewExample.swift
//  Clutch
//
//  Created by Taylor Schmidt on 4/23/16.
//  Copyright © 2016 Taylor Schmidt. All rights reserved.
//

import UIKit
import MXParallaxHeader
import MapKit

class MXScrollViewExample: UITableViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    /* Map Fields */
    var mapView = MKMapView(frame: CGRectZero)
    var locationManager: CLLocationManager?
    var userLocation: CLLocationCoordinate2D?
    
    // Map Annotations
    var route: Route!
//    var stop = Stop(location: CLLocationCoordinate2D(latitude: 0, longitude: 0), name: "", stopID: "", index: 0)
    var stopAnnotation: MKAnnotation?
    
    /* TableView Fields */
    var curStops:[Stop] = []
    var selectedStop: Stop?
    
    /* Timer Fields */
    var startTime = NSTimeInterval() // start stopwatch timer
    
    @IBOutlet weak var StopsSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Perform Setup
        setUpMap()
        sortStops()
        
        // Select the first item in the tableview
        selectedStop = curStops.first
        tableView.reloadData()
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Top)
        tableView(tableView, didSelectRowAtIndexPath: indexPath)
        
        initBusAnnotations()
        self.navigationItem.title = "Stops for Route \(route.routeNum)"
        
        _ = NSTimer.scheduledTimerWithTimeInterval(15, target: self, selector: #selector(MXScrollViewExample.getDataFromBuses), userInfo: nil, repeats: true)
//        _ = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(ViewController.updateTitle), userInfo: nil, repeats: true)
        
        getDataFromBuses()
        addRoutePolyline()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // Hide segmented control if only one direction
        if(route.routeNum == 640 || route.routeNum == 642 ) {
            navigationController?.setToolbarHidden(true, animated: animated)
        } else {
            navigationController?.setToolbarHidden(false, animated: animated)
            let userLocButton = MKUserTrackingBarButtonItem(mapView: mapView)
            let flexLeft = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
            let flexRight = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
            let seg = UIBarButtonItem(customView: StopsSegmentedControl)
            seg.width = (navigationController?.toolbar.frame.width)! - 100
            self.setToolbarItems([userLocButton, flexLeft, seg, flexRight], animated: animated)
        }

    }
    
    
//    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        <#code#>
//    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    // - Update the bus data from OneBusAway API
    // - Check the bus annotations and re-add ones with new locations
    func getDataFromBuses() {
        self.route.refreshBuses()
        
        self.updateStopwatch()
        self.startTime = NSDate.timeIntervalSinceReferenceDate()
        
        dispatch_async(dispatch_get_main_queue(), {
            guard let stop = self.selectedStop else {
                print("ERROR: selectedStop is nil")
                return
            }
            let distances = self.route.busDistancesFromStop(stop)
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
                        self.mapView.addAnnotation(annotation)
                    }
                } else {
                    print("ERROR: no bus found for id = \(id)")
                }
            }
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        checkLocationAuthorizationStatus()
    }
    
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            if let locMan = locationManager {
                locMan.requestWhenInUseAuthorization()
            } else {
                print("ERROR: locationManager was nil")
            }
        }
    }
    
    // MARK: - Table view delegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
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
        dispatch_async(dispatch_get_main_queue(), {
            guard let stop = self.selectedStop else {
                print("ERROR: selectedStop was nil")
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
        })
        
    }
    override func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
//        super.scrollViewDidEndScrollingAnimation(scrollView)
        // Re-center the map view, etc
        updateMapView()
    }
    
    // Initialize stop and bus annotations
    func initBusAnnotations() {
        dispatch_async(dispatch_get_main_queue(), {
            guard let stop = self.selectedStop else {
                print("ERROR: selectedStop was nil")
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
        var coords = route.routeCoords
        let polyline = MKPolyline(coordinates: &coords, count: coords.count)
        let routeRegion = polyline.boundingMapRect
        mapView.setVisibleMapRect(routeRegion, edgePadding: UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0), animated: animated)
    }
    
    // Add the polyline overlay for the route path to the mapview
    func addRoutePolyline() {
        let polyline = MKPolyline(coordinates: &route.routeCoords, count: route.routeCoords.count)
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlay(polyline)
    }
    
    func setUpMap() {
        // MARK: MKMapViewDelegate
        mapView.delegate = self
        mapView.showsPointsOfInterest = false
        
        // Parallax Header
        tableView.parallaxHeader.view = mapView
        tableView.parallaxHeader.height = 350
        tableView.parallaxHeader.mode = .Fill
        tableView.parallaxHeader.minimumHeight = 0
        
        // Need to select default of zero for these two routes
        // They are circular routes (640 run clockwise, 642 runs counter-clockwise)
        // I referenced capmetro pdf for this info
        // https://www.capmetro.org/uploadedFiles/Capmetroorg/Schedules_and_Maps/ut-shuttles.pdf
        if(route.routeNum == 640 || route.routeNum == 642 ) {
            route.generateStopCoords(0)
            route.generateRouteCoords(0)
        }
        
        // Set up user location
        locationManager = CLLocationManager()
        locationManager!.delegate = self
        locationManager!.startUpdatingLocation()
        locationManager!.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = manager.location {
            userLocation = loc.coordinate
        } else {
            print("ERROR: Failed to update user location")
        }
    }
    
    // Determines whether or not the bus
    func containsNextStop(nextStopId: String) -> Bool {
        if(nextStopId == "") {
            return true;
        }
        
        for stop in curStops {
            if(nextStopId == stop.stopId) {
                return true;
            }
        }
        return false;
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
    
    // MARK: - Scroll view delegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        NSLog("progress %f", scrollView.parallaxHeader.progress)
    }
    
    //method used to switch what direction routes we present in the tableview
    @IBAction func StopsSegmentedControlChoose(sender: AnyObject) {
        if StopsSegmentedControl.selectedSegmentIndex == 0 {
            route.generateStopCoords(1)
            route.generateRouteCoords(1)
        } else {
            route.generateStopCoords(0)
            route.generateRouteCoords(0)
        }
        // Sort newly assigned stops
        sortStops()
        // Select first stop on new segment
        selectedStop = curStops.first
        self.tableView.reloadData();
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Bottom)
        tableView(tableView, didSelectRowAtIndexPath: indexPath)
        
    }
    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        for v in views {
            if v.annotation is StopAnnotation {
                v.superview?.bringSubviewToFront(v)
            } else {
                v.sendSubviewToBack(v)
            }
        }
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        for ann in mapView.annotations {
            if ann is StopAnnotation {
                let v = mapView.viewForAnnotation(ann)
                v?.superview?.bringSubviewToFront(v!)
            }
            
        }
    }
    
    
    func sortStops() {
        // Sort stops by distance from user
        self.curStops = self.route.stops.sort {
            if let uCoord = self.locationManager!.location?.coordinate {
                let uLoc = CLLocation(latitude: uCoord.latitude, longitude: uCoord.longitude)
                let stop0 = CLLocation(latitude: $0.location.latitude, longitude: $0.location.longitude)
                let stop1 = CLLocation(latitude: $1.location.latitude, longitude: $1.location.longitude)
                return stop0.distanceFromLocation(uLoc) < stop1.distanceFromLocation(uLoc)
            } else { return false }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.curStops.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)
        
        let curStopCoord = curStops[indexPath.row].location
        let curStopLoc = CLLocation(latitude: curStopCoord.latitude, longitude: curStopCoord.longitude)
        let userLoc: CLLocation?
        if let userCoord = self.locationManager!.location?.coordinate {
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
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if overlay is MKPolyline {
            let polyRenderer = MKPolylineRenderer(overlay: overlay)
            polyRenderer.strokeColor = UIColor(red: 0.5703125, green: 0.83203125, blue: 0.63671875, alpha: 0.8)
            polyRenderer.lineWidth = 5
            return polyRenderer
        }
        return nil
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        // Get the new view controller using segue.destinationViewController.
//        // Pass the selected object to the new view controller.
//        
//        // Get the new view controller using segue.destinationViewController.
//        // Pass the selected object to the new view controller.
//        print("================ HERE =================")
//        let indexPath:NSIndexPath? = self.tableView!.indexPathForSelectedRow
//        let index = indexPath?.row
//        
//        //pass selected route into viewcontroller by sending the string for the route and the array for the route
//        let vc:ViewController = segue.destinationViewController as! ViewController
//        
//        vc.stop = self.curStops[index!]
//        vc.route = self.route
//        
//        //set back button for next screen
//        let backItem = UIBarButtonItem()
//        backItem.title = "Stops"
//        navigationItem.backBarButtonItem = backItem
//    }
    
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
    
    // Called by mapview when adding new annotation
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var view: MKAnnotationView
        if(annotation is StopAnnotation) {
            let ann = annotation as! StopAnnotation
            view = MKAnnotationView(annotation: ann, reuseIdentifier: "stop")
            //view.pinTintColor = MKPinAnnotationView.greenPinColor()
            let image = resizeImage( UIImage(named: ann.img)!, newWidth: 15.0)
            view.image = image
        } else if (annotation is BusAnnotation) {
            let ann = annotation as! BusAnnotation
            view = MKAnnotationView(annotation: ann, reuseIdentifier: "bus")
            //view.pinTintColor = MKPinAnnotationView.redPinColor()
            // ROTATE IMAGE
            // READ EXTENSION DOWN BELOW, GOT FROM:
            // http://stackoverflow.com/questions/27092354/rotating-uiimage-in-swift
            //TODO I think all the buses look like they are moving backward, so might need to adjust the orientation modifier (+10) more
            let image = resizeImage( UIImage(named: ann.img)!, newWidth: 30.0)
            view.image = image
        } else {
            return nil
        }
        view.canShowCallout = true
        return view
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
