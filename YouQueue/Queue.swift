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
    @NSManaged var voteThreshold: Int
    @NSManaged var allowDuplicated: Bool
    @NSManaged var restrictLocation: Bool
    @NSManaged var locationMin: Double
    @NSManaged var open: Bool

    static func parseClassName() -> String {
        return "Queue"
    }
}
