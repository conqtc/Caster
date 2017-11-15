//
//  BannerCell.swift
//  Caster
//
//  Created by Alex Truong on 4/18/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class BannerCell: UITableViewCell {
    @IBOutlet weak var bannerImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
