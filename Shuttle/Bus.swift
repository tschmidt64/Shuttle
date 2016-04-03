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
    var timeSinceUpdate: Double
    var nextStopId: String
    var busId: String
    init(longitude lon: Double, latitude lat: Double, orientation: Double, updateTime: Double, nextStopId: String, busId: String) {
        self.location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        self.orientation = orientation
        self.nextStopId = nextStopId
        self.busId = busId
        let temp = NSDate(timeIntervalSince1970:  ( (updateTime/1000) - (5*3600) )  )
        //used to convert time to seconds
        self.timeSinceUpdate = NSDate().timeIntervalSinceDate(temp) / 1000
        print("lastUpdateTime = \(self.timeSinceUpdate)")
    }
    
    func stringFromTimeInterval(interval: NSTimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        //let hours = interval / 3600
        return String(format: "%02d min %02d sec", minutes, seconds)
    }
    
}