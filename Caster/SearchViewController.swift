//
//  SearchViewController.swift
//  Caster
//
//  Created by Alex Truong on 5/6/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class SearchViewController: AlphaBarsTableViewController {
    
    var searchBar: UISearchBar?
    var searchActive: Bool = false
    
    var podcastList = [PodcastEntry]()
    var artworkList = [UIImage?]()
    var inProgress = [Int: Operation]()
    var dataFetcher = DataFetcher()
    
    var selectedPodcastId = 0
    var selectedArtwork: UIImage?
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
    var loadingView: UIView?
    
    lazy var artworkLoaderQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "SearchArtworkLoaderOperationQueue"
        queue.maxConcurrentOperationCount = 18
        return queue
    }()
    
    func startLoadingAnimation() {
        activityIndicator.backgroundColor = Theme.primaryColor
        activityIndicator.layer.cornerRadius = 5.0
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        
        if loadingView == nil {
            loadingView = UIView()
            loadingView?.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
            loadingView?.addSubview(activityIndicator)
        }
        
        loadingView?.frame = tableView.bounds
        activityIndicator.center.x = loadingView!.center.x
        activityIndicator.center.y = loadingView!.frame.height / 2
        
        tableView.isScrollEnabled = false
        tableView.addSubview(loadingView!)
        activityIndicator.startAnimating()
    }
    
    func stopLoadingAnimation() {
        activityIndicator.stopAnimating()
        loadingView?.removeFromSuperview()
        tableView.isScrollEnabled = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.alpha = 1.0
        
        registerCellTypesFromNibs()
        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableViewAutomaticDimension
        
        searchBar = UISearchBar()
        searchBar?.barStyle = .default
        searchBar?.placeholder = "Search podcast"
        searchBar?.delegate = self
        searchBar?.sizeToFit()
        searchBar?.becomeFirstResponder()
        
        navigationItem.titleView = searchBar
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        dataFetcher.delegate = self
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
            TableViewCellTypes.SearchResult
        ]
        
        for cell in cellTypes {
            tableView.register(UINib(nibName: cell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
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
        let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellTypes.SearchResult.reuseIdentifier, for: indexPath) as! SearchResultCell
        
        let index = indexPath.row

        cell.titleLabel.text = podcastList[index].name ?? ""
        cell.descLabel.text = podcastList[index].artist ?? ""
        cell.artworkImageView.image = artworkList[index]
        
        return cell
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPodcastId = podcastList[indexPath.row].id!
        selectedArtwork = artworkList[indexPath.row]
        performSegue(withIdentifier: "viewPodcast", sender: self)
    }


    // MARK: - Navigation
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
    
    func updateArtworkForCell(withIndexPath indexPath: IndexPath, artwork: UIImage?) {
        DispatchQueue.main.async {
            if let cell = self.tableView.cellForRow(at: indexPath) as? SearchResultCell {
                UIView.transition(with: cell.artworkImageView,
                                  duration: 0.3,
                                  options: .transitionCrossDissolve,
                                  animations: { cell.artworkImageView.image = artwork },
                                  completion: nil)
            }
        }
        
    }

}

extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchActive {
            return
        }
        
        if let searchText = searchBar.text {
            let encodedText = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            searchBar.endEditing(true)

            // remove any error layer if being active
            Utility.removeErrorLayer(onController: self)
            
            startLoadingAnimation()
            searchActive = true
            DispatchQueue.global(qos: .userInitiated).async {
                self.dataFetcher.searchPodcasts(text: encodedText!)
            }
        }
    }
}

extension SearchViewController: DataFetcherDelegate {
    func retryCommand(sender: Any) {
        if Utility.isInternetAvailable() {
            Utility.removeErrorLayer(onController: self)
            // retry
            searchBarSearchButtonClicked(self.searchBar!)
        }
    }
    
    func dataFetcher(_ fetcher: DataFetcher, didConnectWithNetworkError error: DataFetcherErrorStyles, errorDescription: String) {
        
        searchActive = false
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
    
    func dataFetcher(_ fetcher: DataFetcher, didFinishSearchWithResult entries: [PodcastEntry]?) {
        podcastList.removeAll()
        artworkList.removeAll()

        if let podcastList = entries {
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
            self.stopLoadingAnimation()
            self.tableView.reloadData()
        }
        
        searchActive = false
    }
    
    func dataFetcher(_ fetcher: DataFetcher, didFetchTopPodcastsForGenreId id: Int) {
    }    
}
