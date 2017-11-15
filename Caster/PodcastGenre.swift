//
//  PodcastGenre.swift
//  Caster
//
//  Created by Alex Truong on 4/19/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import Foundation

class PodcastGenre {
    let id: Int
    let title: String
    
    var subGenres = [PodcastGenre]()
    
    init(id: Int, title: String) {
        self.id = id
        self.title = title
    }
}
