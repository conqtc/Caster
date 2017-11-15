//
//  SlideOutAnimationController.swift
//  Caster
//
//  Created by Alex Truong on 4/13/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class SlideOutAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    let direction: SlideInDirection
    
    init(direction: SlideInDirection) {
        self.direction = direction
        
        super.init()
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let from = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        
        let container = transitionContext.containerView
        
        // calculate start frame and end frame
        let startFrame = transitionContext.finalFrame(for: from)
        var endFrame = startFrame
        switch (direction) {
        case .left:
            endFrame.origin.x = -startFrame.width
        case .right:
            endFrame.origin.x = container.frame.size.width
        case .top:
            endFrame.origin.y = -startFrame.height
        case .bottom:
            endFrame.origin.y = container.frame.size.height
        }
        
        // start animation
        let duration = transitionDuration(using: transitionContext)
        from.view.frame = startFrame
        
        var options: UIViewAnimationOptions = []
        if transitionContext.isInteractive {
            options = .curveLinear
        }
        
        from.view.alpha = 1.0
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            from.view.frame = endFrame
        }) { didComplete in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            
            // put now playing bar back to key window
            // TODO: implement universal solution
            if !transitionContext.transitionWasCancelled, self.direction == .bottom {
                nowPlayingBar.removeFromSuperview()
                if let window = UIApplication.shared.keyWindow {
                    window.addSubview(nowPlayingBar)
                }
                nowPlayingBar.frame = CGRect(x: 0, y: endFrame.size.height-kNowPlayingBarHeight, width: endFrame.size.width, height: kNowPlayingBarHeight)
            }
        }
    }
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
}
