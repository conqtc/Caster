//
//  EpisodeCell.swift
//  Caster
//
//  Created by Alex Truong on 4/26/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class EpisodeCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        titleLabel.numberOfLines = 2
        subtitleLabel.numberOfLines = 3
        self.selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
