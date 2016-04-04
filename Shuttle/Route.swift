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
    var stops: [Stop] = []
    var busesOnRoute: [Bus] = []
    var nameLong: String
    var nameShort: String

    init(routeNum rNum: Int, nameShort: String, nameLong: String) {
        self.routeNum = rNum
        self.nameLong = nameLong
        self.nameShort = nameShort
        self.refreshAll()
    }
    
    func refreshAll() {
        self.refreshBuses()
        self.generateRouteCoords()
        self.generateStopCoords()
    }
    
    /*
     This refreshes the array self.busesOnRoute with the most recent data available
     */
    func refreshBuses() {
        print("REFRESH BUSES ROUTE: \(self.routeNum)")
        print("")
        let newUrlString = "http://52.88.82.199:8080/onebusaway-api-webapp/api/where/trips-for-route/1_\(routeNum).json?key=TEST&includeSchedules=true&includeStatus=true&_=50000"
        
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
//                    print("newUrlString: \(newUrlString)")
//                    print("JSON: \(subJson)")
                    let busLoc = subJson["status", "lastKnownLocation"].dictionaryValue

                    var lon: Double = 0.0
                    var lat: Double = 0.0
                    if let temp = busLoc["lat"] {
                         lon = busLoc["lon"]!.double!
                         lat = temp.double!
                    }
//                    let lat = busLoc["lat"]!.double!
//                    let lon = busLoc["lon"]!.double!
                    //print("Bus location \(lat), \(lon)")
                    let busId = subJson["status", "vehicleId"].string!
                    let busOrient = subJson["status", "orientation"].double!
                    let busUpdateSecs = subJson["status", "lastUpdateTime"].double!
                    let nextStopId = subJson["status", "nextStop"].string!
                    
                    buses.append(Bus(longitude: lon, latitude: lat, orientation: busOrient, updateTime: busUpdateSecs, nextStopId: nextStopId, busId: busId))
                }
                self.busesOnRoute = buses // Update the object's bus array
            }
        }
//        print("in refresh buses")
//        print(busesOnRoute)
        
        newTask.resume()
    }
    
    /*
     This refreshes the array self.routeCoords with the most recent data available
     */
    func generateRouteCoords() {
        // This is where Micah's code to fetch routes goes
    }
    
    /*
     This refreshes the array self.stopCoords with the most recent data available
     */
    func generateStopCoords() {
        // This is where Julio's code to fetch stops goes
    }
    
    func busDistancesFromStop(stopId startStopId: String) -> [String:Double] {
        var distances: [String:Double] = [:]
        for bus in self.busesOnRoute {
            var currentIndex = 0
            var currentStop: String = self.stops[currentIndex].stopId
            // get to the current bus stop first
            while(currentStop != startStopId) {
                currentIndex += 1
                currentStop = self.stops[currentIndex].stopId
            }
            // travel along stops summing the distances
            var distance = 0.0
            var prevIndex = (currentIndex == 0) ? self.stops.count-1 : currentIndex-1
            let goalStopId = bus.nextStopId
            while(currentStop != goalStopId) { // stop once we've reached the bus's next stop
                // Create CLLocation objs for use by distanceFromLocation
                let curStopCoord = self.stops[currentIndex].location
                let prevStopCoord = self.stops[prevIndex].location
                let curStopLoc = CLLocation(latitude: curStopCoord.latitude, longitude: curStopCoord.longitude)
                let prevStopLoc = CLLocation(latitude: prevStopCoord.latitude, longitude: prevStopCoord.longitude)
                // Calculate distance and add to total
                distance += curStopLoc.distanceFromLocation(prevStopLoc)
                // Get new indices and stops
                currentIndex = (currentIndex == 0) ? self.stops.count-1 : currentIndex-1
                prevIndex = (prevIndex == 0) ? self.stops.count-1 : prevIndex-1
                currentStop = self.stops[currentIndex].stopId
            }
            // Calculate distance from the last stop we looked at to the bus itself
            let curStopCoord = self.stops[currentIndex].location
            let curStopLoc = CLLocation(latitude: curStopCoord.latitude, longitude: curStopCoord.longitude)
            let busLoc = CLLocation(latitude: bus.location.latitude, longitude: bus.location.longitude)
            distance += curStopLoc.distanceFromLocation(busLoc)
            // Append to the return value
            distances[bus.busId] = distance
        }
        return distances
    }
}