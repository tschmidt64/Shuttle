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
    var userLocButton: MKUserTrackingBarButtonItem!
    var showListButton: UIBarButtonItem!
    var locationManager = CLLocationManager()
    var tableHidden = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupLocationManager()
        setupMap()
        setupToolbar()
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
        locationManager = CLLocationManager()
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
            self.mapTableStack.arrangedSubviews.last?.hidden = self.tableHidden
//            self.view.layoutIfNeeded()
        }
        print("Button Pressed")
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("StackCell", forIndexPath: indexPath)
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    
    
}

private extension Selector {
    static let buttonTapped = #selector(StackViewController.showListTapped(_:))
}
    