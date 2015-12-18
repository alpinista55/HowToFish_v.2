//
//  ModelBuilder.swift
//  HowToFish
//
//  Created by Kerr, James on 11/23/15.
//  Copyright © 2015 Columbia Sportswear Company. All rights reserved.
//

import Foundation
import RealmSwift

class ModelBuilder: Object, NSURLSessionDelegate, NSURLSessionDownloadDelegate {
    
    
    static let sharedInstance = ModelBuilder()
    
    func buildLocalDatabase() {
        
        let realm = try! Realm()
        
        try! realm.write{
            realm.deleteAll()
        }
        
        self.buildCategories()
        
        let query = MediaObject.query()
        
        //query?.cachePolicy = PFCachePolicy.CacheElseNetwork
        
        query?.findObjectsInBackgroundWithBlock({ (results: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                if let videos = results as? [MediaObject] {
                    
                    for media in videos {
                        
                        let lmo = LocalMediaObject()
                        lmo.objectID = media.objectId!
                        lmo.createdAt = media.createdAt! //["createdAt"] as? NSDate
                        lmo.updatedAt = media.updatedAt! //["updatedAt"] as? NSDate
                        lmo.title = media.title
                        lmo.category = media.category
                        lmo.heroTag = media.heroTag
                        lmo.mediaURL = media.mediaURL
                        lmo.mediaURL720p = media.mediaURL720p
                        lmo.producer = media.producer
                        lmo.runTime = media.runTime
                        lmo.sequenceNumber = media.sequenceNumber!.integerValue
                        lmo.series = media.series
                        lmo.spokesPerson = media.spokesPerson
                        lmo.thumbURL = media.thumbURL
                        lmo.url = media.url
                        lmo.websiteURL = media.websiteURL
                        
                        try! realm.write {
                            realm.add(lmo)
                        }
                    }
                    
                    NSUserDefaults.standardUserDefaults().setBool(true, forKey: "localData")
                    NSUserDefaults.standardUserDefaults().synchronize()
                    self.downloadAllThumbnails()
                    
                }
                
            } else {
                print("Error: \(error?.localizedDescription)")
            }
        })
    }
    
