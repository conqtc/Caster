//
//  CustomSlider.swift
//  Caster
//
//  Created by Alex Truong on 5/5/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class CustomSlider: UISlider {
    var height: CGFloat = 2.0
    
    override func trackRect(forBounds: CGRect) -> CGRect {
        var tRect = super.trackRect(forBounds: bounds)
        
        tRect.origin.y -= self.height/2 - 0.5
        tRect.size.height = self.height
        
        return tRect
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.minimumTrackTintColor = Theme.primaryColor
        self.setThumbImage(UIImage(named: "Thumb"), for: .normal)
    }
}
