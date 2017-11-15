//
//  PodcastCell.swift
//  Caster
//
//  Created by Alex Truong on 4/18/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class PodcastCell: UICollectionViewCell {
    @IBOutlet weak var artworkView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!

    var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }
    
    var author: String = "" {
        didSet {
            authorLabel.text = author
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        titleLabel.numberOfLines = 2
        artworkView.layer.borderColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0).cgColor
    }

}
