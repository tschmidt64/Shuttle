//
//  Stop.swift
//  Shuttle
//
//  Created by Taylor Schmidt on 3/27/16.
//  Copyright © 2016 Taylor Schmidt. All rights reserved.
//

import Foundation
import CoreLocation

class Stop {
    var location: CLLocationCoordinate2D
    var name: String
    var stopId: String
    
    init(location loc: CLLocationCoordinate2D, name: String, stopID id: String) {
        self.location = loc
        self.name = name
        self.stopId = id
    }
}