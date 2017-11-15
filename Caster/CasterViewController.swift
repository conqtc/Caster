//
//  CasterController.swift
//  Caster
//
//  Created by Alex Truong on 4/16/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

// 3D touch quick actions
enum QuickAction: String {
    case Search
    case About
    
    init?(from shortcutItem: UIApplicationShortcutItem) {
        guard let last = shortcutItem.type.components(separatedBy: ".").last else { return nil }
        self.init(rawValue: last)
    }
}

class CasterViewController: StretchableHeaderTableViewController {
    // list of sections
    // id: genre id (zero in case of top podcast)
    // cellType: type of cell
    // title: section title
    var sections = [(id: Int, cellType: TableViewCellTypes, title: String, numberOfRows: Int)]()
    var collectionCellForSectionId = [Int: PodcastCollectionCell?]()
    
    // selected genreid when touch "view all"
    var selectedGenreId: Int = 0
    
    // selected podcast id
    var selectedPodcastId: Int = 0
    
    // selected artwork for selected podcast
    var selectedArtwork: UIImage?
    
    // custom slide in transitioning delegate
    lazy var slideInTransitioningDelegate = SlideInTransitioningDelegate(direction: .top, animation: .animationSpringWithDamping)
    
    // interactive transition for left-edge swipe to display main menu
    var interactiveTransition = UIPercentDrivenInteractiveTransition()
    // main menu controller
    var mainMenuController: MainMenuController!
    
    // now playing controller for interactive presentation
    var nowPlayingController: NowPlayingViewController!
    
    // how many podcast collection cell has been fetched
    var finishLoadingCount = 0
    
    // loading indicator
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
    // transparent view topping over current view, contains activity indicator view
    var loadingView: UIView?
    
    // topup a loading view on top of current view and start spinning
    func startLoadingAnimation() {
        // dark gray background with corner
        activityIndicator.backgroundColor = Theme.primaryColor
        activityIndicator.layer.cornerRadius = 5.0
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        
        // create the view and add activity indicator as subview
        if loadingView == nil {
            loadingView = UIView()
            loadingView?.backgroundColor = UIColor(white: 0.8, alpha: 0.5)
            loadingView?.addSubview(activityIndicator)
        }

        // disable scrolling while loading
        tableView.isScrollEnabled = false

        // re-adjust size and position
        loadingView?.frame = tableView.bounds
        activityIndicator.center.x = loadingView!.center.x
        activityIndicator.center.y = loadingView!.frame.height / 2
        
        tableView.addSubview(loadingView!)
        // start animating
        activityIndicator.startAnimating()
    }
    
    // stop spinning and remove from super view
    func stopLoadingAnimation() {
        activityIndicator.stopAnimating()
        loadingView?.removeFromSuperview()
        // re-enable scrolling
        tableView.isScrollEnabled = true
    }
    
    // view did load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // make navigation bar/status bar transparent
        navigationBar.setBackgroundImage(justAnImage, for: .default)
        navigationBar.shadowImage = justAnImage
        navigationBar.isTranslucent = true
        
        // register custom cells type
        registerCellTypesFromNibs()

        // re-adjust header height and table view's automatic height
        self.headerHeight = 200
        tableView.estimatedRowHeight = 32
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // top podcast in general collection
        sections.append((0, TableViewCellTypes.PodcastCollection, "Top Podcasts", 1))
        // display this app's info
        sections.append((0, TableViewCellTypes.Announcement, "", 1))
        // top podcasts for featured genres
        for feature in genreData.features {
            sections.append((feature.id, TableViewCellTypes.PodcastCollection, feature.title, 1))
        }
        // list of sub genres
        sections.append((1000, TableViewCellTypes.PodcastGenre, "Genres", genreData.genres.count))
        
        // switch the cache map for current country first time
        switchCountryCacheMap()
        // start loading
        startLoadingAnimation()

        // setup now playing bar
        setupNowPlayingBar()
        
