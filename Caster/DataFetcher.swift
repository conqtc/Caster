//
//  DataModel.swift
//  Caster
//
//  Created by Alex Truong on 4/24/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import Foundation
import UIKit

enum DataFetcherErrorStyles {
    case networkNoConnection
    case networkConnectionInterrupted
    
    case parserUnableToParseXML
    case parserNoItemFoundInXML
    
    case parserUnableToParseJSON
    case parserNoItemFoundInJSON
}

protocol DataFetcherDelegate: class {
    func dataFetcher(_ fetcher: DataFetcher, didFetchTopPodcastsForGenreId id: Int)
    func dataFetcher(_ fetcher: DataFetcher, didFinishSearchWithResult entries: [PodcastEntry]?)
    
    // error handling
    func dataFetcher(_ fetcher: DataFetcher, didConnectWithNetworkError error: DataFetcherErrorStyles, errorDescription: String)
}

class DataFetcher: NSObject {
    var topPodcastList: [PodcastEntry]?
    var delegate: DataFetcherDelegate?
}

// MARK:
extension DataFetcher {
    
    func searchPodcasts(text: String) {
        let searchURL = "https://itunes.apple.com/search?term=\(text)&country=\(country)&entity=podcast"
        
        if let url = URL(string: searchURL) {
            NetCaster.requestJSON(url: url) { response in
                if let error = response.error {
                    self.delegate?.dataFetcher(self, didConnectWithNetworkError: DataFetcherErrorStyles.networkNoConnection, errorDescription: error.localizedDescription)
                } else if let json = response.json {
                    var podcastList = [PodcastEntry]()
                    if let count = json["resultCount"] as? Int, count > 0 {
                        if let results = json["results"] as? [[String: Any]] {
                            for result in results {
                                podcastList.append(self.mapPodcast(json: result))
                            }
                        }
                    } else {
                        // TODO: nothing found
                    }
                    
                    self.delegate?.dataFetcher(self, didFinishSearchWithResult: podcastList)
                }
            }
        }
    }
    
    func fetchTopPodcastsLocally(from fileURL: URL, forGenreId gid: Int) {
        if let parser = iTunesFeedParser(withUrl: fileURL) {
            parser.parseAsync() { entries in
                if let entries = entries {
                    self.topPodcastList = entries
                    
                    for index in 0..<entries.count {
                        self.topPodcastList?[index] = self.mapPodcast(entry: entries[index])
                    }
                    
                    topPodcastListMap[gid] = self.topPodcastList
                } else {
                    // error while parsing the local file
                }
                
                self.delegate?.dataFetcher(self, didFetchTopPodcastsForGenreId: gid)
            }
        } else {
            // unable to initiate feed parser with local file
            // TODO: just for safety, needs to be removed
            self.delegate?.dataFetcher(self, didFetchTopPodcastsForGenreId: gid)
        }
    }
    
    // MARK: fetch and save top xml file
    func fetchTopPodcasts(gid: Int, limit: Int = 100, shouldUseCache: Bool = true) {
        var topUrl = ""
        
        if gid > 0 {
            topUrl = "https://itunes.apple.com/\(country)/rss/toppodcasts/limit=\(limit)/genre=\(gid)/xml"
        } else {
            topUrl = "https://itunes.apple.com/\(country)/rss/toppodcasts/limit=\(limit)/xml"
        }

        // check if local file exist
        let fileURL = Utility.fileUrl(for: "\(country)\(gid)")

        if shouldUseCache {
            if let list = topPodcastListMap[gid] {
                topPodcastList = list
                delegate?.dataFetcher(self, didFetchTopPodcastsForGenreId: gid)
                
                return
            } else if FileManager.default.fileExists(atPath: fileURL.path) {
                fetchTopPodcastsLocally(from: fileURL, forGenreId: gid)
                
                return
            }
        }
        
        // no cache, download it
        NetCaster.download(url: URL(string: topUrl)!, to: fileURL) { response in
            // check error and status code
            if let error = response.error {
                self.delegate?.dataFetcher(self,
                    didConnectWithNetworkError: .networkNoConnection,
                    errorDescription: error.localizedDescription)
            } else {
                self.fetchTopPodcastsLocally(from: fileURL, forGenreId: gid)
            }
        }
    }
}

// MARK: - mapping for caching
extension DataFetcher {
    
