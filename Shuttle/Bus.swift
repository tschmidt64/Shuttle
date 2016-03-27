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
    
    init(longitude lon: Double, latitude lat: Double, orientation: Double, updateTime: Double) {
        location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        self.orientation = orientation
        lastUpdateTime = NSDate(timeIntervalSince1970: updateTime)
    }
    
}