//
//  CellEnums.swift
//  Caster
//
//  Created by Alex Truong on 4/21/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import Foundation
import UIKit

enum TableViewCellTypes: Int {
    //
    case SearchResult
    
    //
    case PodcastInfo
    case Episode
    
    //
    case NormalTopPodcast
    case FirstTopPodcast
    
    //
    case PodcastHeader
    
    //
    case Announcement
    case PodcastCollection
    case PodcastGenre
    case Banner
    
    var reuseIdentifier: String {
        switch (self) {
        case .SearchResult:
            return "SearchResultCell"
            
        case .PodcastInfo:
            return "PodcastInfoCell"
        case .Episode:
            return "EpisodeCell"
            
        case .NormalTopPodcast:
            return "NormalTopPodcastCell"
        case .FirstTopPodcast:
            return "FirstTopPodcastCell"
        
        case .PodcastHeader:
            return "PodcastHeaderCell"
        
        case .Announcement:
            return "AnnouncementCell"
        case .PodcastCollection:
            return "PodcastCollectionCell"
        case .PodcastGenre:
            return "PodcastGenreCell"
        case .Banner:
            return "BannerCell"
        }
    }
    
    var cellClass: UITableViewCell.Type {
        switch (self) {
        case .SearchResult:
            return SearchResultCell.self
            
        case .PodcastInfo:
            return PodcastInfoCell.self
        case .Episode:
            return EpisodeCell.self
            
        case .NormalTopPodcast:
            return NormalTopPodcastCell.self
        case .FirstTopPodcast:
            return FirstTopPodcastCell.self
        
        case .PodcastHeader:
            return PodcastHeaderCell.self
        
        case .Announcement:
            return AnnouncementCell.self
        case .PodcastCollection:
            return PodcastCollectionCell.self
        case .PodcastGenre:
            return PodcastGenreCell.self
        case .Banner:
            return BannerCell.self
        }
    }
}

enum CollectionViewCellTypes: Int {
    case Podcast
    
    var reuseIdentifier: String {
        switch (self) {
        case .Podcast:
            return "PodcastCell"
        }
    }
    
    var cellClass: UICollectionViewCell.Type {
        switch (self) {
        case .Podcast:
            return PodcastCell.self
        }
    }
}
