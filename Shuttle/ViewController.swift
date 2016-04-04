//
//  ViewController.swift
//  Shuttle
//
//  Created by Taylor Schmidt on 2/16/16.
//  Copyright © 2016 Taylor Schmidt. All rights reserved.
//

import UIKit
import MapKit
import SwiftyJSON
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    var route:Route = Route(routeNum: 0, nameShort: "", nameLong: "")
    var stop:Stop = Stop(location: CLLocationCoordinate2D(latitude: 0, longitude: 0), name: "", stopID: "", index: 0)
    var locationManager: CLLocationManager!
    let regionRadius: CLLocationDistance = 1000
    var startTime = NSTimeInterval() //start stopwatch timer
    var latitude:Double = 0
    var longitude:Double = 0
    var stopLat:  Double = 0
    var stopLong: Double = 0 //longitude for selected stop
    var stopName: String = ""
    var stopAnnotation: StopAnnotation!
    var routeNum: Int = 0
    
    var routePoints = [CLLocationCoordinate2D]()
    
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        self.mapView.rotateEnabled = false
        self.mapView.pitchEnabled = false
        annotateStop()
        
        // Decorate the navigation bar
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        
//        To set the navigation bar title to an image:
//        let logo = UIImage(named: "logo.png")
//        let imageView = UIImageView(image:logo)
//        self.navigationItem.titleView = imageView
        
        // Do any additional setup after loading the view, typically from a nib.
        self.startTime = NSDate.timeIntervalSinceReferenceDate()
        //let initialLocation = CLLocation(latitude: 30.302135, longitude: -97.740153)
        //centerMapOnLocation(initialLocation)
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        getDataFromBuses()
        _ = NSTimer.scheduledTimerWithTimeInterval(15, target: self, selector: #selector(ViewController.getDataFromBuses), userInfo: nil, repeats: true)
        
        //add640Route()
        addRoutePolyline()
        //print(self.routeNum)
        
        //self.navigationItem.title = "Buses for Route \(route.routeNum)"
        updateTitle()
        self.stopLat = self.stop.location.latitude
        self.stopLong = self.stop.location.longitude
        self.stopName = self.stop.name
        self.routeNum = self.route.routeNum
    }
    
    func refresh() {
        route.refreshBuses()
        updateTitle()
    }
    func addRoutePolyline() {
        let polyline = MKPolyline(coordinates: &route.routeCoords, count: route.routeCoords.count)
        self.mapView.addOverlay(polyline)
    }
    
    func updateTitle() {
        print("LAST UPDATE RUNNING")
        if let bus = route.busesOnRoute.last {
            self.navigationItem.titleView = setTitle("Buses for Route \(route.routeNum)", subtitle: "Last Update: \(bus.stringFromTimeInterval(bus.timeSinceUpdate))")
        } else {
            self.navigationItem.titleView = setTitle("No Buses on route \(route.routeNum)", subtitle: "")
        }
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
    
    @IBAction func zoomToUserLocation(sender: AnyObject) {
        var mapRegion = MKCoordinateRegion()
        mapRegion.center = self.mapView.userLocation.coordinate
        mapRegion.span.latitudeDelta = 0.02 // this is measured in degrees
        mapRegion.span.longitudeDelta = 0.02
        self.mapView.setRegion(mapRegion, animated: true)
    }
    
    func annotateStop() {
        // Create annotation from lattitude and longitude
        // Have thread updating UI in foreground
        dispatch_async(dispatch_get_main_queue(), {
            let coord: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: self.stopLat, longitude: self.stopLong)
            //let annotation = StopAnnotation(coordinate: coord, title: "Stop " + self.stopName, subtitle: "")
            self.stopAnnotation = StopAnnotation(coordinate: coord, title: "Stop at " + self.stopName, subtitle: "", img: "stop-circle.png")
            //self.mapView.removeAnnotations(self.mapView.annotations)
            self.mapView.addAnnotation(self.stopAnnotation)
            print(self.stopLat, self.stopLong)
            self.centerMapOnLocation(CLLocation(latitude: self.stopLat, longitude: self.stopLong)) //consider centering on stop instead
        })
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // get ahold of current Route object
    // Set up timer to periodically run refresh on this object
    // use the object's list of buses to populate map with annotations
    func getDataFromBuses() {
        print("in get get data from buses   ")
        
        self.route.refreshBuses()
        
        self.updateStopwatch()
        self.startTime = NSDate.timeIntervalSinceReferenceDate()
        
        // Have thread updating UI in foreground
        dispatch_async(dispatch_get_main_queue(), {

            // Create annotation from lattitude and longitude
            self.mapView.removeAnnotations(self.mapView.annotations)
            
            
            let distances = self.route.busDistancesFromStop(stopId: self.stop.stopId)
            for bus in self.route.busesOnRoute {
                //TODO not sure if orientaiton passing is cool here
                var distanceMiles: Double? = nil
                if let distanceMeters = distances[bus.busId] {
                    distanceMiles = distanceMeters * 0.000621371
                }
                let annotation: BusAnnotation
                if distanceMiles != nil {
                    annotation = BusAnnotation(coordinate: bus.location,
                        title: "Bus \(self.route.routeNum)",
                        subtitle: "Distance: \(String(format: "%.2f", distanceMiles!)) mi",
                        img: "Bus-Circle.png",
                        orientation: 0)
                } else {
                    annotation = BusAnnotation(coordinate: bus.location,
                        title: "Bus \(self.route.routeNum)",
                        subtitle: "Distance Unkown",
                        img: "Bus-Circle.png",
                        orientation: 0)
                }
                
                print("bus  latitude: \(bus.location.latitude), bus longitude: \(bus.location.longitude)")
                self.mapView.addAnnotation(annotation)
            }
            self.mapView.addAnnotation(self.stopAnnotation)
        })
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

    func updateStopwatch() {
        let currentTime = NSDate.timeIntervalSinceReferenceDate()
        
        //Find the difference between current time and start time.
        
        var elapsedTime: NSTimeInterval = currentTime - startTime
        print(elapsedTime)
        
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

    func centerMapOnLocation(location: CLLocation) {
        let polyline = MKPolyline(coordinates: &self.route.routeCoords, count: self.route.routeCoords.count)
        let routeRegion = polyline.boundingMapRect
        mapView.setVisibleMapRect(routeRegion, edgePadding: UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0), animated: false)
    }

    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        checkLocationAuthorizationStatus()
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

    //method found on StackOverflow: http://stackoverflow.com/questions/12914004/uinavigationbar-titleview-with-subtitle
    func setTitle(title:String, subtitle:String) -> UIView {
        //Create a label programmatically and give it its property's
        let titleLabel = UILabel(frame: CGRectMake(0, 0, 0, 0)) //x, y, width, height where y is to offset from the view center
        titleLabel.backgroundColor = UIColor.clearColor()
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.font = UIFont(name: "Avenir-Medium", size: 17)
        titleLabel.text = title
        titleLabel.sizeToFit()
        
        //Create a label for the Subtitle
        let subtitleLabel = UILabel(frame: CGRectMake(0, 18, 0, 0))
        subtitleLabel.backgroundColor = UIColor.clearColor()
        subtitleLabel.textColor = UIColor.lightGrayColor()
        subtitleLabel.font = UIFont.systemFontOfSize(12)
        subtitleLabel.text = subtitle
        subtitleLabel.sizeToFit()
        
        // Create a view and add titleLabel and subtitleLabel as subviews setting
        let titleView = UIView(frame: CGRectMake(0, 0, max(titleLabel.frame.size.width, subtitleLabel.frame.size.width), 30))
        
        // Center title or subtitle on screen (depending on which is larger)
        if titleLabel.frame.width >= subtitleLabel.frame.width {
            var adjustment = subtitleLabel.frame
            adjustment.origin.x = titleView.frame.origin.x + (titleView.frame.width/2) - (subtitleLabel.frame.width/2)
            subtitleLabel.frame = adjustment
        } else {
            var adjustment = titleLabel.frame
            adjustment.origin.x = titleView.frame.origin.x + (titleView.frame.width/2) - (titleLabel.frame.width/2)
            titleLabel.frame = adjustment
        }
        
        titleView.addSubview(titleLabel)
        titleView.addSubview(subtitleLabel)
        
        return titleView
    }
}
