//
//  ViewController.swift
//  Shuttle
//
//  Created by Taylor Schmidt on 2/16/16.
//  Copyright © 2016 Taylor Schmidt. All rights reserved.
//

import UIKit
import MapKit


class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        getData()
        var timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "getData", userInfo: nil, repeats: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getData() {
        let urlPath = "https://data.texas.gov/download/cuc7-ywmd/text/plain"
        let url:NSURL? = NSURL(string: urlPath)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithURL(url!) { (data, response, error) -> Void in
            if error != nil {
            } else {
                do {
                    let jsonResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary
                    if jsonResult != nil {
                        if let allArray = jsonResult!["entity"] as? NSArray {
                            if(allArray.count > 0) {
                                let randomBus:NSDictionary = allArray[1] as! NSDictionary;
                                let randomBus2:NSDictionary = randomBus["vehicle"] as! NSDictionary
                                let positionSub:NSDictionary = randomBus2["position"] as! NSDictionary
                                let tripSub:NSDictionary = randomBus2["trip"] as! NSDictionary
                                let route:String = tripSub["route_id"] as! String
                                let lat:Double = positionSub["latitude"] as! Double
                                let long:Double = positionSub ["longitude"] as! Double
                                print(route)
                                print(lat)
                                print(long)
                            } else {
                                print("ahhhh")
                            }
                        }
                    }
                } catch {
                    
                }
            }
        }
        task.resume() // start the request */
    }
    
    
    
}

