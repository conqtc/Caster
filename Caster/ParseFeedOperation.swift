//
//  ParseFeedOperation.swift
//  Caster
//
//  Created by Alex Truong on 5/25/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class ParseFeedOperation: Operation {
    let pid: Int
    let needsDownload: Bool
    var items: [EpisodeItem]?
    var info: PodcastEntry?
    
    init(forPodcast id: Int, needsDownload: Bool) {
        self.pid = id
        self.needsDownload = needsDownload
    }
    
    override func main() {
        let fileURL = Utility.fileUrl(for: "\(pid).xml")
        
        if needsDownload {
            let feedUrl = (podcastMap[pid]?.feedUrl)!
            
            let semaphore = DispatchSemaphore(value: 0)
            
            NetCaster.download(url: URL(string: feedUrl)!, to: fileURL) { response in
                // parse it even failed
                if let parser = iTunesRssParser(withUrl: fileURL) {
                    (self.items, self.info) = parser.parse()
                }
                semaphore.signal()
            }
            
            let _ = semaphore.wait(timeout: .distantFuture)
        } else {
            // parse locally right away
            if let parser = iTunesRssParser(withUrl: fileURL) {
                (self.items, self.info) = parser.parse()
            }
        }
    }

}
