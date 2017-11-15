//
//  LookUpPodcastOperation.swift
//  Caster
//
//  Created by Alex Truong on 5/16/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit

class LookUpPodcastOperation: Operation {

    let podcastId: Int!
    var task: URLSessionDataTask?
    var response: JSONResponse?
    
    init(withPodcastId podcastId: Int) {
        self.podcastId = podcastId
    }
    
    override func main() {
        let url = URL(string: kiTunesLookupPrefix + String(podcastId))
        let fileURL = Utility.fileUrl(for: "\(podcastId!).json")
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            // parse json file
            do {
                let data = try Data(contentsOf: fileURL)
                self.response = JSONResponse(data: data, response: nil, error: nil)
            } catch let error {
                self.response = JSONResponse(data: nil, response: nil, error: error)
            }
        } else {
            let semaphore = DispatchSemaphore(value: 0)

            NetCaster.download(url: url!, to: fileURL) { response in
                if response.error == nil {
                    // parse json file
                    do {
                        let data = try Data(contentsOf: fileURL)
                        self.response = JSONResponse(data: data, response: nil, error: nil)
                    } catch let error {
                        self.response = JSONResponse(data: nil, response: nil, error: error)
                    }
                }
                
                semaphore.signal()
            }

            let _ = semaphore.wait(timeout: .distantFuture)
        }
    }
    
    func cancelLookUp() {
        self.cancel()
        task?.cancel()
    }
}