    func downloadAllThumbnails() {
        
        //Configure session
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory: AnyObject = paths[0]
        let thumbnailsPath = documentsDirectory.stringByAppendingPathComponent("thumbnails")
        
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(thumbnailsPath, withIntermediateDirectories: false, attributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription);
        }
        
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as NSURL!
        let thumbsURL = documentsUrl.URLByAppendingPathComponent("thumbnails")
        let realm = try! Realm()
        let lmos = realm.objects(LocalMediaObject)
        for lmo in lmos {
            if let downloadPath: String = lmo.thumbURL {
                print("\(downloadPath)")
                if downloadPath.characters.count == 0 {
                    print("SequenceNo \(lmo.title) in 0 length")
                }
                if let downloadURL = NSURL(string: downloadPath) {
                    let thumbFilename = "CSC_" + String(lmo.sequenceNumber) + "_thumb.jpg"
                    let saveToURL = thumbsURL.URLByAppendingPathComponent(thumbFilename) as NSURL!
                    
                    if NSFileManager().fileExistsAtPath(saveToURL.path!) {
                        print("file already exists [\(saveToURL!.path!)]")
                    } else {
                        print("downloading file")
                        
                        let request = NSMutableURLRequest(URL: downloadURL)
                        request.HTTPMethod = "GET"
                        let task = session.downloadTaskWithRequest(request, completionHandler: { (tempURL: NSURL?, response:NSURLResponse?, error: NSError?) -> Void in
                            do {
                                try NSFileManager.defaultManager().moveItemAtURL(tempURL!, toURL: saveToURL)
                                } catch let error as NSError {
                                print("error moving file: \(error)")
                                }
                        })
                        task.resume()
                    }
                }
            }
        }
    }
    
    func buildCategories() {
        
        var counter = 0
        
        let thumbnailNames = ["CategoryThumb_BASICS_iPad",
            "CategoryThumb_HARDWARE_iPad",
            "CategoryThumb_FRESHWATER_iPad",
            "CategoryThumb_SALTWATER_iPad",
            "CategoryThumb_FLYFISHING_iPad"
        ]
        
        let displayNames = ["Fishing Basics", "Hardware", "Freshwater Fishing", "Saltwater Fishing", "Fly Fishing"]
        
        let heroTags = ["Fishing Basics", "Tackle", "Freshwater Fishing", "Saltwater Fishing", "Fly Fishing"]
        
        for _ in displayNames {
            let myCategory: MediaCategory = MediaCategory()
            myCategory.id = counter
            myCategory.displayName = displayNames[counter]
            myCategory.thumbnailName = thumbnailNames[counter]
            myCategory.heroTag = heroTags[counter]
            counter++
            
            let realm = try! Realm()
            try! realm.write {
                realm.add(myCategory)
            }
        }
    }
    
    // MARK: - Realm Queries -
    
    func getCategories() -> Results<MediaCategory> {
        let realm = try! Realm()
        let categories = realm.objects(MediaCategory).sorted("id")
        return categories
    }
    
    func getMediaObjectsForCategory(category: MediaCategory) -> Results<LocalMediaObject>{
        let realm = try! Realm()
        let mediaObjects = realm.objects(LocalMediaObject).filter("heroTag = '\(category.heroTag!)'").sorted("title", ascending: true)
        return mediaObjects
    }
    
    func getFavorites() -> Results<LocalMediaObject>{
        let realm = try! Realm()
        let mediaObjects = realm.objects(LocalMediaObject).filter("isFavorite = true").sorted("title", ascending: true)
        return mediaObjects
    }
    
    func getRecent() -> Results<LocalMediaObject>{
        let realm = try! Realm()
        let mediaObjects = realm.objects(LocalMediaObject).filter("isRecent = true").sorted("title", ascending: true)
        return mediaObjects
    }
    
    func deleteMediaFromRecentIfNecessary() {
        
        // Get Recently viewed media
        let realm = try! Realm()
        let recents = realm.objects(LocalMediaObject).filter("isRecent = true").sorted("dateAdded")
        
        // CacheLimit is set in the settingsView
        let cacheLimit = NSUserDefaults.standardUserDefaults().floatForKey("kCacheLimit")
        
        var mediaObjectsToRemove = Array<LocalMediaObject>()
        
        // If cache limit exceeded, add earliest to temp array
        if recents.count > Int(cacheLimit) {
            let delta = recents.count - Int(cacheLimit)
            
            for var i = 0; i < delta; i++ {
                print("Removing lmo at index \(i), added at: \(recents[i].dateAdded), title: \(recents[i].title)")
                mediaObjectsToRemove.append(recents[i])
            }
            
            removeMediaFromRecents(mediaObjectsToRemove)
        }
    }
    
    func removeMediaFromRecents(mediaObjects: Array<LocalMediaObject>) {
        let realm = try! Realm()
        try! realm.write() {
            for media in mediaObjects {
                media.isRecent = false
                if media.isFavorite == false {
                    let path: String = media.isHD ? media.mediaURL720p! : media.mediaURL!
                    self.deleteMediaAtPath(path)
                }
            }
        }
    }
    
    func deleteMediaAtPath(path: String) {
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as NSURL!
        if let url: NSURL = NSURL(string: path) {
            let fileURL = documentsUrl.URLByAppendingPathComponent(url.lastPathComponent!)
            if NSFileManager().fileExistsAtPath(fileURL.path!) {
                do {
                    try NSFileManager().removeItemAtPath(fileURL.path!)
                }
                    
                catch let error as NSError {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        print("Downloaded item")
        
    }
}
