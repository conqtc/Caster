//
//  MainMenuController.swift
//  Caster
//
//  Created by Alex Truong on 5/6/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

enum MenuCommands: Int {
    case NO_COMMAND
    
    case MyPodcast
    case Downloads
    case Country
    case Theme
    case Settings
    case About
    
    case AU
    case GB
    case US
    case CN
    case FR
    case DE
    case IT
    case JP
    case KR
    case RU
    case ES
    case VN
}

protocol MenuDelegate: class {
    func menu(_ sender: UITableViewController, didDismissMenuWithSelectedCommand command: MenuCommands)
}

class MainMenuController: UITableViewController {
    
    var menuItems: [(String, MenuCommands)] = [
        ("Subscriptions", MenuCommands.MyPodcast),
        ("Downloads", MenuCommands.Downloads),
        ("Theme", MenuCommands.Theme),
        ("Country", MenuCommands.Country),
        ("Settings", MenuCommands.Settings),
        ("About", MenuCommands.About)
    ]
    
    var menuIcons = [UIImage]()
    var selectedCommand: MenuCommands = .NO_COMMAND
    
    var delegate: MenuDelegate?
    
    lazy var slideInTransitioningDelegate = SlideInTransitioningDelegate(direction: .left, animation: .animationStretchThenShrink)
    var interactiveTransition = UIPercentDrivenInteractiveTransition()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // custom transition
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = slideInTransitioningDelegate
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        for index in 0..<menuItems.count {
            if menuItems[index].1 == .Country {
                menuIcons.append(UIImage(named: country)!)
            } else {
                menuIcons.append(UIImage(named: menuItems[index].0)!)
            }
        }
        
        // gesture to swipe it back in to the left
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
        let percent = -translate.x / gesture.view!.bounds.size.width
        
        switch gesture.state {
            
        case .began:
            slideInTransitioningDelegate.interactiveTransition = interactiveTransition
            dismiss(animated: true)
            
        case .changed:
            interactiveTransition.update(percent)
            
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: gesture.view)
            
            if (percent > 0.5 && velocity.x == 0) || velocity.x < 0 {
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

        cell.textLabel?.text = menuItems[indexPath.row].0
        cell.imageView?.image = menuIcons[indexPath.row]

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCommand = menuItems[indexPath.row].1
        dismiss(animated: true)
    }
}
