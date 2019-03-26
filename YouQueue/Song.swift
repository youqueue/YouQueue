//
//  Song.swift
//  YouQueue
//
//  Created by Case Wright on 3/25/19.
//  Copyright © 2019 Case Wright. All rights reserved.
//

import UIKit
import Parse

class Song: PFObject, PFSubclassing {
    
    @NSManaged var songId: Int
    @NSManaged var name: String
    @NSManaged var artist: String
    @NSManaged var albumArt: String
    @NSManaged var votes: Int
    @NSManaged var queue: PFObject?
    @NSManaged var played: Bool
    
    static func parseClassName() -> String {
        return "Song"
    }
}
