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


class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    var locationManager: CLLocationManager!
    let regionRadius: CLLocationDistance = 1000
    var startTime = NSTimeInterval() //start stopwatch timer
    var latitude:Double = 0;
    var longitude:Double = 0;
    //var busDict = [String:[AnyObject]]()
    var busDict = [String:AnyObject]()
    var stopLat:Double = 0 //lattitude for selected stop
    var stopLong:Double = 0 //longitude for selected stop
    var stopName:String = ""
    
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
        getData()
        var timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "getData", userInfo: nil, repeats: true)
    }
    
    func annotateStop() {
        // Create annotation from lattitude and longitude
        // Have thread updating UI in foreground
        dispatch_async(dispatch_get_main_queue(), {
            let coord: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: self.stopLat, longitude: self.stopLong)
            //let annotation = StopAnnotation(coordinate: coord, title: "Stop " + self.stopName, subtitle: "")
            let annotation = StopPointAnnotation(coordinate: coord, title: "Stop at" + self.stopName, subtitle: "", img: "location-pin.png")
            
            //self.mapView.removeAnnotations(self.mapView.annotations)
            self.mapView.addAnnotation(annotation)
            print("after add stop annotation")
            self.centerMapOnLocation(CLLocation(latitude: self.stopLat, longitude: self.stopLong)) //consider centering on stop instead
        })
        
        
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
                        if let allEntities = jsonResult!["entity"] as? NSArray {
                            if(allEntities.count > 0) {
                                print(allEntities)
                                // Populate busDict
                                for bus in allEntities{
                                    
                                    var temp = [String:AnyObject]()
                                    
                                    temp["array_index"] = bus["id"]
                                    temp["alert"]       = bus["alert"]
                                    temp["is_deleted"]  = bus["is_deleted"]
                                    
                                    let vehicleSub:NSDictionary = bus["vehicle"] as! NSDictionary
                                    temp["congestion_level"]      = vehicleSub["congestion_level"]
                                    temp["current_status"]        = vehicleSub["current_status"]
                                    temp["current_stop_sequence"] = vehicleSub["current_stop_sequence"]
                                    
                                    let positionSub:NSDictionary = vehicleSub["position"] as! NSDictionary
                                    temp["bearing"]   = positionSub["bearing"]
                                    temp["latitude"]  = positionSub["latitude"]
                                    temp["longitude"] = positionSub["longitude"]
                                    temp["odometer"]  = positionSub["odometer"]
                                    temp["speed"]     = positionSub["speed"]
                                    
                                    temp["stop_id"]   = vehicleSub["stop_id"]
                                    temp["timestamp"] = vehicleSub["timestamp"]
                                    
                                    let tripSub:NSDictionary = vehicleSub["trip"] as! NSDictionary
                                    let route:String = tripSub["route_id"] as! String
                                    
                                    temp["route_id"]                    = tripSub["route_id"]
                                    temp["trip_schedule_relationship"]  = tripSub["schedule_relationship"]
                                    temp["trip_start_date"]             = tripSub["start_date"]
                                    temp["trip_start_time"]             = tripSub["start_time"]
                                    temp["trip_id"]                     = tripSub["speed"]
                                    
                                    let subVehicleSub:NSDictionary = vehicleSub["vehicle"] as! NSDictionary
                                    temp["vehicle_id"]     = subVehicleSub["id"]
                                    temp["vehicle_label"]  = subVehicleSub["label"]
                                    temp["license_plate"]  = subVehicleSub["license_plate"]
                                    
//                                    if let existingEntry = self.busDict[route]{
//                                        self.busDict[route]!.append(temp)
//                                    } else {
//                                        self.busDict[route] = [AnyObject]()
//                                    }
                                    self.busDict[route] = temp
                                }
                                
//                                let entity0:NSDictionary = allEntities[0] as! NSDictionary;
//                                let vehicle0:NSDictionary = entity0["vehicle"] as! NSDictionary
//                                let positionSub:NSDictionary = vehicle0["position"] as! NSDictionary
//                                let tripSub:NSDictionary = vehicle0["trip"] as! NSDictionary
                                //print(self.busDict["642"]!.count)
                                //let bus:NSDictionary = self.busDict["642"]![0] as! NSDictionary
                                let bus:NSDictionary = self.busDict["642"] as! NSDictionary
                                let route:String = bus["route_id"] as! String
                                let newLatitude:Double = bus["latitude"] as! Double
                                let newLongitude:Double = bus["longitude"] as! Double
                                
                                if(newLatitude != self.latitude || newLongitude != self.longitude) {
                                    //values have changed since last pull, update global versions and restart stopwatch
                                    //self.startTime = NSTimeInterval() //update stopwatch
                                    self.latitude = newLatitude
                                    self.longitude = newLongitude
                                    print("Update!")
                                    self.updateStopwatch()
                                    self.startTime = NSDate.timeIntervalSinceReferenceDate()
                                }

                                
                                // Have thread updating UI in foreground
                                dispatch_async(dispatch_get_main_queue(), {
                                    
                                    // Create annotation from lattitude and longitude
                                    let coord: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude)
                                    let annotation = BusAnnotation(coordinate: coord, title: "Route" + route, subtitle: "")
                                    self.mapView.removeAnnotations(self.mapView.annotations)
                                    self.mapView.addAnnotation(annotation)
                                    //self.centerMapOnLocation(CLLocation(latitude: newLatitude, longitude: newLongitude)) //consider centering on stop instead
                                    
                                })

                                print("Route ID: " + route)
                                print("Lat: " + String(newLatitude))
                                print("Long:" + String(newLongitude))
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
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView! {
        print("yo")
        // Remove all annotations from the map view
        var view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "mcniff")
        view.canShowCallout = true
        view.pinTintColor = MKPinAnnotationView.greenPinColor()
        //let ann = annotation as! StopPointAnnotation
        //view.image = UIImage(named:ann.img)
        
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

