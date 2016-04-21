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
    var busesOnRoute: [String:Bus] = [:]
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
        //self.refreshBusesCapMetro()
        self.generateRouteCoords(1)
        self.generateStopCoords(1)
    }
    
    
    /*
     This refreshes the array self.busesOnRoute with the most recent data available
     */
    func refreshBuses() {
//        print("REFRESH BUSES ROUTE: \(self.routeNum)")
//        print("")
        let newUrlString = "http://52.88.82.199:8080/onebusaway-api-webapp/api/where/trips-for-route/1_\(routeNum).json?key=TEST&includeSchedules=true&includeStatus=true&_=50000"
        
        let newURL = NSURL(string: newUrlString)
        
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
                    let busId = subJson["status", "vehicleId"].string!
                    let busOrient = subJson["status", "orientation"].double!
                    let busUpdateSecs = subJson["status", "lastUpdateTime"].double!
                    let nextStopId = subJson["status", "nextStop"].string!
                    let formattedNextStopId = nextStopId.substringFromIndex(nextStopId.startIndex.successor().successor())
                    var busLoc = subJson["status", "lastKnownLocation"].dictionaryValue
                    // sometimes lastKnownLocation is empty, use this instead
                    if busLoc.isEmpty { busLoc = subJson["status", "position"].dictionaryValue }
                    guard let lat = busLoc["lat"]?.double, lon = busLoc["lon"]?.double else {
                        print("ERROR: NO BUS LOCATION. (Route: \(self.routeNum), Bus id: \(busId))")
                        break // ignore this bus entry because no coordinates for it
                    }
//                    let lat = busLoc["lat"]!.double!
//                    let lon = busLoc["lon"]!.double!
                    //print("Bus location \(lat), \(lon)")
                    let newBus = Bus(longitude: lon, latitude: lat, orientation: busOrient, updateTime: busUpdateSecs, nextStopId: formattedNextStopId, busId: busId)
                    self.busesOnRoute[busId] = newBus
                }
            }
        }
//        print("in refresh buses")
//        print(busesOnRoute)
        
        newTask.resume()
    }
    
    
    /* same function as refresh buses, uses capmetro data instead */
    /* https://github.com/tschmidt64/Shuttle/blob/c78794dbf0c3c9fd34c5ee7a99bfbbaa82e1adaf/Shuttle/ViewController.swift */
    /* should be similar to getData method */
     func refreshBusesCapMetro() {
        
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
     
                                    temp["route_id"]                    = tripSub["route_id"]
                                    temp["trip_schedule_relationship"]  = tripSub["schedule_relationship"]
                                    temp["trip_start_date"]             = tripSub["start_date"]
                                    temp["trip_start_time"]             = tripSub["start_time"]
                                    temp["trip_id"]                     = tripSub["speed"]
     
                                    let subVehicleSub:NSDictionary = vehicleSub["vehicle"] as! NSDictionary
                                    temp["vehicle_id"]     = subVehicleSub["id"]
                                    temp["vehicle_label"]  = subVehicleSub["label"]
                                    temp["license_plate"]  = subVehicleSub["license_plate"]
     
                                    if (Int(temp["route_id"] as! String) == self.routeNum) {
                                        
                                        let lat         = temp["latitude"]   as! Double
                                        let long        = temp["longitude"]  as! Double
                                        let orientation = temp["bearing"]    as! Double
                                        let updateTime  = temp["timestamp"]  as! Double
                                        // either next stop or last stop, not actually sure
                                        let nextStopId  = temp["stop_id"]    as! String
                                        let busId       = temp["vehicle_id"] as! String
                                        
                                        let tempBus = Bus(longitude: long, latitude: lat, orientation: orientation, updateTime: updateTime, nextStopId: nextStopId, busId: busId)
                                        print(tempBus.toString())
                                        print()
                                        self.busesOnRoute[busId] = tempBus
                                        
                                    }
                                }
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
        
        task.resume() // start the request
    }

    
    /*
     This refreshes the array self.routeCoords with the most recent data available
     This method needs to be updated to take in an integer that represents whether the route is inbound or outbound
     */
    func generateRouteCoords(direction: Int) {
        // This is where Micah's code to fetch routes goes
        var coords = [CLLocationCoordinate2D]()
        
        if let path = NSBundle.mainBundle().pathForResource("routes/shapes_\(self.routeNum)_\(direction)", ofType: "json") {
            if let data = NSData(contentsOfFile: path) {
                let json = JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                for (_, point) in json {
                    
                    let lat = Double(point["shape_pt_lat"].stringValue)!
                    let long  = Double(point["shape_pt_lon"].stringValue)!
                    coords.append(CLLocationCoordinate2D(latitude: lat, longitude: long))
                    
                }
            }
        }
        self.routeCoords = coords;
    }
    
    /*
     This refreshes the array self.stopCoords with the most recent data available
     */
    func generateStopCoords(direction: Int) {
        let filePath:String = "stops/stops_\(self.routeNum)_\(direction)"
        if let path = NSBundle.mainBundle().pathForResource(filePath, ofType: "json") {
            if let data = NSData(contentsOfFile: path) {
                let json = JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                self.stops = []
                for (_, stop) in json {
                    let lat = Double(stop["stop_lat"].stringValue)!
                    let long  = Double(stop["stop_lon"].stringValue)!
                    let name = stop["stop_desc"].stringValue
                    let stopID = stop["stop_id"].stringValue
                    let stopSeq = stop["stop_sequence"].intValue
                    let tempStop:Stop = Stop(location: CLLocationCoordinate2D(latitude: lat, longitude: long), name: name, stopID: stopID, index: stopSeq)
                    self.stops.append(tempStop)
                }
            }
        }

    } 
    
    
    func busDistancesFromStop(stopId: Stop) -> [String:Double] {
        var distances: [String:Double] = [:]
        for (_, bus) in self.busesOnRoute {
            let busLoc = CLLocation(latitude: bus.location.latitude, longitude: bus.location.longitude)
            let stopLoc = CLLocation(latitude: stopId.location.latitude, longitude: stopId.location.longitude)
            let closestCoordToBus = self.routeCoords.minElement({ (first, second) -> Bool in
                let firstLoc = CLLocation(latitude: first.latitude, longitude: first.longitude)
                let secondLoc = CLLocation(latitude: second.latitude, longitude: second.longitude)
                return firstLoc.distanceFromLocation(busLoc) < secondLoc.distanceFromLocation(busLoc)
            })
            let closestCoordToStop = self.routeCoords.minElement({ (first, second) -> Bool in
                let firstLoc = CLLocation(latitude: first.latitude, longitude: first.longitude)
                let secondLoc = CLLocation(latitude: second.latitude, longitude: second.longitude)
                return firstLoc.distanceFromLocation(stopLoc) < secondLoc.distanceFromLocation(stopLoc)
            })
            
            // TODO: Excuse this disgusting if-let here, will fix later
            if  var iCur = self.routeCoords.indexOf({ (coord) -> Bool in // use bus for curLoc
                return closestCoordToBus?.latitude == coord.latitude
                    && closestCoordToBus?.longitude == coord.longitude
            }), let iStop =  self.routeCoords.indexOf({ (coord) -> Bool in // use stop for stopLoc
                return closestCoordToStop?.latitude == coord.latitude
                    && closestCoordToStop?.longitude == coord.longitude
            }) {
                var iNext = (iCur == self.routeCoords.count - 1) ? 0 : iCur + 1
                var distance = 0.0
                // current and next CLLocationCoordinate2D
                var curCoord = self.routeCoords[iCur]
                var nextCoord = self.routeCoords[iNext]
                // current and next CLlocation
                var curLoc = CLLocation(latitude: curCoord.latitude, longitude: curCoord.longitude)
                var nextLoc = CLLocation(latitude: nextCoord.latitude, longitude: nextCoord.longitude)
                
                while iCur != iStop{
                    let curLen = nextLoc.distanceFromLocation(curLoc)
                    distance += curLen
                    // Loop the indices
                    iCur = (iCur == self.routeCoords.count - 1) ? 0 : iCur + 1
                    iNext = (iNext == self.routeCoords.count - 1) ? 0 : iNext + 1
                    
//                    print("CURRENT: \(iCur)")
                    // update CLLocationCoordinate2Ds
                    curCoord = self.routeCoords[iCur]
                    nextCoord = self.routeCoords[iNext]
                    // Update CLLocations
                    curLoc = CLLocation(latitude: curCoord.latitude, longitude: curCoord.longitude)
                    nextLoc = CLLocation(latitude: nextCoord.latitude, longitude: nextCoord.longitude)
                }
                distance += nextLoc.distanceFromLocation(curLoc)
                distances[bus.busId] = distance
            }
            
        }
        return distances
    }
    

    /*
     This function is like the one above, except takes a startStopId as
     a string and it uses the stops for measuring distances instead of the actual routes themselves
 
     In other words, this one is worse in every way
     */
