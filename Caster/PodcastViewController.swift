//
//  PodcastViewController.swift
//  Caster
//
//  Created by Alex Truong on 4/20/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class PodcastViewController: StretchableHeaderTableViewController {
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var artworkCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundImageView: UIImageView!

    var pid: Int = 0
    var cachedArtwork: UIImage?
    var podcastEntry: PodcastEntry?
    var selectedEpisode: EpisodeItem?
    var episodeList: [EpisodeItem]?
    // for podcast info
    var podcastAttributedText: NSMutableAttributedString?
    // for episode info
    var episodeAttributedText: NSMutableAttributedString?
    let dataFetcher = DataFetcher()
    
    lazy var infoLoaderQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "PodcastInfoLoaderQueue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    lazy var artworkDownloadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "PodcastArtworkDownloadQueue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    lazy var slideInTransitioningDelegate = SlideInTransitioningDelegate(direction: .top, animation: .animationSpringWithDamping)
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
    
    func startLoadingAnimation() {
        activityIndicator.backgroundColor = Theme.primaryColor
        activityIndicator.layer.cornerRadius = 5.0
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        activityIndicator.center = tableView.center
        tableView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    func stopLoadingAnimation() {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // register for 3D touch
        if (traitCollection.forceTouchCapability == .available) {
            registerForPreviewing(with: self, sourceView: self.tableView)
        }
        
        registerCellTypesFromNibs()
        
        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableViewAutomaticDimension
        podcastEntry = podcastMap[pid]
        navigationItem.title = podcastEntry?.name ?? ""
        artworkImageView.image = cachedArtwork
        backgroundImageView.image = cachedArtwork
        
        // set tint colot for the bars
        cachedArtwork?.getColors(scaleDownSize: CGSize(width: 100, height: 100)) { artworkColors in
            var origin = artworkColors.backgroundColor
            // too bright or too dark?
            var brightness = origin!.luminancePerceived
            if brightness > 0.9 || brightness < 0.1 {
                // switch to primary color
                origin = artworkColors.primaryColor
                // too bright or too dark?
                brightness = origin!.luminancePerceived
                if brightness > 0.9 || brightness < 0.1 {
                    // switch to detail
                    origin = artworkColors.detailColor
                    // too bright or too dark?
                    brightness = origin!.luminancePerceived
                    if brightness > 0.9 || brightness < 0.1 {
                        // switch to secondary
                        origin = artworkColors.secondaryColor
                    }
                }
            }
            
            var color = origin
            // gradually make it lighter until light enough
            var percent: CGFloat = 10
            for _ in 0..<5 {
                self.tintColor = color!
                // still dark?
                if color!.luminancePerceived < 0.5 {
                    color = origin!.lighter(by: percent)
                } else { break }
                percent += 10
            }
        }
        
        // disable "more" button
        enableMoreButton(enable: false)
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PodcastInfoCell {
            cell.delegate = self
        }

        // start lookup podcast info
        lookupPodcastInfo()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func enableMoreButton(enable: Bool = true) {
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PodcastInfoCell {
            cell.moreButton.isEnabled = enable
        }
    }
    
    func lookupPodcastInfo() {
        // try to load artwork from file
        var needsDownloadArtwork = false
        if let image = Utility.loadArtworkFromFile(withId: pid) {
            cachedArtwork = image
            artworkImageView.image = image
            backgroundImageView.image = image
        } else {
            needsDownloadArtwork = true
        }
        
        let lookUpOperation = LookUpPodcastOperation(withPodcastId: pid)
        lookUpOperation.completionBlock = {
            // map json data
            if let json = lookUpOperation.response?.json {
                if let count = json["resultCount"] as? Int, count > 0 {
                    if let results = json["results"] as? [[String: Any]] {
                        let _ = self.dataFetcher.mapPodcast(pid: self.pid, json: results[0])
                    }
                }
            }
        }

        let downloadOperation = DownloadArtworkOperation(withPodcastId: pid)
        downloadOperation.completionBlock = {
            // reload image after download
            if let image = Utility.loadArtworkFromFile(withId: self.pid) {
                DispatchQueue.main.async {
                    self.cachedArtwork = image
                    self.artworkImageView.image = image
                    self.backgroundImageView.image = image
                }
            }
        }
        // start
        startLoadingAnimation()
        DispatchQueue.global(qos: .userInitiated).async {
            // lookup json info
            self.infoLoaderQueue.addOperation(lookUpOperation)
            self.infoLoaderQueue.waitUntilAllOperationsAreFinished()
            
            // start downloading artwork if needed
            if needsDownloadArtwork {
                self.artworkDownloadQueue.addOperation(downloadOperation)
            }

            // check if we should download/redownload feed xml
            let checkModifiedOperation = CheckLastModifiedOperation(forPodcast: self.pid)
            self.infoLoaderQueue.addOperation(checkModifiedOperation)
            self.infoLoaderQueue.waitUntilAllOperationsAreFinished()
            
            // parse feed xml file, re/download if needed
            let parseFeedOperation = ParseFeedOperation(forPodcast: self.pid, needsDownload: checkModifiedOperation.needsDownloadFeed)
            parseFeedOperation.completionBlock = {
                self.dataFetcher.mapPodcast(pid: self.pid, info: parseFeedOperation.info)
                self.episodeList = parseFeedOperation.items
                
                DispatchQueue.main.async {
                    self.stopLoadingAnimation()
                    self.tableView.reloadData()
                }
                
                self.prepareAttributedString()
            }
            
            self.infoLoaderQueue.addOperation(parseFeedOperation)
        }
    }
    
    func prepareAttributedString() {
        DataFetcher.fetchPodcastAttributedString(podcast: self.podcastEntry, preferWhite: false) { attributedText in
            if let attributedText = attributedText {
                self.podcastAttributedText = attributedText
                DispatchQueue.main.async {
                    self.enableMoreButton()
                }
            }
        }
    }
    
    func registerCellTypesFromNibs() {
        // First line
        let cellTypes = [
            TableViewCellTypes.PodcastInfo,
            TableViewCellTypes.Episode
        ]
        
        for cell in cellTypes {
            tableView.register(UINib(nibName: cell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 1 {
            return kNowPlayingBarHeight
        } else {
            return CGFloat.leastNormalMagnitude
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            if let episodeList = self.episodeList {
                return episodeList.count
            } else {
                return 0
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "INFORMATION"
        } else {
            return "EPISODES"
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }
    
    func configurePodcastInfo(cell: PodcastInfoCell, info: PodcastEntry) {
        var infoText = ""
        
        /*
         if let text = info.artist {
         infoText.append("Artist: \(text)\n")
         }
         */
        
        if let text = info.summary?.plainText(), !text.isEmpty {
            infoText.append("\(text)")
        } else if let text = info.podcastDescription?.plainText(), !text.isEmpty {
            infoText.append("\(text)")
        }
        
        cell.infoLabel.text = infoText
    }
    
    func configureEpisodeInfo(cell: EpisodeCell, info: EpisodeItem) {
        cell.titleLabel.text = info.title?.plainText() ?? ""
        
        if let text = info.itemDescription?.plainText(), !text.isEmpty {
            cell.subtitleLabel.text = text
        } else {
            cell.subtitleLabel.text = info.summary?.plainText() ?? ""
        }
        
        cell.dateLabel.text = info.pubDate?.toString(withFormat: "EEE d\nMMM")
        if let text = info.duration, let duration = Utility.normalizeEpisodeDuration(text) {
            cell.timeLabel.text = duration
        } else if let time = info.pubDate?.toString(withFormat: "HH:mm") {
            cell.timeLabel.text = "at \(time)"
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellTypes.PodcastInfo.reuseIdentifier, for: indexPath) as! PodcastInfoCell
            
            if let info = podcastEntry {
                configurePodcastInfo(cell: cell, info: info)
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellTypes.Episode.reuseIdentifier, for: indexPath) as! EpisodeCell
            
            if let info = episodeList?[indexPath.row] {
                configureEpisodeInfo(cell: cell, info: info)
            }
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            selectedEpisode = episodeList?[indexPath.row]
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "viewEpisode", sender: self)
            }
        }
    }
    
    // MARK: - Stretchable header
    override func tableViewDidPull(withOffset offset: CGFloat) {
        if offset < 0 {
            // pull down
            artworkImageView.alpha = 1.0
            artworkCenterYConstraint.constant = -10
        } else {
            // pull up
            var alpha: CGFloat = offset / self.headerHeight
            alpha = alpha > 1.0 ? 1.0 : alpha
            alpha = 1.0 - alpha
            artworkImageView.alpha = alpha
            artworkCenterYConstraint.constant = offset / 3 - 10
        }
    }
}

extension PodcastViewController: UIViewControllerPreviewingDelegate {
    // peek
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView.indexPathForRow(at: location) else { return nil }
        guard let cell = self.tableView.cellForRow(at: indexPath) else { return nil }

        previewingContext.sourceRect = cell.frame
        let size = self.view.bounds.size
        
        if indexPath.section > 0 {
            guard let controller = storyboard?.instantiateViewController(withIdentifier: "EpisodeViewController") as? EpisodeViewController else { return nil }
            
            controller.artwork = cachedArtwork
            selectedEpisode = episodeList?[indexPath.row]
            controller.currentEpisode = selectedEpisode
            controller.delegate = self
            
            controller.preferredContentSize = CGSize(width: size.width, height: 450)
            
            return controller
        } else {
            guard let controller = storyboard?.instantiateViewController(withIdentifier: "PodcastPeekController") as? PodcastPeekController else { return nil }
            
            controller.artwork = self.cachedArtwork
            controller.currentPodcast = self.podcastEntry
            controller.preferredContentSize = CGSize(width: size.width, height: 500)
            
            return controller
        }
    }
    
    // pop
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        showDetailViewController(viewControllerToCommit, sender: self)
    }

}

// MARK: -
extension PodcastViewController: EpisodeDelegate {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? NowPlayingViewController {
            controller.artwork = cachedArtwork
            controller.attributedText = episodeAttributedText
            controller.currentEpisode = selectedEpisode
            controller.currentPodcast = podcastEntry
            controller.delegate = self
                        
            // TODO: to be replaced
            mediaPlayer.abandonCurrentPlayerItem()
        } else if let controller = segue.destination as? EpisodeViewController {
            controller.artwork = cachedArtwork
            controller.currentEpisode = selectedEpisode
            controller.delegate = self
        }
    }
    
    func episode(_ sender: EpisodeViewController, didDismissAndStream willStream: Bool, withAttributedText attributedText: NSMutableAttributedString?) {
        self.episodeAttributedText = attributedText
        
        if willStream {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "viewNowPlaying", sender: self)
            }
        }
    }
}


// MARK: -
extension PodcastViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}

// MARK: -
extension PodcastViewController: PodcastInfoDelegate {
    func podcastInfo(didTouchMoreInCell sender: UIButton) {
        if let controller = storyboard?.instantiateViewController(withIdentifier: "PodcastDetailController") as? PodcastDetailController {
            
            controller.attributedString = self.podcastAttributedText
            
            let size = self.view.bounds.size
            controller.preferredContentSize = CGSize(width: size.width, height: size.height * 0.6)
            controller.modalPresentationStyle = .popover
            
            if let popover = controller.popoverPresentationController {
                popover.delegate = self
                popover.permittedArrowDirections = [.up, .down]

                let source = sender
                popover.sourceRect = source.bounds
                popover.sourceView = source
                
                //popover.popoverBackgroundViewClass = SleekPopoverBackgroundView.self
            }

            present(controller, animated: false)
        }
    }
}

