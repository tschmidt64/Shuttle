//
//  ViewController.swift
//  Shuttle
//
//  Created by Taylor Schmidt on 2/16/16.
//  Copyright © 2016 Taylor Schmidt. All rights reserved.
//

import UIKit
import MapKit
import ArcGIS


class ViewController: UIViewController, CLLocationManagerDelegate {
    var locationManager: CLLocationManager!
    let regionRadius: CLLocationDistance = 1000
    var startTime = NSTimeInterval() //start stopwatch timer
    var latitude:Double = 0;
    var longitude:Double = 0;

    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.startTime = NSDate.timeIntervalSinceReferenceDate()
        let initialLocation = CLLocation(latitude: 30.302135, longitude: -97.740153)
        centerMapOnLocation(initialLocation)
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        getData()
        var timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "getData", userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getData() {
        let urlPath = "https://data.texas.gov/download/cuc7-ywmd/text/plain"
        let url:NSURL? = NSURL(string: urlPath)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithURL(url!) { (data, response, error) -> Void in
            if error != nil {
                print("error found")
            } else {
                do {
                    let jsonResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary
                    if jsonResult != nil {
                        if let allArray = jsonResult!["entity"] as? NSArray {
                            if(allArray.count > 0) {
                                let randomBus:NSDictionary = allArray[1] as! NSDictionary;
                                let randomBus2:NSDictionary = randomBus["vehicle"] as! NSDictionary
                                let positionSub:NSDictionary = randomBus2["position"] as! NSDictionary
                                let tripSub:NSDictionary = randomBus2["trip"] as! NSDictionary
                                let route:String = tripSub["route_id"] as! String
                                let lat:Double = positionSub["latitude"] as! Double
                                let long:Double = positionSub ["longitude"] as! Double
                                
                                
                                if(lat != self.latitude || long != self.longitude) {
                                    //values have changed since last pull, update global versions and restart stopwatch
                                    //self.startTime = NSTimeInterval() //update stopwatch
                                    self.latitude = lat
                                    self.longitude = long
                                    print("Update!")
                                    self.updateStopwatch()
                                    self.startTime = NSDate.timeIntervalSinceReferenceDate()
                                }

                                
                                // Have thread updating UI in foreground
                                dispatch_async(dispatch_get_main_queue(), {
                                    
                                    // Create annotation from lattitude and longitude
                                    let coord: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: lat, longitude: long)
                                    let annotation = MapPin(coordinate: coord, title: "Route" + route, subtitle: "")
                                    self.mapView.addAnnotation(annotation)
                                    self.centerMapOnLocation(CLLocation(latitude: lat, longitude: long))
                                    
                                })

                                print("Route ID: " + route)
                                print("Lat: " + String(lat))
                                print("Long:" + String(long))
                                print("")
                            } else {
                                print("ERROR - Something wrong w/ JSON")
                            }
                        }
                    }
                } catch {
                    print("Exception found")
                }
            }
        }
        task.resume() // start the request */
    }

    // Called by mapview when adding new annotation
    func mapView(mapView: MKMapView, annotation: MapPin) -> MKPinAnnotationView {
        // Remove all annotations from the map view
        self.mapView.removeAnnotations(self.mapView.annotations)
        let view:MKPinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "mcniff")
        view.canShowCallout = true
        return view
    }
    
    func updateStopwatch() {
        var currentTime = NSDate.timeIntervalSinceReferenceDate()
        
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
        
        let strMinutes = String(format: "%02d", minutes)
        let strSeconds = String(format: "%02d", seconds)
        
        print(strMinutes)
        print(strSeconds)
    }


    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
            regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
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




}

