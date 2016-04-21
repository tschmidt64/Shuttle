//
//  SplitTableView.swift
//  Clutch
//
//  Created by Taylor Schmidt on 4/21/16.
//  Copyright © 2016 Taylor Schmidt. All rights reserved.
//
import UIKit

class SplitTableView: UITableView {
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, withEvent: event)
        if point.y < 0 { return nil }
        return hitView
    }
}