        // setup left edge swipe for menu
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleScreenEdgeGesture(_:)))
        gesture.edges = .left
        view.addGestureRecognizer(gesture)
    }
    
    //
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // register custom cells
    func registerCellTypesFromNibs() {
        let cellTypes = [
            TableViewCellTypes.Announcement,
            TableViewCellTypes.PodcastGenre,
            TableViewCellTypes.PodcastHeader,
        ]
        
        for cell in cellTypes {
            tableView.register(UINib(nibName: cell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: cell.reuseIdentifier)
        }
        
        // keep all podcast collection cell in memory, not recycling them
        // register same cell type with different reuse id
        let cell = TableViewCellTypes.PodcastCollection
        // top podcast collection
        tableView.register(UINib(nibName: cell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: cell.reuseIdentifier + "0")
        // collections for featured genres
        for feature in genreData.features {
            tableView.register(UINib(nibName: cell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: cell.reuseIdentifier + "\(feature.id)")
        }
    }
    
    func handleScreenEdgeGesture(_ gesture: UIScreenEdgePanGestureRecognizer) {
        let translate = gesture.translation(in: gesture.view)
        var percent = translate.x / (0.75 * gesture.view!.bounds.size.width)
        percent = fmin(percent, 1.0)
        
        switch gesture.state {
            
        case .began:
            mainMenuController = storyboard!.instantiateViewController(withIdentifier: "MainMenu") as! MainMenuController
            mainMenuController.slideInTransitioningDelegate.interactiveTransition = interactiveTransition
            mainMenuController.delegate = self
            
            self.present(mainMenuController, animated: true)
            
        case .changed:
            interactiveTransition.update(percent)
            
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: gesture.view)

            if (percent > 0.5 && velocity.x == 0) || velocity.x > 0 {
                interactiveTransition.finish()
            } else {
                interactiveTransition.cancel()
            }
            
            mainMenuController.slideInTransitioningDelegate.interactiveTransition = nil
            
        default:
            break
        }
    }
    
    func nowPlayingArtworkTouched(recognizer: UITapGestureRecognizer) {
        if let controller = storyboard?.instantiateViewController(withIdentifier: "NowPlaying") as? NowPlayingViewController {
            // tell now playing that it is to be view the current now playing, not start a new one
            controller.currentEpisode = nil
            
            // get current view controller
            if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController as? UINavigationController, let currentViewController = rootViewController.visibleViewController {
                
                if let stretchable = currentViewController as? StretchableHeaderTableViewController {
                    controller.delegate = stretchable
                }
                
                currentViewController.present(controller, animated: true)
            } else {
                controller.delegate = self
                self.present(controller, animated: true)
            }
        }

    }
    
    func nowPlayingArtworkDragged(_ gesture: UIPanGestureRecognizer) {
        let keyWindow = UIApplication.shared.keyWindow!
        
        let translate = gesture.translation(in: keyWindow)
        let percent = -translate.y / keyWindow.bounds.size.height
        
        switch gesture.state {
            
        case .began:
            nowPlayingController = storyboard!.instantiateViewController(withIdentifier: "NowPlaying") as! NowPlayingViewController
            nowPlayingController.slideInTransitioningDelegate.interactiveTransition = interactiveTransition
            nowPlayingController.currentEpisode = nil
            
            if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController as? UINavigationController, let currentViewController = rootViewController.visibleViewController {
                
                if let stretchable = currentViewController as? StretchableHeaderTableViewController {
                    nowPlayingController.delegate = stretchable
                }

                currentViewController.present(nowPlayingController, animated: true)
            } else {
                nowPlayingController.delegate = self
                self.present(nowPlayingController, animated: true)
            }
            
        case .changed:
            interactiveTransition.update(percent)
            
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: keyWindow)
            
            if (percent > 0.5 && velocity.y == 0) || velocity.y < 0 {
                interactiveTransition.finish()
            } else {
                interactiveTransition.cancel()
            }
            
            nowPlayingController.slideInTransitioningDelegate.interactiveTransition = nil
            
        default:
            break
        }
    }
    
    func setupNowPlayingBar() {
        // now playing view
        let r = self.view.bounds
        nowPlayingBar = UIView(frame: CGRect(x: 0, y: -kNowPlayingBarHeight, width: r.size.width, height: kNowPlayingBarHeight))
        
        // setup now playing bar
        nowPlayingBar.backgroundColor = UIColor.darkGray
        nowPlayingBar.layer.masksToBounds = false
        nowPlayingBar.layer.shadowOffset = CGSize(width: 0, height: -2)
        nowPlayingBar.layer.shadowRadius = 2
        nowPlayingBar.layer.shadowOpacity = 0.2
        
        // setup background image
        
        nowPlayingBackground = UIImageView(frame: nowPlayingBar.bounds)
        nowPlayingBackground.clipsToBounds = true
        nowPlayingBackground.contentMode = .scaleToFill
        nowPlayingBackground.image = UIImage(named: "Genre")
        nowPlayingBar.addSubview(nowPlayingBackground)
         
        // blur effects
        let darkBlur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        darkBlur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        darkBlur.frame = nowPlayingBackground.bounds
        nowPlayingBar.addSubview(darkBlur)
        
        // setup play button
        nowPlayingButton = UIButton(type: .custom)
        nowPlayingButton.contentMode = .scaleToFill
        nowPlayingButton.setImage(nowPlayImage, for: .normal)
        nowPlayingButton.addTarget(mediaPlayer, action: #selector(PlayerController.toggleNowPlaying(sender:)), for: .touchUpInside)
        nowPlayingButton.addConstraint(NSLayoutConstraint(item: nowPlayingButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 40))

        // setup progress view
        nowPlayingProgress = UIProgressView(progressViewStyle: .default)
        nowPlayingProgress.trackTintColor = UIColor.clear
        nowPlayingProgress.progressTintColor = Theme.primaryColor
        // setup title
        nowPlayingTitle = UILabel()
        nowPlayingTitle.font = UIFont(name: Theme.primaryFont, size: 14.0)
        nowPlayingTitle.textColor = UIColor.white
        // setup artist
        nowPlayingArtist = UILabel()
        nowPlayingArtist.font = UIFont(name: Theme.primaryFont, size: 12.0)
        nowPlayingArtist.textColor = UIColor.lightText
        
        // setup a stack
        let vStack = NowPlayingBarStackView(arrangedSubviews: [nowPlayingTitle, nowPlayingProgress, nowPlayingArtist])
        vStack.axis = .vertical
        vStack.frame = nowPlayingBar.bounds
        vStack.alignment = .fill
        vStack.distribution = .fill
        vStack.spacing = 2

        // setup artwork
        nowPlayingArtwork = UIImageView(frame: nowPlayingBar.bounds)
        nowPlayingArtwork.layer.borderColor = UIColor(white: 0.8, alpha: 0.5).cgColor
        nowPlayingArtwork.layer.borderWidth = 1.0
        nowPlayingArtwork.layer.masksToBounds = false
        nowPlayingArtwork.layer.shadowOffset = CGSize(width: 0, height: 0)
        nowPlayingArtwork.layer.shadowRadius = 3
        nowPlayingArtwork.layer.shadowOpacity = 0.5
        nowPlayingArtwork.contentMode = .scaleAspectFill
        nowPlayingArtwork.image = defaultArtwork
        nowPlayingArtwork.translatesAutoresizingMaskIntoConstraints = false
        nowPlayingArtwork.addConstraint(NSLayoutConstraint(item: nowPlayingArtwork, attribute: .height, relatedBy: .equal, toItem: nowPlayingArtwork, attribute: .width, multiplier: 1.0, constant: 0))
        nowPlayingArtwork.addConstraint(NSLayoutConstraint(item: nowPlayingArtwork, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 48))
        // handling tap
        let gesture = UITapGestureRecognizer(target: self, action: #selector(nowPlayingArtworkTouched(recognizer:)))
        nowPlayingBar.addGestureRecognizer(gesture)
 
        // setup a stack
        let hStack = NowPlayingBarStackView(arrangedSubviews: [nowPlayingButton, vStack, nowPlayingArtwork])
        hStack.axis = .horizontal
        hStack.frame = nowPlayingBar.bounds
        hStack.alignment = .center
        hStack.distribution = .fill
        hStack.spacing = 8
        
        nowPlayingBar.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|[stack]|", options: [], metrics: nil, views: ["stack": hStack]))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[stack]-3-|", options: [], metrics: nil, views: ["stack": hStack]))
        
        // add to the key window of the app so that this windows is above all else
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(nowPlayingBar)
            // handling drag up
            let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(nowPlayingArtworkDragged(_:)))
            dragGesture.delegate = self
            window.addGestureRecognizer(dragGesture)
        }
    }
    
    func switchCountryCacheMap() {
        if let cacheMap = topCountryMap[country] {
            topPodcastListMap = cacheMap
        } else {
            topCountryMap[country] = [Int: [PodcastEntry]]()
            topPodcastListMap = topCountryMap[country]!
        }
    }
    
    // MARK: table view behaviour
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == sections.count - 1 {
            return kNowPlayingBarHeight
        } else {
            return CGFloat.leastNormalMagnitude
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].numberOfRows
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch (sections[section].cellType) {
        case .Banner, .Announcement:
            return CGFloat.leastNormalMagnitude
        default:
            return 36
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch (sections[section].cellType) {
        case .PodcastCollection:
            let headerCell = tableView.dequeueReusableCell(withIdentifier: TableViewCellTypes.PodcastHeader.reuseIdentifier) as! PodcastHeaderCell
            let sectionId = sections[section].id
            if sectionId == 0 {
                headerCell.title = sections[section].title.uppercased()
            } else {
                let genre = genreData.map[sectionId]!
                headerCell.title = genre.title.uppercased()
            }
            
            // gid
            headerCell.gid = sections[section].id
            headerCell.delegate = self
            
            return headerCell
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellType = sections[indexPath.section].cellType
        
        if cellType != .PodcastCollection {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellType.reuseIdentifier, for: indexPath)
            
            switch (cellType) {
                
            case .Announcement:
                let announcementCell = cell as! AnnouncementCell
                return announcementCell
                
            case .PodcastGenre:
                let genreCell = cell as! PodcastGenreCell
                genreCell.accessoryType = .disclosureIndicator
                genreCell.genreTitle = genreData.genres[indexPath.row].title
                return genreCell
                
            case .Banner:
                let bannerCell = cell as! BannerCell
                return bannerCell
                
            default:
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellType.reuseIdentifier + "\(sections[indexPath.section].id)", for: indexPath)
            
            if let podcastCollectionCell = cell as? PodcastCollectionCell {
                
                if podcastCollectionCell.gid != sections[indexPath.section].id {
                    podcastCollectionCell.gid = sections[indexPath.section].id
                    
                    if sections[indexPath.section].id == 0 {
                        podcastCollectionCell.setCollectionDimension(numberOfRows: 2, numberOfCols: 3)
                    } else {
                        podcastCollectionCell.setCollectionDimension(numberOfRows: 1, numberOfCols: 3)
                    }
                    podcastCollectionCell.delegate = self
                }
                
                // keep reference this cell to reload later
                collectionCellForSectionId[sections[indexPath.section].id] = podcastCollectionCell
                return podcastCollectionCell
            }
            
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellType = sections[indexPath.section].cellType
        
        if cellType == TableViewCellTypes.PodcastGenre {
            selectedGenreId = genreData.genres[indexPath.row].id
            if genreData.genres[indexPath.row].subGenres.count > 0 {
                // view genres with its subgenres
                performSegue(withIdentifier: "viewGenre", sender: self)
            } else {
                // view top podcasts in that particular genre
                performSegue(withIdentifier: "viewTopPodcast", sender: self)
            }
        }
    }
}

