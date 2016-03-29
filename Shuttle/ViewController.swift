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
    var stop:Stop = Stop(location: CLLocationCoordinate2D(latitude: 0, longitude: 0), name: "", stopID: "")
    
    var locationManager: CLLocationManager!
    let regionRadius: CLLocationDistance = 1000
    var startTime = NSTimeInterval() //start stopwatch timer
    
    
    @IBAction func zoomToUserLocation(sender: AnyObject) {
        var mapRegion = MKCoordinateRegion()
        mapRegion.center = self.mapView.userLocation.coordinate
        mapRegion.span.latitudeDelta = 0.2
        mapRegion.span.longitudeDelta = 0.2
        self.mapView.setRegion(mapRegion, animated: true)
    }
    
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
        annotateStop()
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
        
        self.navigationItem.title = "Buses for Route \(route.routeNum)" ;
    
        self.stopLat = self.stop.location.latitude
        self.stopLong = self.stop.location.longitude
        self.stopName = self.stop.name
        self.routeNum = self.route.routeNum
    }
    
    func refresh() {
        route.refreshBuses()
    }
    func addRoutePolyline() {
        let polyline = MKPolyline(coordinates: &route.routeCoords, count: route.routeCoords.count)
        self.mapView.addOverlay(polyline)
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
    
    func getCoordsFromStr() -> [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D]()
        if let dataFromStr = routeData640.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            let json = JSON(data: dataFromStr)
            for (_, val):(String, JSON) in json {
                let points = val["geometry"]["coordinates"].arrayObject as! [Double]
                let coord = CLLocationCoordinate2D(latitude: points[0], longitude: points[1])
                coords.append(coord)
            }
            print(coords)
        }
        return coords
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

    /*func getData() {
        
        let newUrlString = "http://52.88.82.199:8080/onebusaway-api-webapp/api/where/trips-for-route/1_640.json?key=TEST&includeSchedules=true&includeStatus=true&_=50000"
        
        let newURL = NSURL(string: newUrlString)
        var busLocations = [CLLocationCoordinate2D]()
        let newSession = NSURLSession.sharedSession()
        let newTask = newSession.dataTaskWithURL(newURL!) { (data, response, error) -> Void in
            if error != nil {
                print("ERROR FOUND")
            } else {
                let json = JSON(data: data!)
                let newData = json["data", "list"]
                for (_, subJson):(String, JSON) in newData {
                    let bus = subJson["status", "lastKnownLocation"].dictionaryValue
                    let lat = bus["lat"]!.double!
                    let lon = bus["lon"]!.double!
                    busLocations.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
                }
                self.buses = busLocations
                
                self.updateStopwatch()
                self.startTime = NSDate.timeIntervalSinceReferenceDate()
                
                // Have thread updating UI in foreground
                dispatch_async(dispatch_get_main_queue(), {
                    
                    // Create annotation from lattitude and longitude
                    self.mapView.removeAnnotations(self.mapView.annotations)
                    for (index, busCoord) in self.buses.enumerate() {
                        let annotation = BusAnnotation(coordinate: busCoord, title: "Bus 640", subtitle: "\(index)")
                        self.mapView.addAnnotation(annotation)
                    }
                    self.mapView.addAnnotation(self.stopAnnotation)
                })
            }
            
        }
        newTask.resume()
    }*/
    
    
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
            print(self.route.busesOnRoute)
            print("About to loop over all buses")
            for bus in self.route.busesOnRoute {
                //TODO not sure if orientaiton passing is cool here
                let annotation = BusAnnotation(coordinate: bus.location, title: "Bus \(self.route.routeNum)", subtitle: "Bus Id: \(bus.busId)", img: "Bus.png", orientation: bus.orientation)
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
            let image = resizeImage( UIImage(named: ann.img)!, newWidth: 30.0).imageRotatedByDegrees(CGFloat(self.route.busesOnRoute[0].orientation + 225), flip: false)
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
        mapView.setVisibleMapRect(routeRegion, edgePadding: UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0), animated: true)
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

    
    
    /* func add640Route() {
     var coords = [CLLocationCoordinate2D]()
     coords.append(CLLocationCoordinate2D(latitude: 30.283836, longitude: -97.741878))
     coords.append(CLLocationCoordinate2D(latitude: 30.289812, longitude: -97.741363))
     coords.append(CLLocationCoordinate2D(latitude: 30.289414, longitude: -97.736031))
     coords.append(CLLocationCoordinate2D(latitude: 30.289210, longitude: -97.732727))
     coords.append(CLLocationCoordinate2D(latitude: 30.289312, longitude: -97.731407))
     coords.append(CLLocationCoordinate2D(latitude: 30.289321, longitude: -97.731016))
     coords.append(CLLocationCoordinate2D(latitude: 30.289173, longitude: -97.730305))
     coords.append(CLLocationCoordinate2D(latitude: 30.288930, longitude: -97.729726))
     coords.append(CLLocationCoordinate2D(latitude: 30.288687, longitude: -97.729388))
     coords.append(CLLocationCoordinate2D(latitude: 30.288338, longitude: -97.729157))
     coords.append(CLLocationCoordinate2D(latitude: 30.287856, longitude: -97.729629))
     coords.append(CLLocationCoordinate2D(latitude: 30.287532, longitude: -97.729886))
     coords.append(CLLocationCoordinate2D(latitude: 30.285077, longitude: -97.730658))
     coords.append(CLLocationCoordinate2D(latitude: 30.285318, longitude: -97.733705))
     coords.append(CLLocationCoordinate2D(latitude: 30.283502, longitude: -97.734064))
     coords.append(CLLocationCoordinate2D(latitude: 30.283233, longitude: -97.734032))
     coords.append(CLLocationCoordinate2D(latitude: 30.283813, longitude: -97.741895))
     print(coords)
     let polyline = MKPolyline(coordinates: &coords, count: coords.count)
     self.mapView.addOverlay(polyline)
     } */

    var routeData640 = "[{ \"type\": \"Feature\", \"properties\": { \"ID\": 4136, \"STOPNAME\": \"300 21ST SAN JACINTO\", \"ONSTREET\": \"21ST\", \"ATSTREET\": \"SAN JACINTO\" }, \"geometry\": { \"type\": \"Point\", \"coordinates\": [ 3116788.6417877, 10076357.069287 ] } }, { \"type\": \"Feature\", \"properties\": { \"ID\": 3750, \"STOPNAME\": \"400 23RD SAN JACINTO\", \"ONSTREET\": \"23RD\", \"ATSTREET\": \"SAN JACINTO\" }, \"geometry\": { \"type\": \"Point\", \"coordinates\": [ 3117101.130664, 10077110.572374 ] } }, { \"type\": \"Feature\", \"properties\": { \"ID\": 4143, \"STOPNAME\": \"ROBERT DEDMAN TRINITY\", \"ONSTREET\": \"ROBERT DEDMAN\", \"ATSTREET\": \"TRINITY\" }, \"geometry\": { \"type\": \"Point\", \"coordinates\": [ 3118165.3047168, 10077858.024947 ] } }, { \"type\": \"Feature\", \"properties\": { \"ID\": 2005, \"STOPNAME\": \"701 DEAN KEETON SAN JACINTO\", \"ONSTREET\": \"DEAN KEETON\", \"ATSTREET\": \"SAN JACINTO\" }, \"geometry\": { \"type\": \"Point\", \"coordinates\": [ 3117688.2784399, 10078481.421666 ] } }, { \"type\": \"Feature\", \"properties\": { \"ID\": 5438, \"STOPNAME\": \"305 DEAN KEETON SAN JACINTO\", \"ONSTREET\": \"DEAN KEETON\", \"ATSTREET\": \"SAN JACINTO\" }, \"geometry\": { \"type\": \"Point\", \"coordinates\": [ 3116537.8693234, 10078500.28613 ] } }, { \"type\": \"Feature\", \"properties\": { \"ID\": 3512, \"STOPNAME\": \"201 DEAN KEETON UNIVERSITY\", \"ONSTREET\": \"DEAN KEETON\", \"ATSTREET\": \"UNIVERSITY\" }, \"geometry\": { \"type\": \"Point\", \"coordinates\": [ 3115235.3735688, 10078584.577628 ] } }, { \"type\": \"Feature\", \"properties\": { \"ID\": 1042, \"STOPNAME\": \"2231 GUADALUPE WEST MALL UT\", \"ONSTREET\": \"GUADALUPE\", \"ATSTREET\": \"WEST MALL UT\" }, \"geometry\": { \"type\": \"Point\", \"coordinates\": [ 3114542.7552034, 10077186.693284 ] } }, { \"type\": \"Feature\", \"properties\": { \"ID\": 2780, \"STOPNAME\": \"21ST WHITIS MID-BLOCK\", \"ONSTREET\": \"21ST\", \"ATSTREET\": \"WHITIS\" }, \"geometry\": { \"type\": \"Point\", \"coordinates\": [ 3114708.615764, 10076501.782909 ] } }, { \"type\": \"Feature\", \"properties\": { \"ID\": 5207, \"STOPNAME\": \"21ST SPEEDWAY\", \"ONSTREET\": \"21ST\", \"ATSTREET\": \"SPEEDWAY\" }, \"geometry\": { \"type\": \"Point\", \"coordinates\": [ 3115964.0200774, 10076403.71552 ] } }]"
}
