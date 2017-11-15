//
//  TopPodcastViewController.swift
//  Caster
//
//  Created by Alex Truong on 4/20/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class TopPodcastViewController: AlphaBarsTableViewController {
    
    var gid: Int = 0
    var podcastList = [PodcastEntry]()
    var artworkList = [UIImage?]()
    var inProgress = [Int: Operation]()
    var dataFetcher = DataFetcher()

    var selectedPodcastId = 0
    var selectedArtwork: UIImage?
    
    var isRefreshing = false
    
    lazy var artworkLoaderQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "ArtworkLoaderOperationQueue"
        queue.maxConcurrentOperationCount = 18
        return queue
    }()

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
        self.alpha = 1.0
        
        registerCellTypesFromNibs()
        
        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableViewAutomaticDimension
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        self.refreshControl?.addTarget(self, action: #selector(refreshTable(refreshControl:)), for: .valueChanged)

        if gid > 0 {
            let genre = genreData.map[gid]!
            navigationItem.title = genre.title
        } else {
            navigationItem.title = "Top Podcasts"
        }

        startLoadingAnimation()
        
        // load real data
        dataFetcher.delegate = self
        DispatchQueue.global(qos: .userInitiated).async {
            self.dataFetcher.fetchTopPodcasts(gid: self.gid)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationBar.backgroundColor = tintColor
        UIApplication.shared.setStatusBarBackgroundColor(color: tintColor)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func registerCellTypesFromNibs() {
        let cellTypes = [
            TableViewCellTypes.FirstTopPodcast,
            TableViewCellTypes.NormalTopPodcast
        ]
        
        for cell in cellTypes {
            tableView.register(UINib(nibName: cell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }
    
    func refreshTable(refreshControl: UIRefreshControl) {
        isRefreshing = true
        DispatchQueue.global(qos: .userInitiated).async {
            self.dataFetcher.fetchTopPodcasts(gid: self.gid, shouldUseCache: false)
        }
    }
}

// MARK:
extension TopPodcastViewController: DataFetcherDelegate {
    func retryCommand(sender: Any) {
        if Utility.isInternetAvailable() {
            Utility.removeErrorLayer(onController: self)

            // retry
            startLoadingAnimation()
            DispatchQueue.global(qos: .userInitiated).async {
                self.dataFetcher.fetchTopPodcasts(gid: self.gid)
            }
        }
    }
    
    func dataFetcher(_ fetcher: DataFetcher, didConnectWithNetworkError error: DataFetcherErrorStyles, errorDescription: String) {
        
        switch (error) {
            
        case .networkNoConnection:
            DispatchQueue.main.async {
                if self.isRefreshing {
                    self.isRefreshing = false
                    self.refreshControl?.endRefreshing()
                    
                    return
                } else {
                    self.stopLoadingAnimation()
                }
                Utility.topupErrorLayer(overController: self, errorMessage: "No Internet Connection", retryCommand: #selector(self.retryCommand(sender:)))
            }
            
            break
            
        default:
            break
        }
    }

    func dataFetcher(_ fetcher: DataFetcher, didFinishSearchWithResult entries: [PodcastEntry]?) {
    }
    
    func dataFetcher(_: DataFetcher, didFetchTopPodcastsForGenreId id: Int) {
        podcastList.removeAll()
        artworkList.removeAll()
        
        if let podcastList = dataFetcher.topPodcastList {
            self.podcastList = podcastList
            // load artworks
            artworkList = Array(repeating: defaultArtwork, count: podcastList.count)
            for index in 0..<podcastList.count {
                let podcast = podcastList[index]
                let id = podcast.id!

                // try to load from cached file
                if let image = Utility.loadArtworkFromFile(withId: id) {
                    artworkList[index] = image
                }
            }
        }
        
        DispatchQueue.main.async {
            if self.isRefreshing {
                self.isRefreshing = false
                self.refreshControl?.endRefreshing()
            } else {
                self.stopLoadingAnimation()
            }
            self.tableView.reloadData()
        }
    }
}

// MARK:
extension TopPodcastViewController {
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return kNowPlayingBarHeight
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return podcastList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.row) {
        
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellTypes.FirstTopPodcast.reuseIdentifier, for: indexPath) as! FirstTopPodcastCell

            let index = indexPath.row
            
            cell.titleLabel.text = podcastList[index].name ?? ""
            cell.authorLabel.text = podcastList[index].artist ?? ""
            cell.artworkImageView.image = artworkList[index]

            return cell
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellTypes.NormalTopPodcast.reuseIdentifier, for: indexPath) as! NormalTopPodcastCell

            let index = indexPath.row
            
            cell.numberLabel.text = "\(index + 1)"
            cell.titleLabel.text = podcastList[index].name ?? ""
            cell.authorLabel.text = podcastList[index].artist ?? ""
            cell.artworkImageView.image = artworkList[index]
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPodcastId = podcastList[indexPath.row].id!
        selectedArtwork = artworkList[indexPath.row]
        performSegue(withIdentifier: "viewPodcast", sender: self)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let index = indexPath.row

        if artworkList[index] == defaultArtwork, inProgress[index] == nil {
            let imageLoader = LoadArtworkThumbnailOperation(forPodcast: podcastList[index].id!)
            imageLoader.completionBlock = {
                if let image = imageLoader.image {
                    self.artworkList[index] = image
                    self.updateArtworkForCell(withIndexPath: indexPath, artwork: image)
                }
                self.inProgress[index] = nil
            }
            inProgress[index] = imageLoader
            artworkLoaderQueue.addOperation(imageLoader)
        }
    }
}

extension TopPodcastViewController {
    func updateArtworkForCell(withIndexPath indexPath: IndexPath, artwork: UIImage?) {
        DispatchQueue.main.async {
            let cell = self.tableView.cellForRow(at: indexPath)
            
            if let firstCell = cell as? FirstTopPodcastCell {
                UIView.transition(with: firstCell.artworkImageView,
                                  duration: 0.3,
                                  options: .transitionCrossDissolve,
                                  animations: { firstCell.artworkImageView.image = artwork },
                                  completion: nil)
            } else if let normalCell = cell as? NormalTopPodcastCell {
                UIView.transition(with: normalCell.artworkImageView,
                                  duration: 0.3,
                                  options: .transitionCrossDissolve,
                                  animations: { normalCell.artworkImageView.image = artwork },
                                  completion: nil)
            }
        }

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.identifier!) {
            
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