// MARK: -
extension CasterViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if (touch.view?.isKind(of: NowPlayingBarStackView.self) ?? false) {
            return true
        }
        
        return false
    }
}

// MARK: - 3D touch quick shortcuts
extension CasterViewController {
    func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
        
        guard let quickAction = QuickAction(from: shortcutItem) else { return }
        
        if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController as? UINavigationController, let currentViewController = rootViewController.visibleViewController  {
            
            // dismiss all modals
            // TODO: two modals presented at the same time?
            var present = currentViewController
            while let presenting = present.presentingViewController {
                present = presenting
                presenting.dismiss(animated: true)
            }
            present.dismiss(animated: true)

            switch (quickAction) {
                
            case .Search:
                let searchViewController = storyboard!.instantiateViewController(withIdentifier: "SearchViewController") as! SearchViewController
                // go back to main caster view and push the search
                if !present.isKind(of: SearchViewController.self) {
                    rootViewController.popToViewController(self, animated: true)
                    rootViewController.pushViewController(searchViewController, animated: true)
                }
            
            case .About:
                let aboutViewController = storyboard!.instantiateViewController(withIdentifier: "AboutViewController") as! AboutViewController
                // go back to main caster view and push
                if !present.isKind(of: AboutViewController.self) {
                    rootViewController.popToViewController(self, animated: true)
                    rootViewController.pushViewController(aboutViewController, animated: true)
                }
            }
        }

    }
}

