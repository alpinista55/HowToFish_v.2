//
//  SettingsViewController.swift
//  HowToFish
//
//  Created by Kerr, James on 12/1/15.
//  Copyright © 2015 Columbia Sportswear Company. All rights reserved.
//

import Foundation
import RealmSwift

class SettingsViewController: UIViewController {
    
    // UI
    
    @IBOutlet weak var cacheLimitLabel: UILabel!
    @IBOutlet weak var cacheLimitSlider: UISlider!
    @IBOutlet weak var recentFileSizeLabel: UILabel!
    @IBOutlet weak var favoritesFileSizeLabel: UILabel!
    @IBOutlet weak var clearFavoritesButton: UIButton!
    @IBOutlet weak var clearRecentButton: UIButton!
    var menuButton: UIBarButtonItem?
    var homeButton: UIBarButtonItem?
    
    // Realm
    var recents: Results<LocalMediaObject>!
    var favorites: Results<LocalMediaObject>!
    let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as NSURL!
    let realm = try!  Realm()
    
    var isPopOver: Bool = false
    var cacheLimitHasChanged: Bool = false
    
    override func viewDidLoad() {
        
        navigationItem.title = "SETTINGS"
        
        if isPopOver == false {
            menuButton = UIBarButtonItem(image: UIImage(named: "Hamburger"), style: UIBarButtonItemStyle.Plain, target: self, action: nil)
            navigationItem.leftBarButtonItem = menuButton
            
            homeButton = UIBarButtonItem(image: UIImage(named: "House"), style: UIBarButtonItemStyle.Plain, target: self, action: "goHome:")
            navigationItem.rightBarButtonItem = homeButton
        }
        
        
        clearFavoritesButton.backgroundColor = UIColor.clearColor()
        clearFavoritesButton.layer.cornerRadius = 5
        clearFavoritesButton.layer.borderWidth = 1
        clearFavoritesButton.layer.borderColor = UIColor.blackColor().CGColor
        
        clearRecentButton.backgroundColor = UIColor.clearColor()
        clearRecentButton.layer.cornerRadius = 5
        clearRecentButton.layer.borderWidth = 1
        clearRecentButton.layer.borderColor = UIColor.blackColor().CGColor
        
        
        
        recents = realm.objects(LocalMediaObject).filter("isRecent = true")
        var total: Int = recents.sum("fileSize")
        var fileSizeString = NSByteCountFormatter.stringFromByteCount(Int64(total), countStyle: NSByteCountFormatterCountStyle.File)
        recentFileSizeLabel.text = fileSizeString
        
        favorites = realm.objects(LocalMediaObject).filter("isFavorite = true")
        total = favorites.sum("fileSize")
        fileSizeString = NSByteCountFormatter.stringFromByteCount(Int64(total), countStyle: NSByteCountFormatterCountStyle.File)
        
        if self.revealViewController() != nil {
            menuButton!.target = self.revealViewController()
            menuButton!.action = "revealToggle:"
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        favoritesFileSizeLabel.text = fileSizeString
        
        let cacheLimit = NSUserDefaults.standardUserDefaults().integerForKey("kCacheLimit")
        cacheLimitLabel.text = String(cacheLimit)
        cacheLimitSlider.value = Float(cacheLimit)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        if cacheLimitHasChanged {
            NSUserDefaults.standardUserDefaults().setFloat(cacheLimitSlider.value, forKey: "kCacheLimit")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    @IBAction func clearRecent(sender: AnyObject) {
        for lmo in recents {
            if !lmo.isFavorite {
                deleteVideoWithURL(lmo.mediaURL!)
            }
            try! realm.write() {
                lmo.isRecent = false
            }
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName("kUserDidChangeSettings", object: nil)
    }
    
    @IBAction func clearFavorites(sender: AnyObject) {
        for lmo in favorites {
            deleteVideoWithURL(lmo.mediaURL!)
            try! realm.write() {
                lmo.isFavorite = false
                lmo.isRecent = false
            }
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName("kUserDidChangeSettings", object: nil)
    }
    
    func deleteVideoWithURL(urlString: String) {
        if let url: NSURL = NSURL(string: urlString) {
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
    

    @IBAction func cacheLimitSliderValueChanged(sender: AnyObject) {
        let slider: UISlider = sender as! UISlider
        let roundedValue = round(slider.value)
        cacheLimitLabel.text = String(Int(roundedValue))
        slider.value = roundedValue
        cacheLimitHasChanged = true
    }
    
    @IBAction func goHome(sender: AnyObject) {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    
}
