//
//  PodcastEntry.swift
//  Caster
//
//  Created by Alex Truong on 4/28/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import Foundation
import UIKit

class PodcastEntry {
    var id: Int?
    var title: String?
    var summary: String?
    var name: String?
    var image: String?
    var category: String?
    var artist: String?
    var rights: String?
    var content: String?

    var link: String?
    var podcastDescription: String?
    var feedUrl: String?
    var artworkUrl: String?
    var copyright: String?
    var author: String?
    var owner: String?
    var lastBuildDate: Date?
    
    convenience init(fromJSON json: [String: Any]) {
        self.init()
        // podcast info
        if let id = json["trackId"] as? Int {
            self.id = id
        }
        
        if let trackName = json["trackName"] as? String {
            self.name = trackName
        }
        
        if let artistName = json["artistName"] as? String {
            self.artist = artistName
        }
        
        if let genre = json["primaryGenreName"] as? String {
            self.category = genre
        }
        
        if let image = json["artworkUrl100"] as? String {
            self.image = image
        }
        
        if let artworkUrl = json["artworkUrl600"] as? String {
            self.artworkUrl = artworkUrl
        }
        
        if let feedUrl = json["feedUrl"] as? String {
            self.feedUrl = feedUrl
        }
    }
}
