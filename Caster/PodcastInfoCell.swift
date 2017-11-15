//
//  PodcastInfoCell.swift
//  Caster
//
//  Created by Alex Truong on 5/1/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

protocol PodcastInfoDelegate: class {
    func podcastInfo(didTouchMoreInCell sender: UIButton)
}

class PodcastInfoCell: UITableViewCell {
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    
    var delegate: PodcastInfoDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.selectionStyle = .none
        self.infoLabel.numberOfLines = 5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func moreTouchUp(_ sender: UIButton) {
        delegate?.podcastInfo(didTouchMoreInCell: self.moreButton)
    }
}
