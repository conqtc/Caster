//
//  AnnouncementCell.swift
//  Caster
//
//  Created by Alex Truong on 4/18/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class AnnouncementCell: UITableViewCell {

    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var backdropView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        self.descLabel.numberOfLines = 5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
