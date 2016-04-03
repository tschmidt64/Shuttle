//
//  StopPointAnnotation.swift
//  Shuttle
//
//  Created by Micah Peoples on 3/6/16.
//  Copyright © 2016 Taylor Schmidt. All rights reserved.
//

import MapKit

class StopPointAnnotation : MKPointAnnotation
{
    var img: String
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, img: String)
    {
        self.img = img;
        super.init()
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}