//
//  LightNavigationAnimatorForPush.swift
//  Caster
//
//  Created by Alex Truong on 6/4/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class LightNavigationAnimatorForPush: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let to = transitionContext.viewController(forKey: .to)!
        
        transitionContext.containerView.addSubview(to.view)
        
        // calculate start frame and end frame
        let endFrame = transitionContext.finalFrame(for: to)
        var startFrame = endFrame
        
        // slide in from the right
        startFrame.origin.x = transitionContext.containerView.frame.size.width

        // animation here
        to.view.frame = startFrame
        let duration = transitionDuration(using: transitionContext)

        UIView.animate(withDuration: duration, animations: {
            to.view.frame = endFrame
        }) { finished in
            // end of animation
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            
        }
    }
}