    // map podcast with info after parsing feed's url
    func mapPodcast(pid: Int, info: PodcastEntry?) {
        if let podcast = podcastMap[pid] {
            // update only if there's new value, otherwise assign to itself (unchanged)
            podcast.summary = info?.summary ?? podcast.summary
            podcast.link = info?.link ?? podcast.link
            podcast.podcastDescription = info?.podcastDescription ?? podcast.podcastDescription
            podcast.lastBuildDate = info?.lastBuildDate ?? podcast.lastBuildDate
            podcast.copyright = info?.copyright ?? podcast.copyright
            podcast.author = info?.author ?? podcast.author
            // only change category if not yet set
            podcast.category = podcast.category ?? info?.category
        } else {
            // TODO: ?
        }
    }
    
    // map podcast with json data after search
    func mapPodcast(json: [String: Any]) -> PodcastEntry {

        if let id = json["trackId"] as? Int {
            if let podcast = podcastMap[id] {
                // TODO: update this
                if let genre = json["primaryGenreName"] as? String {
                    podcast.category = genre
                }
                
                if let artworkUrl = json["artworkUrl600"] as? String {
                    podcast.artworkUrl = artworkUrl
                }
                
                if let feedUrl = json["feedUrl"] as? String {
                    podcast.feedUrl = feedUrl
                }

                return podcast
            }
        }
        
        let newEntry = PodcastEntry(fromJSON: json)
        if let id = newEntry.id {
            podcastMap[id] = newEntry
        }
        
        return newEntry
    }

    // map podcast with entry data after parsing top's list
    func mapPodcast(entry: PodcastEntry) -> PodcastEntry {
        if let id = entry.id {
            if let podcast = podcastMap[id] {
                // update this podcast only when it is null
                podcast.title = podcast.title ?? entry.title
                podcast.name = podcast.name ?? entry.name
                podcast.artist = podcast.artist ?? entry.artist
                podcast.content = podcast.content ?? entry.content
                podcast.summary = podcast.summary ?? entry.summary
                podcast.rights = podcast.rights ?? entry.rights
                podcast.image = podcast.image ?? entry.image
                
                // re-fixate category
                podcast.category = entry.category ?? podcast.category
                
                return podcast
            }
            
            podcastMap[id] = entry
        }
        
        return entry
    }
    
    // map podcast with json data after looking up
    func mapPodcast(pid: Int, json: [String: Any]) -> PodcastEntry {
        if let entry = podcastMap[pid] {
            // artwork url
            if let artworkUrl = json["artworkUrl600"] as? String {
                entry.artworkUrl = artworkUrl
            }
            // feed url
            if let feedUrl = json["feedUrl"] as? String {
                entry.feedUrl = feedUrl
            }
            
            return entry
        } else {
            // create a new one
            let newEntry = PodcastEntry(fromJSON: json)
            podcastMap[pid] = newEntry
            
            return newEntry
        }
    }
}

