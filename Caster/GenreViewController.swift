//
//  GenreViewController.swift
//  Caster
//
//  Created by Alex Truong on 4/20/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class GenreViewController: StretchableHeaderTableViewController {
    
    var gid: Int = 0
    var genre: PodcastGenre!
    
    var selectedGenreId: Int = 0
    var selectedPodcastId: Int = 0
    var selectedArtwork: UIImage?
    var needsReloadCollection = false
    
    var sections = [(id: Int, cellType: TableViewCellTypes, title: String, numberOfRows: Int)]()
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
    var loadingView: UIView?
    
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
        
        registerCellTypesFromNibs()
        
        self.headerHeight = 200
        tableView.estimatedRowHeight = 32
        tableView.rowHeight = UITableViewAutomaticDimension
        
        genre = genreData.map[gid]!
        sections.append((0, TableViewCellTypes.PodcastCollection, "Top Podcasts", 1))
        sections.append((1000, TableViewCellTypes.PodcastGenre, "Sub Genres", genre.subGenres.count))
        
        navigationItem.title = genre.title
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        startLoadingAnimation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        stopLoadingAnimation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func registerCellTypesFromNibs() {
        let cellTypes = [
            TableViewCellTypes.PodcastGenre,
            TableViewCellTypes.PodcastHeader,
            TableViewCellTypes.PodcastCollection
            ]
        
        for cell in cellTypes {
            tableView.register(UINib(nibName: cell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }
    
    // MARK: - table view
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
            
            headerCell.gid = gid
            headerCell.delegate = self
            
            return headerCell
            
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellType = sections[indexPath.section].cellType
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellType.reuseIdentifier, for: indexPath)
        
        switch (cellType) {
            
        case .PodcastCollection:
            let podcastCollectionCell = cell as! PodcastCollectionCell
            
            if podcastCollectionCell.gid != sections[indexPath.section].id || needsReloadCollection {
                podcastCollectionCell.gid = gid
                podcastCollectionCell.setCollectionDimension(numberOfRows: 3, numberOfCols: 3)
                podcastCollectionCell.delegate = self
            }
            return podcastCollectionCell
            
        case .PodcastGenre:
            let genreCell = cell as! PodcastGenreCell
            genreCell.accessoryType = .disclosureIndicator
            genreCell.genreTitle = genre.subGenres[indexPath.row].title
            return genreCell
            
        default:
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellType = sections[indexPath.section].cellType
        
        if cellType == TableViewCellTypes.PodcastGenre {
            selectedGenreId = genre.subGenres[indexPath.row].id
            // view top podcasts in that particular genre
            performSegue(withIdentifier: "viewTopPodcast", sender: self)
        }
    }
}

// MARK: segue
extension GenreViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.identifier!) {

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

extension GenreViewController: PodcastHeaderDelegate {
    func podcastHeader(sender: UITableViewCell, didTouchShowAllWith gid: Int) {
        selectedGenreId = gid
        // view top podcasts in that particular genre
        performSegue(withIdentifier: "viewTopPodcast", sender: self)
    }
}


extension GenreViewController: PodcastCollectionDelegate {
    func retryCommand(sender: Any) {
        if Utility.isInternetAvailable() {

            Utility.removeErrorLayer(onController: self)
            
            // retry
            needsReloadCollection = true
            startLoadingAnimation()
            self.tableView.reloadData()
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
        DispatchQueue.main.async {
            self.stopLoadingAnimation()
        }
    }
    
    func podcastCollection(_ sender: UICollectionView?, didSelectPodcastWithId id: Int, andCachedArtwork artwork: UIImage?) {
        selectedPodcastId = id
        selectedArtwork = artwork
        performSegue(withIdentifier: "viewPodcast", sender: self)
    }
}
