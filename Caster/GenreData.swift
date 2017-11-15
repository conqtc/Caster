//
//  GenreData.swift
//  Caster
//
//  Created by Alex Truong on 4/20/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import Foundation

class GenreData {

    var genres = [PodcastGenre]()
    var map = [Int: PodcastGenre]()
    var features = [PodcastGenre]()
    
    init() {
        let path = Bundle.main.path(forResource: "Genre", ofType: "plist")!
        let data = NSDictionary(contentsOfFile: path) as! [String: [[String: AnyObject]]]
        
        for dictionary in data["genre"]! {
            let id = dictionary["id"] as! Int
            let title = dictionary["title"] as! String
            let genre = PodcastGenre(id: id, title: title)
            if let subData = dictionary["subgenre"] as? [[String: AnyObject]] {
                for subDict in subData {
                    let sid = subDict["id"] as! Int
                    let stitle = subDict["title"] as! String
                    let subGenre = PodcastGenre(id: sid, title: stitle)
                    genre.subGenres.append(subGenre)
                    map[sid] = subGenre
                }
            }
            genres.append(genre)
            map[id] = genre
        }

        for dictionary in data["feature"]! {
            let id = dictionary["id"] as! Int
            //let title = dictionary["title"] as! String
            features.append(map[id]!)
        }
    }
}
