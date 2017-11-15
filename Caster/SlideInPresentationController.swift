//
//  SlideInPresentationController.swift
//  Caster
//
//  Created by Alex Truong on 4/13/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class SlideInPresentationController: UIPresentationController {
    
    let direction: SlideInDirection
    
    var showShadow = false
    var shadow: UIView!
    var savedAlpha: CGFloat = 0
    var savedColor: UIColor? = UIColor.clear
    
    init(direction: SlideInDirection, presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        
        self.direction = direction
        
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        
        if let _ = presentedView as? UITableView {
            showShadow = true
            setupShadow()
        }
    }
    
    func setupShadow() {
        shadow = UIView()
        shadow.translatesAutoresizingMaskIntoConstraints = false
        shadow.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        shadow.alpha = 0.0
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(shadowTapped(_:)))
        shadow.addGestureRecognizer(gesture)
    }
    
    func shadowTapped(_ gesture: UITapGestureRecognizer) {
        presentingViewController.dismiss(animated: true)
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let childSize = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerView!.bounds.size)
        
        var childFrame = CGRect(x: 0, y: 0, width: childSize.width, height: childSize.height)
        
        switch (direction) {
            
        case .right:
            childFrame.origin.x = containerView!.bounds.size.width - childSize.width

        case .bottom:
            childFrame.origin.y = containerView!.bounds.size.height - childSize.height
        
        default:
            break
        }

        return childFrame
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        
        switch (direction) {
            
        case .left, .right:
            return CGSize(width: parentSize.width * 0.8, height: parentSize.height)
        
        case .top, .bottom:
            var height = parentSize.height
            if let tableView = presentedView as? UITableView {
                tableView.layoutIfNeeded()
                if height > tableView.contentSize.height {
                    height = tableView.contentSize.height
                }
            } else {
                height = parentSize.height
            }
            return CGSize(width: parentSize.width, height: height)
        }
    }
    
    override func presentationTransitionWillBegin() {
        if let coordinator = presentedViewController.transitionCoordinator {
            if showShadow {
                containerView?.insertSubview(shadow, at: 0)
                
                NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|[shadow]|", options: [], metrics: nil, views: ["shadow": shadow]))
                NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|[shadow]|", options: [], metrics: nil, views: ["shadow": shadow]))

                coordinator.animate(alongsideTransition: { _ in
                    self.shadow.alpha = 1.0
                })
            }
            
            if direction == .bottom || direction == .top {
                UIApplication.shared.disableStatusBarChange()
                savedColor = statusBar.backgroundColor

                if direction == .top {
                    coordinator.animateAlongsideTransition(in: statusBar, animation: { _ in
                        statusBar.backgroundColor = UIColor.clear
                    })
                }
            }
        }
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        if !completed {
            if showShadow {
                shadow.removeFromSuperview()
            }
            
            if direction == .bottom || direction == .top {
                statusBar.backgroundColor = self.savedColor
            }
        } else if direction == .bottom {
            UIView.animate(withDuration: 0.3) {
                statusBar.backgroundColor = UIColor.clear
            }
        }
    }
    
    override func dismissalTransitionWillBegin() {
        if let coordinator = presentedViewController.transitionCoordinator {
            if showShadow {
                coordinator.animate(alongsideTransition: { _ in
                    self.shadow.alpha = 0
                })
                
            }
            
            if direction == .bottom || direction == .top {
                if direction == .top {
                    coordinator.animateAlongsideTransition(in: statusBar, animation: { _ in
                        statusBar.backgroundColor = self.savedColor
                    })
                } else {
                    statusBar.backgroundColor = self.savedColor
                }
            }
        }
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            if showShadow {
                self.shadow.removeFromSuperview()
            }
        } else if direction == .bottom || direction == .top {
            statusBar.backgroundColor = UIColor.clear
        }
        
        if direction == .bottom || direction == .top {
            UIApplication.shared.enableStatusBarChange()
        }
    }
}
