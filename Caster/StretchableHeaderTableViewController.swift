//
//  StretchableHeaderTableViewController.swift
//  Caster
//
//  Created by Alex Truong on 4/22/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class StretchableHeaderTableViewController: AlphaBarsTableViewController {

    var headerView: UIView!
    var headerHeight: CGFloat = 240
    var headerWidth: CGFloat = 0
    
    var headerOffset: CGFloat = 0

    var statusBarHidden = false
    var didLayoutHeader = false
    var didAppear = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // replace the header view with our own view
        headerView = tableView.tableHeaderView
        // almost invisible header view
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: CGFloat.leastNormalMagnitude))
        // work with the new controllable header view
        tableView.addSubview(headerView)
    }
    
    // re-calculate the inset/offset including the toplayoutguide
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if !didLayoutHeader {
            var inset = tableView.contentInset
            inset.top = headerHeight
            tableView.contentInset = inset
            
            headerWidth = tableView.bounds.width
            let r = CGRect(x: 0, y: -headerHeight, width: headerWidth, height: headerHeight)
            headerView.frame = r
            
            // scroll to the top
            headerOffset = -inset.top
            tableView.contentOffset.y = headerOffset
            
            didLayoutHeader = true
        }
    }
 
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        didAppear = true
        
        // re-calculate the transparency and offset values
        scrollViewDidScroll(self.tableView)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        didAppear = false
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    // do nothing, to be overriden in subclass
    // offset < 0: pull down
    // offset > 0: pull up
    func tableViewDidPull(withOffset offset: CGFloat) {}
    
    // handling pulling up and down
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if didAppear, didLayoutHeader {
            var alphax: CGFloat = 0

            let offset = tableView.contentOffset.y
            if offset <= headerOffset {
                // pull down
                var r = CGRect(x: 0, y: -headerHeight, width: headerWidth, height: headerHeight)
                r.origin.y -= (headerOffset - offset)
                r.size.height += (headerOffset - offset)
                headerView.frame = r
            } else {
                // pull up
                alphax = (offset - headerOffset) / (self.headerHeight - navBarHeight - statusBarHeight)
                alphax = min(1.0, alphax)
            }
            
            // only if different
            if alphax != self.alpha {
                self.alpha = alphax
                // change status bar and navigation bar alpha
                let color = tintColor.withAlphaComponent(self.alpha)
                UIApplication.shared.setStatusBarBackgroundColor(color: color)
                navigationBar.backgroundColor = color
                // calling dynamic incase subclass has anything to do with it
                tableViewDidPull(withOffset: (offset - headerOffset))
            }
        }
    }
}

// MARK: -
extension StretchableHeaderTableViewController: NowPlayingDelegate {
    func didDismissNowPlaying(_ sender: NowPlayingViewController) {
        self.scrollViewDidScroll(self.tableView)
    }
}

// MARK: status bar handling
extension StretchableHeaderTableViewController {
    override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    func updateStatusBar(hidden: Bool) {
        if statusBarHidden != hidden {
            statusBarHidden = hidden
            UIView.animate(withDuration: 0.2) {
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
}
