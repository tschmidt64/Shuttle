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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //these three busses are just circulators, 640 and 640 run clockwise, 642 runs counter clockwise
        //I referenced capmetro pdf for this info
        //https://www.capmetro.org/uploadedFiles/Capmetroorg/Schedules_and_Maps/ut-shuttles.pdf
        if(curRoute.routeNum == 640 || curRoute.routeNum == 641 || curRoute.routeNum == 642 ) {
            StopsSegmentedControl.hidden = true
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
    
    
    
    func sortAndSetStops() {
        // Sort stops by distance from user
        self.curStops = self.curRoute.stops.sort() {
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
    
    //method used to switch what direction routes we present in the 
    @IBAction func StopsSegmentedControlChoose(sender: AnyObject) {
        if StopsSegmentedControl.selectedSegmentIndex == 0 {
            print("toward campus and \(curRoute.routeNum)")
            self.popRouteObj(curRoute.routeNum, direction: 1)
        } else {
            print("away from campus and \(curRoute.routeNum)")
            self.popRouteObj(curRoute.routeNum, direction: 0)
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
    
    func popRouteObj(route:Int, direction:Int) {
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
                    let tempStop:Stop = Stop(location: CLLocationCoordinate2D(latitude: lat, longitude: long), name: name, stopID: stopID)
                    self.curRoute.stops.append(tempStop)
                    //coords.append(CLLocationCoordinate2D(latitude: lat, longitude: long)
                    //print("jsonData:\(json)")
                }
            }
        }
    }
    

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
        
        //let stopId:String = curStops[index!].stopId
        vc.stop = self.curStops[index!]
        vc.route = self.curRoute
        
        //set back button for next screen
        let backItem = UIBarButtonItem()
        backItem.title = "Stops"
        navigationItem.backBarButtonItem = backItem
    }

    
    //this should be integrated with core data so not needed to repeat
    /* func generateStops() {
        tempStop["name"] = "300 21ST & SAN JACINTO"
        tempStop["lat"]  = 3116788.6417877
        tempStop["long"] = 10076357.069287
        stops["4136"] = tempStop
        
        tempStop["name"] = "400 23RD & SAN JACINTO"
        tempStop["lat"]  = 3117101.130664
        tempStop["long"] = 10077110.572374
        stops["3750"] = tempStop
        
        tempStop["name"] = "ROBERT DEDMAN & TRINITY"
        tempStop["lat"]  = 3118165.3047168
        tempStop["long"] = 10077858.024947
        stops["4143"] = tempStop
        
        tempStop["name"] = "701 DEAN KEETON & SAN JACINTO"
        tempStop["lat"]  = 3117688.2784399
        tempStop["long"] = 10078481.421666
        stops["2005"] = tempStop
        
        tempStop["name"] = "305 DEAN KEETON & SAN JACINTO"
        tempStop["lat"]  = 3116537.8693234
        tempStop["long"] = 10078500.28613
        stops["5438"] = tempStop
        
        tempStop["name"] = "201 DEAN KEETON & UNIVERSITY"
        tempStop["lat"]  = 3115235.3735688
        tempStop["long"] = 10078584.577628
        stops["3512"] = tempStop
        
        tempStop["name"] = "2231 GUADALUPE & WEST MALL UT"
        tempStop["lat"]  = 3114542.7552034
        tempStop["long"] = 10077186.693284
        stops["1042"] = tempStop
        
        tempStop["name"] = "21ST & WHITIS MID-BLOCK"
        tempStop["lat"]  = 3114708.615764
        tempStop["long"] = 10076501.782909
        stops["2780"] = tempStop
        
        tempStop["name"] = "21ST & SPEEDWAY"
        tempStop["lat"]  = 30.283479
        tempStop["long"] = -97.737158
        stops["5207"] = tempStop
        
    } */

}
