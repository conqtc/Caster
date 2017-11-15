//
//  LoadArtworkThumbnailOperation.swift
//  Caster
//
//  Created by Alex Truong on 5/17/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class LoadArtworkThumbnailOperation: Operation {
    let pid: Int
    var image: UIImage?
    
    init(forPodcast id: Int) {
        self.pid = id
    }
    
    override func main() {
        let fileURL = Utility.fileUrl(for: "\(pid)s")
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            image = Utility.loadSmallArtworkFromFile(withId: pid)
        } else if let imageUrl = podcastMap[pid]?.image {
            let semaphore = DispatchSemaphore(value: 0)
            
            NetCaster.download(url: URL(string: imageUrl)!, to: fileURL) { response in
                if response.error == nil {
                    self.image = Utility.loadSmallArtworkFromFile(withId: self.pid)
                }
                
                semaphore.signal()
            }
            
            let _ = semaphore.wait(timeout: .distantFuture)
        }
    }
}
