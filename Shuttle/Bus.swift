//
//  Bus.swift
//  Shuttle
//
//  Created by Taylor Schmidt on 3/27/16.
//  Copyright © 2016 Taylor Schmidt. All rights reserved.
//

import Foundation
import CoreLocation

class Bus {
    var location: CLLocationCoordinate2D
    var orientation: Double
    var lastUpdateTime: NSDate
    var nextStopId: String
    var busId: String
    
    init(longitude lon: Double, latitude lat: Double, orientation: Double, updateTime: Double, nextStopId: String, busId: String) {
        self.location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        self.orientation = orientation
        self.nextStopId = nextStopId
        self.busId = busId
        self.lastUpdateTime = NSDate(timeIntervalSince1970: (updateTime/1000))
    }
    
    func toString() -> String {
        var s =  "Bus " + busId
            s += ", lat: " + String(location.latitude) + "long: " + String(location.longitude)
            s += ", orientation: " + String(orientation)
            s += ", next stop: " + String(nextStopId)
            s += ", last update time: " + String(lastUpdateTime)
        return s
    }
}