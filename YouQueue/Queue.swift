//
//  Queue.swift
//  YouQueue
//
//  Created by Case Wright on 3/26/19.
//  Copyright © 2019 Case Wright. All rights reserved.
//

import UIKit
import Parse

class Queue: PFObject, PFSubclassing {
    
    @NSManaged var code: String
    @NSManaged var lat: Double
    @NSManaged var long: Double
    @NSManaged var vote_threshold: Int
    @NSManaged var allow_duplicated: Bool
    @NSManaged var restrict_location: Bool
    @NSManaged var location_min: Double
    @NSManaged var open: Bool
    
    static func parseClassName() -> String {
        return "Queue"
    }
}
