//
//  PodcastGenreCell.swift
//  Caster
//
//  Created by Alex Truong on 4/18/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class PodcastGenreCell: UITableViewCell {
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var artworkImageView: UIImageView!
    
    var genreTitle: String = "" {
        didSet {
            genreLabel.text = self.genreTitle
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
