//
//  HeaderMapView.swift
//  Clutch
//
//  Created by Taylor Schmidt on 4/23/16.
//  Copyright © 2016 Taylor Schmidt. All rights reserved.
//

import UIKit
import MapKit

class HeaderMapView: UIView {
    
    var heightLayoutConstraint = NSLayoutConstraint()
    var bottomLayoutConstraint = NSLayoutConstraint()
    
    var containerView = UIView()
    var containerLayoutConstraint = NSLayoutConstraint()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.whiteColor()
        self.addMapConstraints()
    }
    
    /*
     The container view is needed to extend the visible area for the image view
     to include that below the navigation bar. If this container view isn't present
     the image view would be clipped at the navigation bar's bottom and the parallax
     effect would not work correctly
     */
    func addMapConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor.redColor()
        self.addSubview(containerView)
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[containerView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["containerView" : containerView]))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[containerView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["containerView" : containerView]))
        containerLayoutConstraint = NSLayoutConstraint(item: containerView, attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: 1.0, constant: 0.0)
        self.addConstraint(containerLayoutConstraint)
        
        let mapView: MKMapView = MKMapView.init()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.backgroundColor = UIColor.whiteColor()
        mapView.clipsToBounds = true
        mapView.contentMode = .ScaleAspectFill
        containerView.addSubview(mapView)
        containerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[mapView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["mapView" : mapView]))
        bottomLayoutConstraint = NSLayoutConstraint(item: mapView, attribute: .Bottom, relatedBy: .Equal, toItem: containerView, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        containerView.addConstraint(bottomLayoutConstraint)
        heightLayoutConstraint = NSLayoutConstraint(item: mapView, attribute: .Height, relatedBy: .Equal, toItem: containerView, attribute: .Height, multiplier: 1.0, constant: 0.0)
        containerView.addConstraint(heightLayoutConstraint)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        containerLayoutConstraint.constant = scrollView.contentInset.top;
        let offsetY = -(scrollView.contentOffset.y + scrollView.contentInset.top);
        containerView.clipsToBounds = offsetY <= 0
        bottomLayoutConstraint.constant = offsetY >= 0 ? 0 : -offsetY / 2
        heightLayoutConstraint.constant = max(offsetY + scrollView.contentInset.top, scrollView.contentInset.top)
    }
}
