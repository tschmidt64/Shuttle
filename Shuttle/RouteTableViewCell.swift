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
    @IBOutlet weak var lblNumBuses: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        lblNameShort.layer.cornerRadius = 5
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
