//
//  Utility.swift
//  Caster
//
//  Created by Alex Truong on 4/24/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration

class Utility {
    static var errorView: UIView?
    static var noConnectionImageView: UIImageView?
    static var errorLabel: UILabel?
    static var retryButton: UIButton?
    static var currentRetryCommand: Selector?
    static var stackView: UIStackView?
    static var isErrorViewActive = false
    
    //
    static func timeFormatFromSeconds(_ time: Int) -> String {
        let remain = time % 3600
        let h = time / 3600
        let m = remain / 60
        let s = remain % 60
        
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
    
    //
    static func normalizeEpisodeDuration(_ string: String) -> String? {
        let comps = string.components(separatedBy: ":")
        
        let interval = comps.reversed().enumerated().map { index, number in
                (Double(number) ?? 0) * pow(Double(60), Double(index))
            }.reduce(0, +)
        
        if let time = Int(exactly: interval) {

            let remain = time % 3600
            let h = time / 3600
            let m = remain / 60
            let s = remain % 60
        
            var result = ""
            
            if h > 0 {
                result.append("\(h)h")
            }
            
            if (m > 0) {
                if !result.isEmpty {
                    result.append(" ")
                }
                result.append("\(m)m")
            }

            if (s > 0) {
                if !result.isEmpty {
                    result.append(" ")
                }
                result.append("\(s)s")
            }
            
            return result
        }
        
        return nil
    }

    
    //
    // http://stackoverflow.com/questions/39558868/check-internet-connection-ios-10
    //
    class func isInternetAvailable() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
    //
    class func loadArtworkFromFile(withId id: Int) -> UIImage? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent("\(id)")
        return UIImage(contentsOfFile: fileURL.path)
    }

    class func loadSmallArtworkFromFile(withId id: Int) -> UIImage? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent("\(id)s")
        return UIImage(contentsOfFile: fileURL.path)
    }

    //
    class func fileUrl(for name: String) -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        return documentsURL.appendingPathComponent(name)
    }
    
    class func topupErrorLayer(overController controller: UITableViewController, errorMessage: String, retryCommand: Selector) {
        
        if errorView == nil {
            errorView = UIView()
            errorView?.backgroundColor = UIColor(white: 0.9, alpha: 1.0)

            noConnectionImageView = UIImageView(image: UIImage(named: "NoConnection"))
            noConnectionImageView?.frame = CGRect(x: 0, y: 0, width: 128, height: 128)
            noConnectionImageView?.contentMode = .scaleToFill
            
            errorLabel = UILabel()
            
            retryButton = UIButton(type: .roundedRect)
            retryButton?.setTitle("Try Again", for: .normal)
            
            stackView = UIStackView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
            stackView?.axis = .vertical
            stackView?.distribution = .equalSpacing
            stackView?.alignment = .center
            stackView?.spacing = 5.0
            
            stackView?.addArrangedSubview(noConnectionImageView!)
            stackView?.addArrangedSubview(errorLabel!)
            stackView?.addArrangedSubview(retryButton!)
            
            errorView?.addSubview(stackView!)
        }
        
        if let errorView = errorView {
            // remove from super view if has
            if isErrorViewActive {
                if let parent = errorView.superview as? UITableView {
                    parent.isScrollEnabled = true
                }
                errorView.removeFromSuperview()
            }

            errorView.frame = controller.tableView.bounds
            errorLabel?.text = errorMessage
            
            if currentRetryCommand != nil {
                retryButton?.removeTarget(controller, action: currentRetryCommand, for: .touchUpInside)
            }
            retryButton?.addTarget(controller, action: retryCommand, for: .touchUpInside)
            currentRetryCommand = retryCommand
            
            stackView?.center.x = errorView.frame.size.width / 2
            stackView?.center.y = errorView.frame.size.height / 2
            
            controller.tableView.addSubview(errorView)
            controller.tableView.bringSubview(toFront: errorView)
            controller.tableView.isScrollEnabled = false
            isErrorViewActive = true
        }
    }
    
    class func removeErrorLayer(onController controller: UITableViewController) {
        if isErrorViewActive {
            if let errorView = errorView {
                if let parent = errorView.superview as? UITableView {
                    parent.isScrollEnabled = true
                }
                errorView.removeFromSuperview()
            }
            isErrorViewActive = false
        }
    }
}
