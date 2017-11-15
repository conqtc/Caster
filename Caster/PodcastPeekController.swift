//
//  PodcastPeekController.swift
//  Caster
//
//  Created by Alex Truong on 5/30/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class PodcastPeekController: UITableViewController {
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var infoTextView: InternalLinkTextView!
    @IBOutlet weak var doneButton: UIButton!
    
    var artwork: UIImage?
    var currentPodcast: PodcastEntry?
    
    lazy var slideInTransitioningDelegate = SlideInTransitioningDelegate(direction: .top, animation: .animationDefault)
    var interactiveTransition = UIPercentDrivenInteractiveTransition()
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    
    func startLoadingAnimation() {
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        activityIndicator.center = infoTextView.center
        infoTextView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    func stopLoadingAnimation() {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // custom transition
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = slideInTransitioningDelegate
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let cellView = doneButton.superview {
            cellView.backgroundColor = Theme.primaryColor
        }
        doneButton.setTitleColor(UIColor.white, for: .normal)
        doneButton.setTitleColor(UIColor.lightText, for: .highlighted)
        backgroundImageView.image = artwork
        infoTextView.linkTextAttributes = [NSForegroundColorAttributeName: UIColor.yellow]

        startLoadingAnimation()
        preparePodcastInfo()
        
        // gesture to pull it up
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        view.addGestureRecognizer(gesture)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func handleGesture(_ gesture: UIPanGestureRecognizer) {
        let translate = gesture.translation(in: gesture.view)
        let percent = -translate.y / gesture.view!.bounds.size.height
        
        switch gesture.state {
            
        case .began:
            slideInTransitioningDelegate.interactiveTransition = interactiveTransition
            dismiss(animated: true)
            
        case .changed:
            interactiveTransition.update(percent)
            
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: gesture.view)
            
            if (percent > 0.5 && velocity.y == 0) || velocity.y < 0 {
                interactiveTransition.finish()
            } else {
                interactiveTransition.cancel()
            }
            
            slideInTransitioningDelegate.interactiveTransition = nil
            
        default:
            break
        }
    }
    
    func preparePodcastInfo() {
        DataFetcher.fetchPodcastAttributedString(podcast: self.currentPodcast, preferWhite: true) { attributedText in
            DispatchQueue.main.async {
                self.infoTextView.attributedText = attributedText
                // workaround for textview's bug on cutting off part from the bottom of the view
                self.infoTextView.isScrollEnabled = false
                self.infoTextView.isScrollEnabled = true
                self.stopLoadingAnimation()
            }
        }
    }

    @IBAction func doneTouched(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
