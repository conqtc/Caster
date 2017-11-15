//
//  SlideInTransitioningDelegate.swift
//  Caster
//
//  Created by Alex Truong on 4/13/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

enum SlideInDirection {
    case left
    case right
    case top
    case bottom
}

enum SlideInAnimation {
    case animationDefault
    case animationSpringWithDamping
    case animationStretchThenShrink
}

class SlideInTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    var direction: SlideInDirection
    var animation: SlideInAnimation
    
    var interactiveTransition: UIPercentDrivenInteractiveTransition?
    
    init(direction: SlideInDirection = .left, animation: SlideInAnimation = .animationDefault) {
        self.direction = direction
        self.animation = animation
        super.init()
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return SlideInPresentationController(direction: self.direction, presentedViewController: presented, presenting: presenting)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideInAnimationController(direction: self.direction, animation: self.animation)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideOutAnimationController(direction: self.direction)
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveTransition
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveTransition
    }
}
