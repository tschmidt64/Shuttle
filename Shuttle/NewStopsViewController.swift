//
//  ViewController.swift
//  Shuttle
//
//  Created by Taylor Schmidt on 2/16/16.
//  Copyright © 2016 Taylor Schmidt. All rights reserved.
//

import UIKit
import MapKit
import SwiftyJSON
import CoreLocation

class NewStopsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var tableViewScrolling: SplitTableView!
    @IBOutlet weak var mapViewBackground: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableViewScrolling.delegate = self
        self.tableViewScrolling.dataSource = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableViewScrolling.contentInset = UIEdgeInsetsMake(self.mapViewBackground.frame.size.height, 0, 0, 0)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.y < -(self.mapViewBackground.frame.size.height) {
            scrollView.setContentOffset(CGPointMake(scrollView.contentOffset.x, -(self.mapViewBackground.frame.size.height)) , animated: false)
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableViewScrolling.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        cell.textLabel?.text = "Cell number \(indexPath.row)"
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
}

/*
 

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.contentInset = UIEdgeInsetsMake(self.mapView.frame.size.height-40, 0, 0, 0);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if (scrollView.contentOffset.y < self.mapView.frame.size.height*-1 ) {
        [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, self.mapView.frame.size.height*-1)];
    }
}
 
 
 -(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
 {
 return 100;
 }
 
 -(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
 {
 UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
 
 cell.textLabel.text = [NSString stringWithFormat:@"%ld",(long)indexPath.row];
 
 return cell;
 
 }

 */