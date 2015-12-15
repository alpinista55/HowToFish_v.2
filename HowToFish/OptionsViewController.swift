//
//  OptionsViewController.swift
//  HowToFish
//
//  Created by Kerr, James on 12/1/15.
//  Copyright © 2015 Columbia Sportswear Company. All rights reserved.
//

import Foundation
import RealmSwift



class OptionsViewController: UIViewController {
    
    var lmo: LocalMediaObject?
    let realm = try! Realm()
    
    //UI
    @IBOutlet weak var recentsButton: UIButton!
    @IBOutlet weak var favoritesButton: UIButton!
    @IBOutlet weak var safariButton: UIButton!
    @IBOutlet weak var downloadHDButton: UIButton!
    
    
    override func viewDidLoad() {
        

        if lmo!.isRecent {
            recentsButton.enabled = true
        } else {
            recentsButton.enabled = false
        }

        lmo!.isFavorite ? favoritesButton.setTitle("Remove from Favorites", forState: UIControlState.Normal) : favoritesButton.setTitle("Add to Favorites", forState: UIControlState.Normal)
        lmo!.isHD ? downloadHDButton.setTitle("Download in SD", forState: UIControlState.Normal) : downloadHDButton.setTitle("Download in HD", forState: UIControlState.Normal)
        
        //preferredContentSize = CGSizeMake(300.0, 310.0)

    }
    
    @IBAction func share(sender: AnyObject) {
        
        let info = ["lmo": lmo!, "shareType": sender.tag]
        
        dismissViewControllerAnimated(true, completion: { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("kUserDidSelectShare", object: nil, userInfo: info)
        })
    }
    
    @IBAction func toggleMediaObjectToFavoriteStatus() {
        
        var isFavoriteNewValue: Bool
        if lmo!.isFavorite == false {
            isFavoriteNewValue = true
            favoritesButton.setTitle("Remove from Favorites", forState: UIControlState.Normal)
        } else {
            isFavoriteNewValue = false
            favoritesButton.setTitle("Add to Favorites", forState: UIControlState.Normal)
        }
        
        
        try! realm.write {
            self.lmo!.isFavorite = isFavoriteNewValue
        }
        
        let userInfo = ["lmo": lmo!]
        
        dismissViewControllerAnimated(true) { () -> Void in
            //NSNotificationCenter.defaultCenter().postNotificationName("kVideoOptionsDidChange", object: nil)
            NSNotificationCenter.defaultCenter().postNotificationName("kVideoOptionsDidChange", object: nil, userInfo: userInfo)
        }
    }
    
    @IBAction func removeMediaFromRecents() {
        try! realm.write() {
            self.lmo!.isRecent = false
        }
        
        let path: String = lmo!.isHD ? lmo!.mediaURL720p! : lmo!.mediaURL!
        
        deleteMediaAtPath(path)
        
        dismissViewControllerAnimated(true) { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("kVideoOptionsDidChange", object: nil, userInfo: nil)
        }
    }
    
    @IBAction func openInSafari() {
        
        if let url = NSURL(string: lmo!.websiteURL!) {
            dismissViewControllerAnimated(true, completion: { () -> Void in
                UIApplication.sharedApplication().openURL(url)
            })
        }
    }
    
    @IBAction func downloadInHD() {
        removeMediaFromRecents()
        
        try! realm.write() {
            self.lmo!.isHD = !self.lmo!.isHD
        }
        dismissViewControllerAnimated(true) { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("kVideoOptionsDidChange", object: nil)
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
    
    @IBAction func dismissOptionsVC(tapRecognizer: UITapGestureRecognizer) {

            dismissViewControllerAnimated(true, completion: nil)
    }
    
}
