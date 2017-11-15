//
//  AppDelegate.swift
//  Caster
//
//  Created by Alex Truong on 4/16/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit
import MediaPlayer
import CoreData

// MARK: global data
let kBackgroundIdentifier = "CasterPodcastAppBackgroundId"
let kiTunesLookupPrefix = "https://itunes.apple.com/lookup?id="

var country = "au"
var isLatinLanguage = true
let genreData = GenreData()

var topCountryMap = [String: [Int: [PodcastEntry]]]()
var topPodcastListMap = [Int: [PodcastEntry]]()
var podcastMap = [Int: PodcastEntry]()
var episodeListMap = [Int: EpisodeItem]()

let justAnImage = UIImage()
let defaultArtwork = UIImage(named: "Artwork Large")

var mediaPlayer = PlayerController()

// now playing bar
let kNowPlayingBarHeight: CGFloat = 56
var nowPlayingBar: UIView!
var nowPlayingBackground: UIImageView!
var nowPlayingArtwork: UIImageView!
var nowPlayingButton: UIButton!
var nowPlayingProgress: UIProgressView!
var nowPlayingTitle: UILabel!
var nowPlayingArtist: UILabel!
let nowPlayImage = UIImage(named: "npPlay")
let nowPauseImage = UIImage(named: "npPause")
var nowPlayingRate: Double = 0.0

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // render attributed string the first time to warm up the webkit and javascriptcore engine into memory
        DispatchQueue.global(qos: .background).async {
            let _ = "<span>Let's warm up WebKit</span>".attributedString()
        }
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        // register remote commands
        let remoteCommands = MPRemoteCommandCenter.shared()
        // play
        remoteCommands.playCommand.addTarget { event in
            mediaPlayer.playImmediately(atRate: 1.0)
            return .success
        }
        // pause
        remoteCommands.pauseCommand.addTarget { event in
            mediaPlayer.pause()
            return .success
        }
        // skip forward
        remoteCommands.skipForwardCommand.preferredIntervals = [NSNumber(value: 30)]
        remoteCommands.skipForwardCommand.addTarget { event in
            mediaPlayer.skipForward()
            return .success
        }
        // skip backward
        remoteCommands.skipBackwardCommand.preferredIntervals = [NSNumber(value: 30)]
        remoteCommands.skipBackwardCommand.addTarget { event in
            mediaPlayer.skipBackward()
            return .success
        }
        
        // don't show the network activity indicator
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidEnterBackground(_ application: UIApplication) {
        // keep this app active in the background for around 3 mins which is
        // long enough to load the media to play
        backgroundTaskIdentifier =
            UIApplication.shared.beginBackgroundTask(expirationHandler: {
                UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!)
                self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
            })
    }

    func applicationWillEnterForeground(_ application: UIApplication) {}

    func applicationDidBecomeActive(_ application: UIApplication) {}

    func applicationWillTerminate(_ application: UIApplication) {
        self.saveContext()
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if let window = window {
            guard let rootController = window.rootViewController as? UINavigationController else { return }
            guard let controller = rootController.viewControllers.first as? CasterViewController else { return }
            controller.handleShortcutItem(shortcutItem)
        }
        
        completionHandler(true)
    }
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Caster")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