// MARK: -
extension CasterViewController: MenuDelegate {
    func reloadPodcastCollections() {
        finishLoadingCount = 0
        startLoadingAnimation()
        
        for section in 0..<sections.count {
            if sections[section].cellType == .PodcastCollection {
                if let cell = collectionCellForSectionId[sections[section].id] {
                    cell?.gid = sections[section].id
                }
            }
        }
    }
    
    func menu(_ sender: UITableViewController, didDismissMenuWithSelectedCommand command: MenuCommands) {
        
        // update UI anyway
        self.scrollViewDidScroll(self.tableView)

        switch (command) {
        case .Country:
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "showCountriesMenu", sender: self)
            }
            
        case .AU, .GB, .US, .CN, .DE, .ES, .FR, .IT, .JP, .KR, .RU, .VN:
            let oldCountry = country
            
            isLatinLanguage = false
            switch (command) {
            
            case .AU:
                country = "au"
                isLatinLanguage = true

            case .GB:
                country = "gb"
                isLatinLanguage = true

            case .US:
                country = "us"
                isLatinLanguage = true

            case .DE:
                country = "de"
                isLatinLanguage = true

            case .ES:
                country = "es"
                isLatinLanguage = true

            case .FR:
                country = "fr"
                isLatinLanguage = true

            case .IT:
                country = "it"
                isLatinLanguage = true

            case .CN: country = "cn"
            case .JP: country = "jp"
            case .KR: country = "kr"
            case .RU: country = "ru"

            case .VN:
                country = "vn"
                isLatinLanguage = true
                
            default: break
            }
            
