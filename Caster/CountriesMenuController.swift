//
//  CountriesMenuController.swift
//  Caster
//
//  Created by Alex Truong on 5/7/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class CountriesMenuController: UITableViewController {
    let menuItems: [(String, String, MenuCommands)] = [
        ("au", "Australia", MenuCommands.AU),
        ("us", "United States", MenuCommands.US),
        ("cn", "China", MenuCommands.CN),
        ("gb", "United Kingdom", MenuCommands.GB),
        ("jp", "Japan", MenuCommands.JP),
        ("fr", "France", MenuCommands.FR),
        ("kr", "Korea", MenuCommands.KR),
        ("es", "Spain", MenuCommands.ES),
        //("de", "Germany", MenuCommands.DE),
        //("it", "Italy", MenuCommands.IT),
        //("ru", "Russia", MenuCommands.RU),
        //("vn", "Vietnam", MenuCommands.VN),
    ]

    
    var menuIcons = [UIImage]()
    var selectedCommand: MenuCommands = .NO_COMMAND
    
    var delegate: MenuDelegate?
    
    lazy var slideInTransitioningDelegate = SlideInTransitioningDelegate(direction: .top, animation: .animationSpringWithDamping)
    var interactiveTransition = UIPercentDrivenInteractiveTransition()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // custom transition
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = slideInTransitioningDelegate
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for (name, _, _) in menuItems {
            menuIcons.append(UIImage(named: name)!)
        }
        
        // gesture to pull it up
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        view.addGestureRecognizer(gesture)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.menu(self, didDismissMenuWithSelectedCommand: selectedCommand)
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
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReuseCell", for: indexPath)
        
        cell.textLabel?.text = menuItems[indexPath.row].1
        cell.imageView?.image = menuIcons[indexPath.row]
        
        if country == menuItems[indexPath.row].0 {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCommand = menuItems[indexPath.row].2
        dismiss(animated: true)
    }
}
