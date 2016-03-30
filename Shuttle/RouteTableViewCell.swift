//
//  FinalTableViewCell.swift
//  pikkl
//
//  Created by Julio Correa on 11/28/15.
//  Copyright © 2015 CS378. All rights reserved.
//

import UIKit

class RouteTableViewCell: UITableViewCell {
    
    @IBOutlet weak var lblNameShort: UILabel!
    @IBOutlet weak var lblNameLong: UILabel!
    @IBOutlet weak var lblRouteNum: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}