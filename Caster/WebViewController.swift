//
//  WebViewController.swift
//  Caster
//
//  Created by Alex Truong on 5/30/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class WebViewController: UIViewController, UIWebViewDelegate {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var doneButton: UIButton!
    var url: URL?
    
    lazy var slideInTransitioningDelegate = SlideInTransitioningDelegate(direction: .top, animation: .animationSpringWithDamping)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // custom transition
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = slideInTransitioningDelegate
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = Theme.primaryColor
        doneButton.setTitleColor(UIColor.white, for: .normal)
        
        if let url = self.url {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()

            webView.delegate = self
            let request = URLRequest(url: url)
            self.webView.loadRequest(request)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func doneTouched(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.activityIndicator.stopAnimating()
        self.activityIndicator.isHidden = true
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        let error = error as NSError
        
        // ignore redirect, domain and "plugin handled load" errors
        if error.code != NSURLErrorCancelled, error.code != 102, error.code != 204 {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            
            let style = "<style> * { font-family: Avenir-light; color: black; } </style>"
            let errorString = "Error: \(error.localizedDescription)<br/>\(error.localizedFailureReason ?? "")<br/>\(error.localizedRecoverySuggestion ?? "")"
            webView.loadHTMLString("\(style)<h3>\(errorString)</h3>", baseURL: nil)
        }
    }    
}
