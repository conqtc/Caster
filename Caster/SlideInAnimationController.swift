//
//  SlideInAnimationController.swift
//  Caster
//
//  Created by Alex Truong on 4/13/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class SlideInAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    let stretchScale: CGFloat = 1.02
    let shrinkScale: CGFloat = 0.995
    
    let direction: SlideInDirection
    let animation: SlideInAnimation
    
    init(direction: SlideInDirection = .left, animation: SlideInAnimation = .animationDefault) {
        self.direction = direction
        self.animation = animation

        super.init()
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView

        // add "to" view to the container
        let to = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        container.addSubview(to.view)
        
        // calculate start frame and end frame
        let endFrame = transitionContext.finalFrame(for: to)
        var startFrame = endFrame
        
        switch (direction) {
        case .left:
            startFrame.origin.x = -endFrame.width
        case .right:
            startFrame.origin.x = container.frame.size.width
        case .top:
            startFrame.origin.y = -endFrame.height
        case .bottom:
            startFrame.origin.y = container.frame.size.height
        }
        
        // scale factors
        var scaleX: CGFloat = 1.0
        var scaleY: CGFloat = 1.0
        var shrinkScaleX: CGFloat = 1.0
        var shrinkScaleY: CGFloat = 1.0

        if animation == .animationStretchThenShrink {
            switch (direction) {
            case .left:
                (scaleX, shrinkScaleX) = (stretchScale, shrinkScale)
                to.view.layer.anchorPoint.x = 0.0
            case .right:
                (scaleX, shrinkScaleX) = (stretchScale, shrinkScale)
                to.view.layer.anchorPoint.x = 1.0
            case .top:
                (scaleY, shrinkScaleY) = (stretchScale, shrinkScale)
                to.view.layer.anchorPoint.y = 0.0
            case .bottom:
                (scaleY, shrinkScaleY) = (stretchScale, shrinkScale)
                to.view.layer.anchorPoint.y = 1.0
            }
        }
        
        // start animation
        to.view.frame = startFrame
        let duration = transitionDuration(using: transitionContext)
        
        // put now playing bar to "to" view
        // TODO: implement universal solution
        if self.direction == .bottom {
            nowPlayingBar.removeFromSuperview()
            to.view.addSubview(nowPlayingBar)
            nowPlayingBar.frame = CGRect(x: 0, y: -kNowPlayingBarHeight, width: endFrame.size.width, height: kNowPlayingBarHeight)
        }

        if transitionContext.isInteractive {
            UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: {
                to.view.frame = endFrame
            }) { didComplete in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                
                // put now playing bar back to keywindow
                if transitionContext.transitionWasCancelled, self.direction == .bottom {
                    nowPlayingBar.removeFromSuperview()
                    if let window = UIApplication.shared.keyWindow {
                        window.addSubview(nowPlayingBar)
                    }
                    nowPlayingBar.frame = CGRect(x: 0, y: startFrame.origin.y - kNowPlayingBarHeight, width: startFrame.size.width, height: kNowPlayingBarHeight)
                }
            }
            
            return
        }
        
        switch (animation) {
        case .animationDefault:
            UIView.animate(withDuration: duration, animations: {
                to.view.frame = endFrame
            }) { didComplete in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }

        case .animationSpringWithDamping:
            to.view.alpha = 0
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                to.view.frame = endFrame
                to.view.alpha = 1.0
            }) { didComplete in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        
        case .animationStretchThenShrink:
            let stretchTime: Double = 1/2
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, options: .calculationModeLinear, animations: {
                
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: stretchTime, animations: {
                    to.view.frame = endFrame
                    to.view.transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
                })

                UIView.addKeyframe(withRelativeStartTime: stretchTime, relativeDuration: (1 - stretchTime), animations: {
                    to.view.transform = CGAffineTransform(scaleX: shrinkScaleX, y: shrinkScaleY)
                })
            }) { didComplete in
                to.view.transform = CGAffineTransform.identity
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        switch (animation) {
        case .animationDefault:
            return 0.3
        case .animationStretchThenShrink:
            return 0.3
        case .animationSpringWithDamping:
            return 0.3
        }
    }

}
