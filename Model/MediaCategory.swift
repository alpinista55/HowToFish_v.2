//
//  MediaCategory.swift
//  HowToFish
//
//  Created by Kerr, James on 12/8/15.
//  Copyright © 2015 Columbia Sportswear Company. All rights reserved.
//

import Foundation
import RealmSwift

class MediaCategory: Object {
    dynamic var id: Int = -1
    dynamic var heroTag: String?
    dynamic var displayName: String?
    dynamic var thumbnailName: String?
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
