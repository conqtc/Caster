//
//  SleekPopoverBackgroundView.swift
//  Caster
//
//  Created by Alex Truong on 6/2/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class SleekPopoverBackgroundView: UIPopoverBackgroundView {
    /*
    override class var wantsDefaultContentAppearance: Bool {
        return true
    }
    */
    
    override var arrowDirection: UIPopoverArrowDirection {
        get { return UIPopoverArrowDirection.left }
        set { }
    }
    
    override var arrowOffset: CGFloat {
        get { return 0.0 }
        set {}
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        self.layer.shadowColor = UIColor(white: 0, alpha: 0.2).cgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override class func arrowHeight() -> CGFloat {
        return 0.0
    }
    
    override class func arrowBase() -> CGFloat {
        return 0.0
    }
  
    override class func contentViewInsets() -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    }
}
