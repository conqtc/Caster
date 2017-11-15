//
//  AlphaBarsTableViewController.swift
//  Caster
//
//  Created by Alex Truong on 6/3/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class AlphaBarsTableViewController: UITableViewController {
    //
    var navigationBar: UINavigationBar!

    //
    var navBarHeight: CGFloat = 0
    var statusBarHeight: CGFloat = 0

    //
    var alpha: CGFloat = 0
    var tintColor: UIColor = UIColor.white

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let navigationBar = navigationController?.navigationBar {
            self.navigationBar = navigationBar
            navBarHeight = navigationBar.frame.size.height
        }
        
        statusBarHeight = UIApplication.shared.getStatusBarHeight()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // make transition great again
        if let coordinator = self.transitionCoordinator {
            let color = tintColor.withAlphaComponent(alpha)
            
            coordinator.animate(alongsideTransition: { _ in
                self.navigationController?.navigationBar.backgroundColor = color
            })
            
            coordinator.animateAlongsideTransition(in: statusBar, animation: { _ in
                statusBar.backgroundColor = color
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
