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
        self.generateRouteCoords(1)
        self.generateStopCoords(1)
    }
    
    /*
     This refreshes the array self.busesOnRoute with the most recent data available
     */
    func refreshBuses(callback: @escaping () -> ()) {
        let urlStr = "https://lnykjry6ze.execute-api.us-west-2.amazonaws.com/prod/gtfsrt-debug?url=https://data.texas.gov/download/eiei-9rpf/application/octet-stream"
        let url = URL(string: urlStr)
        let newSession = URLSession.shared
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let newTask = newSession.dataTask(with: url!, completionHandler: { (data, response, error) -> Void in
            if error != nil {
                print("ERROR FOUND")
            } else {
                let json = JSON(data: data!)
                let entityJson = json["entity"].arrayValue
//                print("ENTITY ARR LENGTH: ", entityJson.count)
                for entity in entityJson {
                    let vehicle = entity["vehicle"]
                    let routeNum = vehicle["trip", "route_id"].intValue
                    if routeNum == self.routeNum {
//                                            print("ENTITY:")
                        let busId = vehicle["vehicle", "id"].stringValue
//                                          print("BusId: ", busId)
                        let busOrient = vehicle["position", "bearing"].intValue
//                                            print("BusOrient: ", busOrient)
                        let lastUpdate = vehicle["timestamp"].intValue
//                                            print("lastUpdate: ", lastUpdate)
                        let nextStopId = vehicle["stop_id"].stringValue
//                                            print("nextStopId: ", nextStopId)
                        let busLoc = vehicle["position"]

                        
                        guard let lat = busLoc["latitude"].double, let lon = busLoc["longitude"].double else {
                            print("ERROR: NO BUS LOCATION.")
                            break
                        }
                        
//                                            print("lat: ", lat, ", Lon: ", lon)
                        let newBus = Bus(longitude: lon, latitude: lat, orientation: Double(busOrient), updateTime: Double(lastUpdate), nextStopId: nextStopId, busId: busId)
                        self.busesOnRoute[busId] = newBus
                    }
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    callback()
                }
            }
        })
        
        newTask.resume()
    }
    
    /*
    /* same function as refresh buses, uses capmetro data instead */
    /* https://github.com/tschmidt64/Shuttle/blob/c78794dbf0c3c9fd34c5ee7a99bfbbaa82e1adaf/Shuttle/ViewController.swift */
    /* should be similar to getData method */
     func refreshBusesCapMetro() {
        
        let urlPath = "https://data.texas.gov/download/cuc7-ywmd/text/plain"
        let url:URL? = URL(string: urlPath)
        let session = URLSession.shared
        let task = session.dataTask(with: url!, completionHandler: { (data, response, error) -> Void in
            if error != nil {
                print("error found")
            } else {
                do {
                    let jsonResult = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                    if jsonResult != nil {
                        if let allEntities = jsonResult!["entity"] as? NSArray {
                            if(allEntities.count > 0) {
                                // Populate busDict
                                for bus in allEntities {
                                    
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
        }) 
        
        task.resume() // start the request
    }
    */

    
    /*
     This refreshes the array self.routeCoords with the most recent data available
     This method needs to be updated to take in an integer that represents whether the route is inbound or outbound
     */
    func generateRouteCoords(_ direction: Int) {
        // This is where Micah's code to fetch routes goes
        var coords = [CLLocationCoordinate2D]()
        
        if let path = Bundle.main.path(forResource: "routes/shapes_\(self.routeNum)_\(direction)", ofType: "json") {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                let json = JSON(data: data, options: JSONSerialization.ReadingOptions.allowFragments, error: nil)
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
    func generateStopCoords(_ direction: Int) {
        let filePath:String = "stops/stops_\(self.routeNum)_\(direction)"
        if let path = Bundle.main.path(forResource: filePath, ofType: "json") {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                let json = JSON(data: data, options: JSONSerialization.ReadingOptions.allowFragments, error: nil)
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
    
    
    func busDistancesFromStop(_ stopId: Stop) -> [String:Double] {
        var distances: [String:Double] = [:]
        for (_, bus) in self.busesOnRoute {
            let busLoc = CLLocation(latitude: bus.location.latitude, longitude: bus.location.longitude)
            let stopLoc = CLLocation(latitude: stopId.location.latitude, longitude: stopId.location.longitude)
            let closestCoordToBus = self.routeCoords.min(by: { (first, second) -> Bool in
                let firstLoc = CLLocation(latitude: first.latitude, longitude: first.longitude)
                let secondLoc = CLLocation(latitude: second.latitude, longitude: second.longitude)
                return firstLoc.distance(from: busLoc) < secondLoc.distance(from: busLoc)
            })
            let closestCoordToStop = self.routeCoords.min(by: { (first, second) -> Bool in
                let firstLoc = CLLocation(latitude: first.latitude, longitude: first.longitude)
                let secondLoc = CLLocation(latitude: second.latitude, longitude: second.longitude)
                return firstLoc.distance(from: stopLoc) < secondLoc.distance(from: stopLoc)
            })
            
            // TODO: Excuse this disgusting if-let here, will fix later
            if  var iCur = self.routeCoords.index(where: { (coord) -> Bool in // use bus for curLoc
                return closestCoordToBus?.latitude == coord.latitude
                    && closestCoordToBus?.longitude == coord.longitude
            }), let iStop =  self.routeCoords.index(where: { (coord) -> Bool in // use stop for stopLoc
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
                    let curLen = nextLoc.distance(from: curLoc)
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
                distance += nextLoc.distance(from: curLoc)
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