            if country != oldCountry {
                switchCountryCacheMap()
                // remove any error layer if being active
                Utility.removeErrorLayer(onController: self)
                reloadPodcastCollections()
            }
            
        case .About:
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "viewAbout", sender: self)
            }
            
        default:
            break
        }
    }
}

// MARK: Adaptive
extension CasterViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}

// MARK: segue
extension CasterViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.identifier!) {
            
        case "showMainMenu":
            if let controller = segue.destination as? MainMenuController {
                controller.delegate = self
            }
            
        case "showCountriesMenu":
            if let controller = segue.destination as? CountriesMenuController {
                controller.delegate = self
            }
            
        case "viewGenre":
            if let controller = segue.destination as? GenreViewController {
                controller.gid = selectedGenreId
            }
            
        case "viewTopPodcast":
            if let controller = segue.destination as? TopPodcastViewController {
                controller.gid = selectedGenreId
            }
            
        case "viewPodcast":
            if let controller = segue.destination as? PodcastViewController {
                controller.pid = selectedPodcastId
                controller.cachedArtwork = selectedArtwork
            }
        
        default:
            break
        }
    }
}

// MARK: -
extension CasterViewController: PodcastHeaderDelegate {
    func podcastHeader(sender: UITableViewCell, didTouchShowAllWith gid: Int) {
        selectedGenreId = gid
        // view top podcasts in that particular genre
        self.performSegue(withIdentifier: "viewTopPodcast", sender: self)
    }
}

// MARK: -
extension CasterViewController: PodcastCollectionDelegate {
    func retryCommand(sender: Any) {
        if Utility.isInternetAvailable() {
            Utility.removeErrorLayer(onController: self)
            
            // retry
            reloadPodcastCollections()
        }
    }

    func podcastCollection(_ sender: UICollectionView?, didConnectWithNetworkError error: DataFetcherErrorStyles, errorDescription: String) {
        
        DispatchQueue.main.async {
            self.stopLoadingAnimation()
        }
        
        switch (error) {
            
        case .networkNoConnection:
            DispatchQueue.main.async {
                Utility.topupErrorLayer(overController: self, errorMessage: "No Internet Connection", retryCommand: #selector(self.retryCommand(sender:)))
            }
            
            break
            
        default:
            break
        }
    }

    func podcastCollection(_ sender: UICollectionView?, didFinishLoadingCollection complete: Bool) {
        finishLoadingCount += 1
        if finishLoadingCount > genreData.features.count {
            DispatchQueue.main.async {
                self.stopLoadingAnimation()
            }
        }
    }
    
    func podcastCollection(_ sender: UICollectionView?, didSelectPodcastWithId id: Int, andCachedArtwork artwork: UIImage?) {
        selectedPodcastId = id
        selectedArtwork = artwork
        self.performSegue(withIdentifier: "viewPodcast", sender: self)
    }
}
