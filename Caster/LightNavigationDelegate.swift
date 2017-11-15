//
//  LightNavigationDelegate.swift
//  Caster
//
//  Created by Alex Truong on 6/4/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class LightNavigationDelegate: NSObject, UINavigationControllerDelegate {
    let pushAnimator = LightNavigationAnimatorForPush()
    let popAnimator = LightNavigationAnimatorForPop()
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    
        switch (operation) {
        case .push:
            return pushAnimator

        case .pop:
            return popAnimator
            
        default:
            return nil
        }
    }
}
