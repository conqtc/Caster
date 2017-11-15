//
//  UI.swift
//  Caster
//
//  Created by Alex Truong on 5/9/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import Foundation
import UIKit

var allowStatusBarChange = true
var statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView

extension UIApplication {
    
    func enableStatusBarChange() {
        allowStatusBarChange = true
    }
    
    func disableStatusBarChange() {
        allowStatusBarChange = false
    }
    
    func getStatusBarHeight() -> CGFloat {
        return statusBar.frame.size.height
    }
    
    func getStatusBarBackgroundColor() -> UIColor? {
        return statusBar.backgroundColor
    }
    
    func setStatusBarBackgroundColor(color: UIColor?, forceChange: Bool = false) {
        if allowStatusBarChange || forceChange {
            statusBar.backgroundColor = color
        }
    }
}
