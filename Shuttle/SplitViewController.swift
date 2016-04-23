//
//  SplitViewController.swift
//  Clutch
//
//  Created by Taylor Schmidt on 4/23/16.
//  Copyright © 2016 Taylor Schmidt. All rights reserved.
//

import UIKit
import MapKit

class SplitViewController: UITableViewController, CLLocationManagerDelegate, MKMapViewDelegate{
    var curRoute: Route?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableHeaderView = HeaderMapView.init(frame: CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 200));
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let headerView = self.tableView.tableHeaderView as! HeaderMapView
        headerView.scrollViewDidScroll(scrollView)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        cell.textLabel?.text = "Cell number \(indexPath.row)"
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
}
