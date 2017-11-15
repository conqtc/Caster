//
//  InternalLinkTextView.swift
//  Caster
//
//  Created by Alex Truong on 5/30/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit
import SafariServices

class InternalLinkTextView: UITextView, UITextViewDelegate {
    
    var preferredSafari: Bool = false
    
    var gradientMask: CAGradientLayer?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.delegate = self

        self.gradientMask = CAGradientLayer()
        if let mask = self.gradientMask {
            mask.bounds = self.frame
            mask.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
            mask.locations = [0.0, 0.02, 0.98, 1.0]
            mask.anchorPoint = .zero
            self.layer.mask = mask
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientMask?.bounds = self.frame
        gradientMask?.position = CGPoint(x: 0, y: scrollView.contentOffset.y)
        CATransaction.commit()
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        if preferredSafari {
            let safariViewController = SFSafariViewController(url: URL, entersReaderIfAvailable: true)

            if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController as? UINavigationController, let currentViewController = rootViewController.visibleViewController {
                currentViewController.present(safariViewController, animated: true)
                
                return false
            }
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let webView = storyboard.instantiateViewController(withIdentifier: "WebView") as? WebViewController {
            webView.url = URL
            
            if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController as? UINavigationController, let currentViewController = rootViewController.visibleViewController {
                currentViewController.present(webView, animated: true)
            }
        }
    
        return false
    }
}
