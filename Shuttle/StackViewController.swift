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
    
    var userLocButton: MKUserTrackingBarButtonItem!
    var showListButton: UIBarButtonItem!
    var tableHidden = false
    
    var curRoute: Route = Route(routeNum: 0, nameShort: "", nameLong: "")
    var curStops: [Stop] = []
    var locationManager = CLLocationManager()
    var userLocation: CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Get's coordinates for stops and buses
        generateCoordinates()
        setupTableView()
        setupLocationManager()
        setupMap()
        setupToolbar()
        sortAndSetStops()
    }
    override func viewWillAppear(animated: Bool) {
        if let selected = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRowAtIndexPath(selected, animated: true)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        updateMapView(tableView)
    }
    
    func sortAndSetStops() {
        // Sort stops by distance from user
        self.curStops = self.curRoute.stops.sort {
            if let uCoord = self.locationManager.location?.coordinate {
                let uLoc = CLLocation(latitude: uCoord.latitude, longitude: uCoord.longitude)
                let stop0 = CLLocation(latitude: $0.location.latitude, longitude: $0.location.longitude)
                let stop1 = CLLocation(latitude: $1.location.latitude, longitude: $1.location.longitude)
                return stop0.distanceFromLocation(uLoc) < stop1.distanceFromLocation(uLoc)
            }
            return false
        }
    }
    
    func generateCoordinates() {
        if(curRoute.routeNum == 640 || curRoute.routeNum == 642 ) {
            self.curRoute.generateStopCoords(0)
            self.curRoute.generateRouteCoords(0)
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
        showListButton = UIBarButtonItem(title: "Show List", style: .Plain, target: self, action: Selector.buttonTapped)
        navigationController?.toolbarHidden = false
        let flexL = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace , target: self, action: nil)
        let flexR = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace , target: self, action: nil)
        toolbarItems = [userLocButton, flexL, showListButton, flexR]
        
    }
    
    func showListTapped(sender: UIBarButtonItem) {
        self.tableHidden = !self.tableHidden
        
        UIView.animateWithDuration(0.2) {
            self.tableView.hidden = self.tableHidden
            self.toolbar.hidden = self.tableHidden
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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.curStops.count
    }
    
    
    
}

private extension Selector {
    static let buttonTapped = #selector(StackViewController.showListTapped(_:))
}
    