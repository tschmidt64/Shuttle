//
//  StopsTableViewController.swift
//  Shuttle
//
//  Created by Julio Correa on 3/3/16.
//  Copyright © 2016 Taylor Schmidt. All rights reserved.
//

import UIKit
import SwiftyJSON
import CoreLocation

class StopsTableViewController: UITableViewController, CLLocationManagerDelegate {

    var curRoute:Route = Route(routeNum: 0, nameShort: "", nameLong: "")
    var curStops:[Stop] = []
    var locationManager: CLLocationManager!
    var userLocation: CLLocationCoordinate2D!
    //var routePoints = [CLLocationCoordinate2D]()

    @IBOutlet weak var StopsSegmentedControl: UISegmentedControl!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var navBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //these three busses are just circulators, 640 and 640 run clockwise, 642 runs counter clockwise
        //I referenced capmetro pdf for this info
        //https://www.capmetro.org/uploadedFiles/Capmetroorg/Schedules_and_Maps/ut-shuttles.pdf
        if(curRoute.routeNum == 640 || curRoute.routeNum == 641 || curRoute.routeNum == 642 ) {
            self.curRoute.generateStopCoords(0)
            self.curRoute.generateRouteCoords(0)
            //do this because these routes only have on direction, so need to be set on 0
            StopsSegmentedControl.hidden = true
            self.navBar.removeFromSuperview()
            self.tableView.contentInset = UIEdgeInsets(top: -44.0, left: 0.0, bottom: 0.0, right: 0.0)
        } else {
            let item = UINavigationItem()
            item.titleView = self.StopsSegmentedControl
            self.navBar.barTintColor = UIColor.whiteColor()
            self.navBar.items = [item]
        }
        
        // Set up user location
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        sortAndSetStops()
        
        self.navigationItem.title = "Stops for Route \(curRoute.routeNum)"
        
        //popRouteObj(curRoute.routeNum, direction: 0)
        //generateStops()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        if let selected = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRowAtIndexPath(selected, animated: true)
        }
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //method used to switch what direction routes we present in the tableview
    @IBAction func StopsSegmentedControlChoose(sender: AnyObject) {
        if StopsSegmentedControl.selectedSegmentIndex == 0 {
            self.curRoute.generateStopCoords(1)
            self.curRoute.generateRouteCoords(1)
        } else {
            self.curRoute.generateStopCoords(0)
            self.curRoute.generateRouteCoords(0)
        }
        sortAndSetStops()
        self.tableView.reloadData();
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
    
    /* func popRouteObj(route:Int, direction:Int) {
        let filePath:String = "stops/stops_\(route)_\(direction)"
        if let path = NSBundle.mainBundle().pathForResource(filePath, ofType: "json") {
            if let data = NSData(contentsOfFile: path) {
                let json = JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                self.curRoute.stops = []
                for (_, stop) in json {
                    let lat = Double(stop["stop_lat"].stringValue)!
                    let long  = Double(stop["stop_lon"].stringValue)!
                    let name = stop["stop_desc"].stringValue
                    let stopID = stop["stop_id"].stringValue
                    let stopSeq = stop["stop_sequence"].intValue
                    let tempStop:Stop = Stop(location: CLLocationCoordinate2D(latitude: lat, longitude: long), name: name, stopID: stopID, index: stopSeq)
                    self.curRoute.stops.append(tempStop)
                    //coords.append(CLLocationCoordinate2D(latitude: lat, longitude: long)
                    //print("jsonData:\(json)")
                }
            }
        }
    } */
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let indexPath:NSIndexPath? = self.tableView!.indexPathForSelectedRow
        let index = indexPath?.row
        
        //pass selected route into viewcontroller by sending the string for the route and the array for the route
        let vc:ViewController = segue.destinationViewController as! ViewController
        
        vc.stop = self.curStops[index!]
        vc.route = self.curRoute
                
        //set back button for next screen
        let backItem = UIBarButtonItem()
        backItem.title = "Stops"
        navigationItem.backBarButtonItem = backItem
    }
}