// MARK: -
extension DataFetcher {
    static func fetchPodcastAttributedString(podcast: PodcastEntry?, preferWhite: Bool, completionHandler: @escaping (NSMutableAttributedString?) -> Void) {

        var infoText = ""
        
        if let podcast = podcast {
            DispatchQueue.global(qos: .userInitiated).async {
                // name/title
                if let text = podcast.name {
                    infoText.append("<h3>\(text)</h3>")
                } else if let text = podcast.title {
                    infoText.append("<h3>\(text)</h3>")
                }
                
                // artist/author
                if let text = podcast.artist {
                    infoText.append("<p><b>Artist:</b> \(text)</p>")
                } else if let text = podcast.author {
                    infoText.append("<p><b>Author:</b> \(text)</p>")
                }
                
                // category
                if let text = podcast.category {
                    infoText.append("<p><b>Category:</b> \(text)</p>")
                }
                
                // only if different
                if isLatinLanguage {
                    // summary/description
                    if let text = podcast.podcastDescription?.normalize(), !text.isEmpty {
                        infoText.append("<p>\(text)</p>")
                    }
                    
                    if let text = podcast.summary?.normalize(), !text.isEmpty{
                        let summary = podcast.summary?.rawText() ?? ""
                        let desc = podcast.podcastDescription?.rawText() ?? ""
                        if summary != desc, desc.levenshtein(toString: summary, distanceMoreThan: 0.3) {
                            infoText.append("<p>\(text)</p>")
                        }
                    }
                } else {
                    if let text = podcast.summary?.normalize(), !text.isEmpty{
                        infoText.append("<p>\(text)</p>")
                    } else if let text = podcast.podcastDescription?.normalize(), !text.isEmpty {
                        infoText.append("<p>\(text)</p>")
                    }
                }

                // link
                if let text = podcast.link {
                    infoText.append("<p>\(text)")
                }

                // copy right
                if let text = podcast.rights {
                    infoText.append("<p>\(text)")
                } else if let text = podcast.copyright {
                    infoText.append("<p>\(text)")
                }
                
                var color = "black"
                if preferWhite { color = "white"}
                
                let style = "<style> * { font-family: Avenir-light !important; color: \(color) !important; background: none !important; } *:not(h1, h2, h3) { font-size: 13pt !important; } </style>"

                if let attributedText = (style + infoText).attributedString() {
                    completionHandler(attributedText)
                } else {
                    completionHandler(nil)
                }
            }
        }  else {
            completionHandler(nil)
        }
    }

    
    static func fetchEpisodeAttributedString(episode: EpisodeItem?, completionHandler: @escaping (NSMutableAttributedString?) -> Void) {
        
        var infoText = ""
        
        if let episode = episode {
            DispatchQueue.global(qos: .userInitiated).async {
                if let text = episode.title?.trimming() {
                    infoText.append("<h3>\(text)</h3>")
                }
                
                if isLatinLanguage {
                    var subtitle = ""
                    if let text = episode.subTitle?.trimming() {
                        subtitle = episode.subTitle?.rawText() ?? ""
                        infoText.append("<h4>\(text)</h4>")
                    }
                    
                    var desc = ""
                    if let text = episode.itemDescription?.normalize(), !text.isEmpty {
                        desc = episode.itemDescription?.rawText() ?? ""
                        if desc != subtitle {
                            infoText.append("<p>\(text)</p>")
                        }
                    } else {
                        desc = subtitle
                    }
                    
                    var summary = ""
                    if let text = episode.summary?.normalize(), !text.isEmpty {
                        summary = episode.summary?.rawText() ?? ""
                        if summary != desc {
                            infoText.append("<p>\(text)</p>")
                        }
                    } else {
                        summary = desc
                    }
                    
                    if let text = episode.content?.normalize(), !text.isEmpty {
                        let content = episode.content?.rawText() ?? ""
                        if content != summary {
                            infoText.append("<p>\(text)</p>")
                        }
                    }
                } else {
                    if let text = episode.subTitle?.trimming() {
                        infoText.append("<h3>\(text)</h3>")
                    }

                    if let text = episode.content?.normalize(), !text.isEmpty {
                        infoText.append("<p>\(text)</p>")
                    } else if let text = episode.summary?.normalize(), !text.isEmpty {
                        infoText.append("<p>\(text)</p>")
                    } else if let text = episode.itemDescription?.normalize(), !text.isEmpty {
                        infoText.append("<p>\(text)</p>")
                    }
                }

                if let text = episode.author?.trimming() {
                    infoText.append("<p><b>Author:</b> \(text)</p>")
                }
                
                if let pubDate = episode.pubDate {
                    infoText.append("<p><b>Publish Date:</b> \(pubDate.toString(withFormat: "EEE, d-MMM-yyyy HH:mm")!)</p>")
                }
                
                if let text = episode.duration?.trimming(), let duration = Utility.normalizeEpisodeDuration(text) {
                    infoText.append("<p><b>Duration:</b> \(duration)</p>")
                }
                
                if let text = episode.medium?.trimming(), text.hasPrefix("audio") || text.hasPrefix("video") {
                    infoText.append("<p><b>Type:</b> \(text)</p>")
                } else if let text = episode.mediaType?.trimming(), text.hasPrefix("audio") || text.hasPrefix("video") {
                    infoText.append("<p><b>Type:</b> \(text)</p>")
                } else if let text = episode.enclosureType?.trimming(), text.hasPrefix("audio") || text.hasPrefix("video") {
                    infoText.append("<p><b>Type:</b> \(text)</p>")
                }
                
                if let text = episode.link?.normalize(), !text.isEmpty {
                    infoText.append("<p>\(text)")
                }
                
                let style = "<style> * { font-family: Avenir-light !important; color: white !important; background: none !important; } *:not(h1, h2, h3, h4) { font-size: 13pt !important; } </style>"
                
                if let attributedText = (style + infoText).attributedString() {
                    completionHandler(attributedText)
                } else {
                    completionHandler(nil)
                }
            }
        } else {
            completionHandler(nil)
            
        }
    }
    
}