//    func busDistancesFromStop(stopId startStopId: String) -> [String:Double] {
//        var distances: [String:Double] = [:]
//        let stops = self.stops.sort { $0.index < $1.index }
//        for bus in self.busesOnRoute {
//            // get to the current bus stop first
//            if var currentIndex = (stops.map {$0.stopId }).indexOf(startStopId) {
//                var currentStop: String = stops[currentIndex].stopId
//                // travel along stops summing the distances
//                var distance = 0.0
//                var prevIndex = (currentIndex == 0) ? stops.count-1 : currentIndex-1
//                let goalStopId = bus.nextStopId
//                if (stops.map{$0.stopId}).contains({ (s) -> Bool in s == goalStopId }) {
//                    while(currentStop != goalStopId) { // stop once we've reached the bus's next stop
//                        print("CURRENT: \(currentStop) | GOAL \(goalStopId)")
//                        // Create CLLocation objs for use by distanceFromLocation
//                        let curStopCoord = stops[currentIndex].location
//                        let prevStopCoord = stops[prevIndex].location
//                        let curStopLoc = CLLocation(latitude: curStopCoord.latitude, longitude: curStopCoord.longitude)
//                        let prevStopLoc = CLLocation(latitude: prevStopCoord.latitude, longitude: prevStopCoord.longitude)
//                        // Calculate distance and add to total
//                        distance += curStopLoc.distanceFromLocation(prevStopLoc)
//                        // Get new indices and stops
//                        currentIndex = (currentIndex == 0) ? stops.count-1 : currentIndex-1
//                        prevIndex = (prevIndex == 0) ? stops.count-1 : prevIndex-1
//                        currentStop = stops[currentIndex].stopId
//                    }
//                    // Calculate distance from the last stop we looked at to the bus itself
//                    let curStopCoord = stops[currentIndex].location
//                    let curStopLoc = CLLocation(latitude: curStopCoord.latitude, longitude: curStopCoord.longitude)
//                    let busLoc = CLLocation(latitude: bus.location.latitude, longitude: bus.location.longitude)
//                    distance += curStopLoc.distanceFromLocation(busLoc)
//                    // Append to the return value
//                    distances[bus.busId] = distance
//                }
//                
//            }
//        }
//        return distances
//    }
}