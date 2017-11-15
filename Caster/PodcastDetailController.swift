//
//  PodcastDetailController.swift
//  Caster
//
//  Created by Alex Truong on 5/18/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class PodcastDetailController: UIViewController {
    @IBOutlet weak var detailTextView: InternalLinkTextView!
    
    var attributedString: NSMutableAttributedString?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        detailTextView.attributedText = self.attributedString
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        detailTextView.setContentOffset(.zero, animated: true)
        detailTextView.scrollViewDidScroll(detailTextView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
