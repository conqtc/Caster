//
//  NetCaster.swift
//  Caster
//
//  Created by Alex Truong on 5/7/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import Foundation

// a JSON response encapsulation
struct JSONResponse {
    var json: [String: Any]?
    var statusCode: Int?
    var error: Error?
    
    // initializer
    init(data: Data?, response: URLResponse?, error: Error?) {
        if let statusCode = (response as? HTTPURLResponse)?.statusCode {
            self.statusCode = statusCode
        }
        
        if let data = data {
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                self.json = json
            }
        }
        
        self.error = error
    }
}

struct DownloadResponse {
    var statusCode: Int?
    var destinationURL: URL?
    var error: Error?
    
    init(destination: URL?, response: URLResponse?, error: Error?) {
        if let statusCode = (response as? HTTPURLResponse)?.statusCode {
            self.statusCode = statusCode
        }

        self.destinationURL = destination
        self.error = error
    }
}

// a replacement of famous Alamofire ?!
class NetCaster {
    
    static var shared: URLSession {
        if session == nil {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = TimeInterval(30.0)
            configuration.timeoutIntervalForResource = TimeInterval(60.0)
            
            session = URLSession(configuration: configuration)
        }
        
        return session!
    }
    
    static var session: URLSession?
    
    // request a json data
    class func requestJSON(url: URL, completionHandler: @escaping (JSONResponse) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            completionHandler(JSONResponse(data: data, response: response, error: error))
        }
        
        task.resume()
    }
    
    // download to a specific location
    class func download(url: URL, to destination: URL, completionHandler: @escaping (DownloadResponse) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { (tempURL, response, error) in
            do {
                if let source = tempURL {
                    if FileManager.default.fileExists(atPath: destination.path) {
                        // remove existing one
                        try FileManager.default.removeItem(atPath: destination.path)
                    }
                    try FileManager.default.copyItem(at: source, to: destination)
                }

                completionHandler(DownloadResponse(destination: destination, response: response, error: error))
            } catch (let fileError) {
                completionHandler(DownloadResponse(destination: nil, response: response, error: fileError))
            }
        }
        
        task.resume()
    }
    
    // retrieve last modified-date header ino
    class func lastModifiedDate(ofUrl url: URL, completionHandler: @escaping (Date?) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let response = response as? HTTPURLResponse, let lastModified = response.allHeaderFields["Last-Modified"] as? String {
                
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE, dd LLL yyyy hh:mm:ss zzz"
                let date = formatter.date(from: lastModified)
                
                completionHandler(date)
            } else {
                completionHandler(nil)
            }
        }
        
        task.resume()
    }

}
