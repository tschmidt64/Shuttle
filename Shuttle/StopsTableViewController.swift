//
//  StopsTableViewController.swift
//  Shuttle
//
//  Created by Julio Correa on 3/3/16.
//  Copyright © 2016 Taylor Schmidt. All rights reserved.
//

import UIKit
import SwiftyJSON

class StopsTableViewController: UITableViewController {
    //stops dictionary contains all of the stops key:value = stopID:stopDictionary
    //tempStop holds the specific information for a stop
    
    
    var curRoute = "" //this is where the route will be passed into that this view will show stops for
    var curRouteStops = [String]() //this is the array that all the stops for curRoute will be displayed and used to reference the stops dictionary to display the stop names, etc.
    var stops = [String:AnyObject]()
    var tempStop = [String:AnyObject]()

    override func viewDidLoad() {
        super.viewDidLoad()
        popRouteObj(640, direction: 1)
        generateStops()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return curRouteStops.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        let stopId:String = curRouteStops[indexPath.row]
        let stop = stops[stopId]
        cell.textLabel!.text = stop!["name"] as? String
        return cell
    }
    
    func popRouteObj(route:Int, direction:Int) {
        var file = "stops_" + String(route) + "_" + String(direction)
        if let path = NSBundle.mainBundle().pathForResource("stops/stops_640_0", ofType: "json") {
            if let data = NSData(contentsOfFile: path) {
                let json = JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                print("jsonData:\(json)")
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
        
        let stopId:String = curRouteStops[index!]
        let stop = stops[stopId] as! NSDictionary
        vc.stopLat =  stop["lat"] as! Double
        vc.stopLong = stop["long"] as! Double
        vc.stopName = stop["name"] as! String
        vc.routeNum = curRoute
    }

    
    //this should be integrated with core data so not needed to repeat
    func generateStops() {
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
        
    }

}
