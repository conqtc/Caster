//
//  PodcastCollectionCell.swift
//  Caster
//
//  Created by Alex Truong on 4/18/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

protocol PodcastCollectionDelegate: class {
    func podcastCollection(_ sender: UICollectionView?, didSelectPodcastWithId id: Int, andCachedArtwork artwork: UIImage?)
    func podcastCollection(_ sender: UICollectionView?, didFinishLoadingCollection complete: Bool)
    func podcastCollection(_ sender: UICollectionView?, didConnectWithNetworkError error: DataFetcherErrorStyles, errorDescription: String)
}

class PodcastCollectionCell: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var numberOfPodcasts = 36
    var numberOfRows: Int = 1
    var numberOfCols: Int = 3

    var dimension: NSLayoutConstraint? = nil
    var delegate: PodcastCollectionDelegate?
    
    var gid: Int = -1 {
        didSet {
            DispatchQueue.global(qos: .userInitiated).async {
                self.dataFetcher.fetchTopPodcasts(gid: self.gid)
            }
        }
    }
    
    var podcastList = [PodcastEntry]()
    var artworkList = [UIImage?]()
    var inProgress = [Int: Operation]()
    let dataFetcher = DataFetcher()
    
    lazy var artworkLoaderQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "PodcastCollectionArtworkLoaderOperationQueue\(self.gid)"
        queue.maxConcurrentOperationCount = 18
        return queue
    }()

    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        
        collectionView.register(UINib(nibName: CollectionViewCellTypes.Podcast.reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: CollectionViewCellTypes.Podcast.reuseIdentifier)
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        dataFetcher.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setCollectionDimension(numberOfRows: Int, numberOfCols: Int) {
        self.numberOfRows = numberOfRows
        self.numberOfCols = numberOfCols
        
        let scale = (3.0 * CGFloat(numberOfCols)) / (4.5 * CGFloat(numberOfRows))
        
        // remove old dimension
        if let constraint = self.dimension {
            collectionView.removeConstraint(constraint)
        }
        
        // apply new dimension
        dimension = NSLayoutConstraint(item: collectionView, attribute: .width, relatedBy: .equal, toItem: collectionView, attribute: .height, multiplier: scale, constant: 0.0)
        collectionView.addConstraint(dimension!)
    }
}

// MARK:
extension PodcastCollectionCell: DataFetcherDelegate {
    func dataFetcher(_ fetcher: DataFetcher, didConnectWithNetworkError error: DataFetcherErrorStyles, errorDescription: String) {
        self.delegate?.podcastCollection(self.collectionView, didConnectWithNetworkError: error, errorDescription: errorDescription)
    }
    
    func dataFetcher(_ fetcher: DataFetcher, didFinishSearchWithResult entries: [PodcastEntry]?) {
    }

    func dataFetcher(_ : DataFetcher, didFetchTopPodcastsForGenreId id: Int) {
        podcastList.removeAll()
        artworkList.removeAll()
        
        if let podcastList = dataFetcher.topPodcastList {
            self.podcastList = podcastList
            
            // load artworks
            let count = podcastList.count < numberOfPodcasts ? podcastList.count : numberOfPodcasts
            artworkList = Array(repeating: defaultArtwork, count: count)
            for index in 0..<count {
                let podcast = podcastList[index]
                let id = podcast.id!
                
                // try to load from cached file
                if let image = Utility.loadArtworkFromFile(withId: id) {
                    artworkList[index] = image
                } else {
                    // vigorously load artworks
                    /*
                    let imageLoader = ImageLoaderOperation(url: podcast.image)
                    imageLoader.completionBlock = {
                        if let image = imageLoader.image {
                            self.artworkList[index] = image
                            self.updateArtworkForCell(withIndexPath: IndexPath(item: index, section: 0), artwork: image)
                        }
                        self.inProgress[index] = nil
                    }
                    inProgress[index] = imageLoader
                    artworkLoaderQueue.addOperation(imageLoader)
                    */
                }
            }
        }

        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        delegate?.podcastCollection(collectionView, didFinishLoadingCollection: true)
    }
}

// MARK:
extension PodcastCollectionCell: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return podcastList.count < numberOfPodcasts ? podcastList.count : numberOfPodcasts
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionViewCellTypes.Podcast.reuseIdentifier, for: indexPath) as! PodcastCell
        
        let index = indexPath.item
        cell.title = podcastList[index].name ?? ""
        cell.author = podcastList[index].artist ?? ""
        cell.artworkView.image = artworkList[index]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let index = indexPath.item
        
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
    
    func updateArtworkForCell(withIndexPath indexPath: IndexPath, artwork: UIImage?) {
        DispatchQueue.main.async {
            if let cell = self.collectionView.cellForItem(at: indexPath) as? PodcastCell {
                cell.artworkView.image = artwork
                UIView.transition(with: cell.artworkView,
                                  duration: 0.3,
                                  options: .transitionCrossDissolve,
                                  animations: { cell.artworkView.image = artwork },
                                  completion: nil)
            }
        }
        
    }

}

extension PodcastCollectionCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        
        let width = UIScreen.main.bounds.size.width / CGFloat(numberOfCols)
        
        return CGSize(width: width, height: 4.5 * width / 3.0 - 0.1 )
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.podcastCollection(self.collectionView, didSelectPodcastWithId: podcastList[indexPath.item].id!, andCachedArtwork: artworkList[indexPath.item])
    }
}
