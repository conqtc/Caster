//
//  LightNavigationAnimatorForPop.swift
//  Caster
//
//  Created by Alex Truong on 6/4/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class LightNavigationAnimatorForPop:NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let from = transitionContext.viewController(forKey: .from)!
        let to = transitionContext.viewController(forKey: .to)!
        
        transitionContext.containerView.addSubview(to.view)
        transitionContext.containerView.addSubview(from.view)
        
        // calculate start frame and end frame
        let startFrame = transitionContext.finalFrame(for: to)
        var endFrame = startFrame
        
        endFrame.origin.x = transitionContext.containerView.frame.size.width
        
        // animation here
        from.view.frame = startFrame
        to.view.frame = startFrame
        let duration = transitionDuration(using: transitionContext)
        
        UIView.animate(withDuration: duration, animations: {
            from.view.frame = endFrame
        }) { finished in
            // end of animation
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            
        }
    }
}
