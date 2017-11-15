//
//  iTunesRSSParser.swift
//  Based on FeedKit: https://github.com/nmdias/FeedKit
//  Caster
//
//  Created by Alex Truong on 4/22/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import Foundation

// MARK: parser data

class iTunesRssParser: NSObject {
    let shouldLimitResult = true
    let kMaxItemsCount = 100
    var itemCount = 0
    
    var parser: XMLParser!
    var items: [EpisodeItem]?
    var info: PodcastEntry?

    var status: ParseStatus = .stopped
    var currentPath: URL = URL(string: "/")!

    init?(withUrl url: URL) {
        super.init()
        
        guard let parser = XMLParser(contentsOf: url) else {
            return nil
        }
        
        self.parser = parser
        self.parser.delegate = self
    }
    
    func parse() -> ([EpisodeItem]?, PodcastEntry?) {
        status = .parsing
        
        let success = parser.parse()
        
        if success {
            return (self.items, self.info)
        } else {
            if status == .aborted {
                return (self.items, self.info)
            } else {
                return (nil, nil)
            }
        }
    }
    
    func parseAsync(queue: DispatchQueue = DispatchQueue.global(qos: .background), complete: @escaping ([EpisodeItem]?, PodcastEntry?) -> Void) {
        queue.async {
            let (items, info) = self.parse()
            complete(items, info)
        }
    }
    
    func abort() {
        if status == .parsing {
            parser.abortParsing()
        }

        status = .aborted
    }
}

// MARK: XMLParserDelegate

extension iTunesRssParser: XMLParserDelegate {
    
    func mapAttributes(_ attributes: [String : String], forPath path: RSSPath) {
        switch (path) {
            
        case .RSSChannel:
            info = PodcastEntry()
            
        case .RSSChannelItunesCategory:
            if let category = attributes["text"] {
                info?.category = category
            }
            
        case .RSSChannelItem:
            itemCount += 1
            
            if shouldLimitResult, itemCount > kMaxItemsCount {
                self.abort()
                return
            }
 
            if self.items == nil {
                self.items = []
            }

            self.items?.append(EpisodeItem())
            
        case .RSSChannelItemEnclosure:
            if let url = attributes["url"] {
                items?.last?.enclosureUrl = url
            }
            
            if let length = attributes["length"] {
                items?.last?.enclosureLength = Int(length)
            }
            
            if let type = attributes["type"] {
                items?.last?.enclosureType = type
            }
            
        case .RSSChannelItemMediaContent:
            // only care about audio/video
            if let medium = attributes["medium"] {
                items?.last?.medium = medium
                
                if medium.hasPrefix("audio") || medium.hasPrefix("video"), let url = attributes["url"] {
                    items?.last?.mediaUrl = url
                }
            } else if let type = attributes["type"] {
                items?.last?.mediaType = type
                if type.hasPrefix("audio") || type.hasPrefix("video"), let url = attributes["url"] {
                    items?.last?.mediaUrl = url
                }
            }
            
    
        default:
            break
        }
    }
    
    func mapCharacters(_ string: String, forPath path: RSSPath) {
        switch (path) {
            
        case .RSSChannelLink:
            info?.link = info?.link?.appending(string) ?? string
            
        case .RSSChannelDescription:
            info?.podcastDescription = info?.podcastDescription?.appending(string) ?? string
            
        case .RSSChannelCategory:
            info?.category = info?.category?.appending(string) ?? string
            
        case .RSSChannelCopyright, .RSSChannelMediaCopyright:
            info?.copyright = info?.copyright?.appending(string) ?? string
            
        case .RSSChannelItunesSummary:
            info?.summary = info?.summary?.appending(string) ?? string
            
        case .RSSChannelLastBuildDate:
            info?.lastBuildDate = string.toDate()

        case .RSSChannelItunesAuthor:
            info?.author = info?.author?.appending(string) ?? string

        // MARK:
        case .RSSChannelItemTitle:
            self.items?.last?.title = self.items?.last?.title?.appending(string) ?? string
            
        case .RSSChannelItemLink:
            self.items?.last?.link = self.items?.last?.link?.appending(string) ?? string
            
        case .RSSChannelItemItunesSubtitle:
            self.items?.last?.subTitle = self.items?.last?.subTitle?.appending(string) ?? string
            
        case .RSSChannelItemDescription:
            self.items?.last?.itemDescription = self.items?.last?.itemDescription?.appending(string) ?? string
            
        case .RSSChannelItemPubDate:
            self.items?.last?.pubDate = string.toDate()
            
        case .RSSChannelItemItunesSummary:
            self.items?.last?.summary = self.items?.last?.summary?.appending(string) ?? string
            
        case .RSSChannelItemContent:
            self.items?.last?.content = self.items?.last?.content?.appending(string) ?? string
            
        case .RSSChannelItemAuthor, .RSSChannelItemItunesAuthor:
            self.items?.last?.author = self.items?.last?.author?.appending(string) ?? string
            
        case .RSSChannelItemItunesDuration:
            self.items?.last?.duration = self.items?.last?.duration?.appending(string) ?? string
            
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentPath.appendPathComponent(elementName)
        
        if let path = RSSPath(rawValue: currentPath.absoluteString) {
            mapAttributes(attributeDict, forPath: path)
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if let path = RSSPath(rawValue: currentPath.absoluteString) {
            mapCharacters(string, forPath: path)
        }
    }
    
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        guard let string = String(data: CDATABlock, encoding: .utf8) else {
            self.abort()
            return
        }
        
        if let path = RSSPath(rawValue: currentPath.absoluteString) {
            mapCharacters(string, forPath: path)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        currentPath.deleteLastPathComponent()
    }
}
