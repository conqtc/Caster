//
//  NowPlayingEpisodeViewController.swift
//  Caster
//
//  Created by Alex Truong on 5/1/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class NowPlayingEpisodeViewController: UIViewController {
    @IBOutlet weak var infoTextView: InternalLinkTextView!

    var attributedText: NSMutableAttributedString? {
        didSet {
            setAttributedText()
        }
    }

    func setAttributedText() {
        // possibly to be called from background
        DispatchQueue.main.async {
            if self.infoTextView != nil {
                self.infoTextView.attributedText = self.attributedText
                self.infoTextView.linkTextAttributes = [NSForegroundColorAttributeName: UIColor.yellow]
                // workaround for textview's bug on cutting off part from the bottom of the view
                self.infoTextView.isScrollEnabled = false
                self.infoTextView.isScrollEnabled = true
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setAttributedText()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        infoTextView.scrollViewDidScroll(infoTextView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
