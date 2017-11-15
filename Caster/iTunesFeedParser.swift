//
//  iTunesFeedParser.swift
//  Based on FeedKit: https://github.com/nmdias/FeedKit
//  Caster
//
//  Created by Alex Truong on 4/28/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import Foundation

// MARK: parser data

class iTunesFeedParser: NSObject {
    var parser: XMLParser!
    var entries: [PodcastEntry]?
    
    var status: ParseStatus = .stopped
    var currentPath: URL = URL(string: "/")!
    
    var parsingImage = false
    
    init?(withUrl url: URL) {
        super.init()
        
        guard let parser = XMLParser(contentsOf: url) else {
            return nil
        }
        
        self.parser = parser
        self.parser.delegate = self
    }
    
    func parse() -> [PodcastEntry]? {
        status = .parsing
        
        let success = parser.parse()
        
        if success {
            return self.entries
        } else {
            return nil
        }
    }
    
    func parseAsync(queue: DispatchQueue = DispatchQueue.global(qos: .background), complete: @escaping ([PodcastEntry]?) -> Void) {
        queue.async {
            complete(self.parse())
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

extension iTunesFeedParser: XMLParserDelegate {
    
    func mapAttributes(_ attributes: [String : String], forPath path: FeedPath) {
        switch (path) {
            
        case .FeedEntry:
            if self.entries == nil {
                self.entries = []
            }
            self.entries?.append(PodcastEntry())
            
        case .FeedEntryID:
            self.entries?.last?.id = Int(attributes["im:id"] ?? "0")
            
        case .FeedEntryCategory:
            self.entries?.last?.category = attributes["term"] ?? ""
            
        case .FeedEntryImage:
            if let height = attributes["height"], height == "170"  {
                parsingImage = true
            } else {
                parsingImage = false
            }
            
        default:
            break
        }
    }
    
    func mapCharacters(_ string: String, forPath path: FeedPath) {
        switch (path) {
            
        case .FeedEntryTitle:
            self.entries?.last?.title = self.entries?.last?.title?.appending(string) ?? string
            
        case .FeedEntryName:
            self.entries?.last?.name = self.entries?.last?.name?.appending(string) ?? string
            
        case .FeedEntryArtist:
            self.entries?.last?.artist = self.entries?.last?.artist?.appending(string) ?? string
            
        case .FeedEntryContent:
            self.entries?.last?.content = self.entries?.last?.content?.appending(string) ?? string
            
        case .FeedEntrySummary:
            self.entries?.last?.summary = self.entries?.last?.summary?.appending(string) ?? string
            
        case .FeedEntryRights:
            self.entries?.last?.rights = self.entries?.last?.rights?.appending(string) ?? string
            
        case .FeedEntryImage:
            if parsingImage {
                self.entries?.last?.image = self.entries?.last?.image?.appending(string) ?? string
            }
            
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentPath.appendPathComponent(elementName)
        
        if let path = FeedPath(rawValue: currentPath.absoluteString) {
            mapAttributes(attributeDict, forPath: path)
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if let path = FeedPath(rawValue: currentPath.absoluteString) {
            mapCharacters(string, forPath: path)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        currentPath.deleteLastPathComponent()
    }
}
