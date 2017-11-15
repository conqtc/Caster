//
//  CheckLastModifiedOperation.swift
//  Caster
//
//  Created by Alex Truong on 5/25/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class CheckLastModifiedOperation: Operation {
    let pid: Int
    var needsDownloadFeed: Bool = false
    
    init(forPodcast id: Int) {
        self.pid = id
    }
    
    override func main() {
        self.needsDownloadFeed = false
        
        let fileURL = Utility.fileUrl(for: "\(pid).xml")
        guard let feedUrl = podcastMap[pid]?.feedUrl else {
            return
        }

        if FileManager.default.fileExists(atPath: fileURL.path) {
            // get file last modified date
            var creationDate: Date!
            
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                creationDate = attributes[.creationDate] as! Date
            } catch {}
            
            if let creationDate = creationDate {
                let semaphore = DispatchSemaphore(value: 0)
                NetCaster.lastModifiedDate(ofUrl: URL(string: feedUrl)!) { date in
                    if let date = date, date > creationDate {
                        self.needsDownloadFeed = true
                    }
                    
                    semaphore.signal()
                }
                let _ = semaphore.wait(timeout: .distantFuture)
            }
        } else {
            self.needsDownloadFeed = true
        }
    }
}
