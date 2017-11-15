//
//  PodcastHeader.swift
//  Caster
//
//  Created by Alex Truong on 4/19/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

protocol PodcastHeaderDelegate: class {
    func podcastHeader(sender: UITableViewCell, didTouchShowAllWith gid: Int)
}

class PodcastHeaderCell: UITableViewCell {

    @IBOutlet weak var showAllButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    var gid: Int = 0
    var delegate: PodcastHeaderDelegate?
    
    var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.layoutMargins = UIEdgeInsets.zero
        
        showAllButton.backgroundColor = Theme.primaryColor
        showAllButton.setTitleColor(UIColor.lightText, for: .highlighted)
        showAllButton.contentEdgeInsets = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func showAllTouched(_ sender: UIButton) {
        delegate?.podcastHeader(sender: self, didTouchShowAllWith: self.gid)
    }
}
