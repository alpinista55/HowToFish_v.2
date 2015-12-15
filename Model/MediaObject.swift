//
//  MediaObject.swift
//  HowToFish
//
//  Created by Kerr, James on 11/19/15.
//  Copyright © 2015 Columbia Sportswear Company. All rights reserved.
//

import Foundation

class MediaObject : PFObject, PFSubclassing {
    
    @NSManaged var category: String?
    @NSManaged var heroTag: String?
    @NSManaged var mediaURL: String?
    @NSManaged var mediaURL720p: String?
    @NSManaged var producer: String?
    @NSManaged var runTime: String?
    @NSManaged var sequenceNumber: NSNumber?
    @NSManaged var series: String?
    @NSManaged var spokesPerson: String?
    @NSManaged var tags: Array<String>?
    @NSManaged var thumbURL: String?
    @NSManaged var title: String?
    @NSManaged var url: String?
    @NSManaged var websiteURL: String?
    @NSManaged var thumb: PFFile?
    
    
    override class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    static func parseClassName() -> String {
        return "MediaObject"
    }
    
}
