//
//  EpisodeViewController.swift
//  Caster
//
//  Created by Alex Truong on 5/28/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

protocol EpisodeDelegate: class {
    func episode(_ sender: EpisodeViewController, didDismissAndStream willStream: Bool, withAttributedText attributedText: NSMutableAttributedString?)
}

class EpisodeViewController: UITableViewController {
    @IBOutlet weak var streamButton: UIButton!
    @IBOutlet weak var infoTextView: InternalLinkTextView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    var currentEpisode: EpisodeItem?
    var artwork: UIImage?
    var attributedText: NSMutableAttributedString?
    var willStream: Bool = false
    
    var delegate: EpisodeDelegate?
    
    lazy var slideInTransitioningDelegate = SlideInTransitioningDelegate(direction: .top, animation: .animationSpringWithDamping)
    var interactiveTransition = UIPercentDrivenInteractiveTransition()
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
    
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
        
        streamButton.backgroundColor = Theme.primaryColor
        backgroundImageView.image = artwork
        infoTextView.linkTextAttributes = [NSForegroundColorAttributeName: UIColor.yellow]
        
        startLoadingAnimation()
        prepareEpisodeInfo()
        
        // gesture to pull it up
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        view.addGestureRecognizer(gesture)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.delegate?.episode(self, didDismissAndStream: willStream, withAttributedText: attributedText)
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

    @IBAction func streamTouched(_ sender: UIButton) {
        willStream = true
        dismiss(animated: true)
    }
    
    // prepare attributed string for episode's information
    func prepareEpisodeInfo() {
        DataFetcher.fetchEpisodeAttributedString(episode: self.currentEpisode) { attributedText in
            self.attributedText = attributedText
            DispatchQueue.main.async {
                self.infoTextView.attributedText = attributedText
                // workaround for textview's bug on cutting off part from the bottom of the view
                self.infoTextView.isScrollEnabled = false
                self.infoTextView.isScrollEnabled = true
                self.stopLoadingAnimation()
            }
        }
    }
}

// preview actions for peek
extension EpisodeViewController {
    override var previewActionItems: [UIPreviewActionItem] {
        let streamAction = UIPreviewAction(title: "Stream This Episode", style: .default) { action, viewController in
            self.delegate?.episode(self, didDismissAndStream: true, withAttributedText: self.attributedText)
        }
        
        let closeAction = UIPreviewAction(title: "Close", style: .destructive) { action, viewController in
            // do nothing, just looks nice
        }
        
        return [streamAction, closeAction]
        
    }
}
