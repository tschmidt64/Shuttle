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
    
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
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
                                
                                // Create annotation from lattitude and longitude
                                let coord: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: lat, longitude: long)
                                let annotation = MapPin(coordinate: coord, title: "Route" + route, subtitle: "")
                                self.mapView.addAnnotation(annotation)
                                self.centerMapOnLocation(CLLocation(latitude: lat, longitude: long))
                                
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

