//
//  Route.swift
//  Shuttle
//
//  Created by Taylor Schmidt on 3/27/16.
//  Copyright © 2016 Taylor Schmidt. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftyJSON

class Route {
    var routeNum: Int
    var routeCoords: [CLLocationCoordinate2D] = []
    var stopCoords: [CLLocationCoordinate2D] = []
    var busesOnRoute: [Bus] = []
    var nameLong: String
    var nameShort: String
    var stops: [Stop]

    init(routeNum rNum: Int, nameShort: String, nameLong: String) {
        self.routeNum = rNum
        self.nameLong = nameLong
        self.nameShort = nameShort
        self.stops = []
        self.refreshAll()
    }
    
    func refreshAll() {
        self.refreshBuses()
        self.refreshRouteCoords()
        self.refreshStopCoords()
    }
    
    /*
     This refreshes the array self.busesOnRoute with the most recent data available
     */
    func refreshBuses() {
        let newUrlString = "http://52.88.82.199:8080/onebusaway-api-webapp/api/where/trips-for-route/1_\(self.routeNum).json?key=TEST&includeSchedules=true&includeStatus=true&_=50000"
        let newURL = NSURL(string: newUrlString)
        var buses: [Bus] = []
        
        let newSession = NSURLSession.sharedSession()
        let newTask = newSession.dataTaskWithURL(newURL!) { (data, response, error) -> Void in
            if error != nil {
                print("ERROR FOUND")
            } else {
                let json = JSON(data: data!)
                let newData = json["data", "list"]
                // Get the pieces data from the JSON
                for (_, subJson):(String, JSON) in newData {
                    let busLoc = subJson["status", "lastKnownLocation"].dictionaryValue
                    let lat = busLoc["lat"]!.double!
                    let lon = busLoc["lon"]!.double!
                    let busOrient = subJson["status", "orientation"].double!
                    let busUpdateSecs = subJson["status", "lastUpdateTime"].double!
                    
                    buses.append(Bus(longitude: lon, latitude: lat, orientation: busOrient, updateTime: busUpdateSecs))
                }
            }
        }
        self.busesOnRoute = buses // Update the object's bus array
        newTask.resume()
    }
    
    /*
     This refreshes the array self.routeCoords with the most recent data available
     */
    func refreshRouteCoords() {
        // This is where Micah's code to fetch routes goes
    }
    
    /*
     This refreshes the array self.stopCoords with the most recent data available
     */
    func refreshStopCoords() {
        // This is where Julio's code to fetch stops goes
    }
    
}