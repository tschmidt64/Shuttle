//
//  RoutesTableViewController.swift
//  Shuttle
//
//  Created by Julio Correa on 3/2/16.
//  Copyright © 2016 Taylor Schmidt. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftyJSON

class RoutesTableViewController: UITableViewController {
    //will be dictionary of arrays which comprise of a bus's stop ID's for use in acccesing the bus's stops.
    var routes: [Route] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        initRoutes()
        self.routes.sortInPlace() { $0.routeNum < $1.routeNum } // sort the routes descending by route number
/*
 642 WC West Campus/UT
 653 RR Red River/UT
 656 IF Intramural Fields/UT
 661 FW Far West/UT
 663 LA Lake Austin/UT
 640 FA Forty Acres
 641 EC East Campus
 670 CP Crossing Place
 671 NR North Riverside
 672 LS Lakeshore
 680 NR/LS North Riverside/Lakeshore
 681 IF/FW Intramural/Far West
*/
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    // set up all the route objects with their information using the stuff in comment above
    func initRoutes() {
            routes.append(Route(routeNum: 642, nameShort: "WC",  nameLong: "West Campus/UT"))
            routes.append(Route(routeNum: 653, nameShort: "RR",  nameLong: "Red River/UT"))
            routes.append(Route(routeNum: 656, nameShort: "IF", nameLong: "Intramural Fields/UT"))
            routes.append(Route(routeNum: 661, nameShort: "FW",  nameLong: "Far West/UT"))
            routes.append(Route(routeNum: 663, nameShort: "LA",  nameLong: "Lake Austin/UT"))
            routes.append(Route(routeNum: 640, nameShort: "FA",  nameLong: "Forty Acres"))
            routes.append(Route(routeNum: 641, nameShort: "EC",  nameLong: "East Campus"))
            routes.append(Route(routeNum: 670, nameShort: "CP",  nameLong: "Crossing Place"))
            routes.append(Route(routeNum: 671, nameShort: "NR",  nameLong: "North Riverside"))
            routes.append(Route(routeNum: 672, nameShort: "LS",  nameLong: "Lakeshore"))
            routes.append(Route(routeNum: 680, nameShort: "NR/LS", nameLong: "North Riverside/Lakeshore"))
            routes.append(Route(routeNum: 681, nameShort: "IF/FW", nameLong: "Intramural/Far West"))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getCoordsForRoute(routeNum: String, direction: String) -> [CLLocationCoordinate2D] {
        print(routeNum)
        var coords = [CLLocationCoordinate2D]()
        
        if let path = NSBundle.mainBundle().pathForResource("routes/shapes_" + routeNum + "_" + direction, ofType: "json") {
            if let data = NSData(contentsOfFile: path) {
                let json = JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                //coords.append(CLLocationCoordinate2D(latitude: <#T##CLLocationDegrees#>, longitude: <#T##CLLocationDegrees#>)
                for (_, point) in json {
                    
                    let lat = Double(point["shape_pt_lat"].stringValue)!
                    let long  = Double(point["shape_pt_lon"].stringValue)!
                    coords.append(CLLocationCoordinate2D(latitude: lat, longitude: long))

                }

                //print(coords)
            }
        }
        return coords;
    }
    

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return routes.count
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! RouteTableViewCell
        let index = indexPath.row
        // Configure the cell...
        cell.lblNameShort.text = String(routes[index].nameShort)
        cell.lblNameLong.text = String(routes[index].nameLong)
        cell.lblRouteNum.text = String(routes[index].routeNum)
        //cell.lbl.text = String(routes[index].routeNum)
        return cell
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
        let indexPath:NSIndexPath? = self.tableView!.indexPathForSelectedRow
        let index = indexPath?.row

        //pass selected route into viewcontroller by sending the string for the route and the array for the route
        let stopsTableView:StopsTableViewController = segue.destinationViewController as! StopsTableViewController
        let selectedRoute:Route = routes[index!]
        print("selectedRoute \(selectedRoute.nameLong)")
        selectedRoute.routeCoords = getCoordsForRoute(String(selectedRoute.routeNum), direction: "0")
        stopsTableView.curRoute = selectedRoute

        //TO-DO this is hard coded, figure out directional stuff
        stopsTableView.popRouteObj(selectedRoute.routeNum, direction: 0)
        
        //setting back button
        let backItem = UIBarButtonItem()
        backItem.title = "Routes"
        navigationItem.backBarButtonItem = backItem
    }
    
}
