//
//  DownloadArtworkOperation.swift
//  Caster
//
//  Created by Alex Truong on 5/15/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class DownloadArtworkOperation: Operation {
    
    let podcastId: Int!
    var response: DownloadResponse?
    var task: URLSessionDownloadTask?
    
    init(withPodcastId podcastId: Int) {
        self.podcastId = podcastId
    }
    
    override func main() {
        let destination = Utility.fileUrl(for: "\(podcastId!)")
        
        if let artworkUrl = podcastMap[podcastId]?.artworkUrl {
            let source = URL(string: artworkUrl)

            let semaphore = DispatchSemaphore(value: 0)
            
            task = URLSession.shared.downloadTask(with: source!) { (tempURL, response, error) in
                do {
                    if let tempURL = tempURL {
                        if FileManager.default.fileExists(atPath: destination.path) {
                            // remove existing one
                            try FileManager.default.removeItem(atPath: destination.path)
                        }
                        try FileManager.default.copyItem(at: tempURL, to: destination)
                    }
                    
                    self.response = DownloadResponse(destination: destination, response: response, error: error)
                } catch (let fileError) {
                    self.response = DownloadResponse(destination: nil, response: response, error: fileError)
                }
                
                semaphore.signal()
            }
            
            task?.resume()
            
            let _ = semaphore.wait(timeout: .distantFuture)
        }
    }
    
    func cancelDownload() {
        self.cancel()
        task?.cancel()
    }
    
}
