//
//  LocalMediaObject.swift
//  HowToFish
//
//  Created by Kerr, James on 11/23/15.
//  Copyright © 2015 Columbia Sportswear Company. All rights reserved.
//

import Foundation
import RealmSwift

class LocalMediaObject: Object {
    dynamic var objectID = ""
    dynamic var dateAdded: NSDate!
    dynamic var createdAt: NSDate?
    dynamic var updatedAt: NSDate?
    dynamic var category: String?
    dynamic var heroTag: String?
    dynamic var mediaURL: String?
    dynamic var mediaURL720p: String?
    dynamic var producer: String?
    dynamic var runTime: String?
    dynamic var sequenceNumber = 0
    dynamic var series: String?
    
    dynamic var spokesPerson: String?
    var tags: List<PFGTag>?
    dynamic var thumbURL: String?
    dynamic var title: String?
    dynamic var url: String?
    dynamic var websiteURL: String?
    
    dynamic var isRecent: Bool = false
    dynamic var isFavorite: Bool = false
    dynamic var isHD: Bool = false
    
    dynamic var fileSize: Int64 = 0
    
    override static func primaryKey() -> String? {
        return "objectID"
    }
}
