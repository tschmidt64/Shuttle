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
    var img: String

    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, img: String)
    {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.img = img
    }
    
    func pinColor() -> UIColor
    {
        return UIColor.green
    }
}
