//
//  NowPlayingArtworkViewController.swift
//  Caster
//
//  Created by Alex Truong on 5/1/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class NowPlayingArtworkViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artworkImageView: UIImageView!
    
    var artwork: UIImage?
    var episodeTitle: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        artworkImageView.image = artwork
        
        //
        titleLabel.text = episodeTitle ?? "Unknown Title"
        titleLabel.numberOfLines = 2
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
