//
//  BusAnnotation.swift
//  MapKit Playground
//
//  Created by Micah Peoples on 2/14/16.
//  Copyright © 2016 Taylor Schmidt. All rights reserved.
//

import MapKit

class BusAnnotation : NSObject, MKAnnotation
{
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var img: String
    var orientation: Double

    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, img: String, orientation: Double)
    {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.img = img
        self.orientation = orientation
    }
    
    func pinColor() -> UIColor
    {
        return UIColor.redColor()
    }
}