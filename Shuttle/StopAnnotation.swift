//
//  BusAnnotation.swift
//  MapKit Playground
//
//  Created by Micah Peoples on 2/14/16.
//  Copyright © 2016 Taylor Schmidt. All rights reserved.
//

import MapKit

class StopAnnotation : NSObject, MKAnnotation
{
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var color: UIColor!

    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String)
    {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
    
    func pinColor() -> UIColor
    {
        return UIColor.greenColor()
    }
}