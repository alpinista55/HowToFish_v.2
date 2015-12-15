//
//  ViewController.swift
//  HowToFish
//
//  Created by Kerr, James on 11/19/15.
//  Copyright © 2015 Columbia Sportswear Company. All rights reserved.
//

import UIKit
import Realm
import RealmSwift


enum HeroTag: Int {
    case Basics = 0, Hardware, Freshwater, Saltwater, FlyFishing
}

class CategoryViewController: UIViewController, NSURLSessionDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate{
    
    @IBOutlet weak var imageView: UIImageView!
    var expectedContentLength = 0
    var buffer:NSMutableData = NSMutableData()
    var destinationURL: NSURL?
    var videos: Results<LocalMediaObject>?
   // let realm = try! Realm()
    var collectionTitle: String?
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var progressBar: UIProgressView!
    
    //slideshow
    var images = Array<UIImage>()
    var slideshowTimer: NSTimer?
    var slideCounter = 0;

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "PFG: HOW TO FISH"
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = "revealToggle:"
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        loadImages()

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.title = "PFG: HOW TO FISH"
        startSlideShow()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        stopSlideShow()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func handleButtonTap(sender: AnyObject) {

        switch sender.tag {
        case HeroTag.Basics.rawValue:
            collectionTitle = "Fishing Basics"
            fetchMediaForTag(collectionTitle!)
        case HeroTag.Hardware.rawValue:
            collectionTitle = "Tackle"
            fetchMediaForTag(collectionTitle!)
        case HeroTag.Saltwater.rawValue:
            collectionTitle = "Saltwater Fishing"
            fetchMediaForTag(collectionTitle!)
        case HeroTag.Freshwater.rawValue:
            collectionTitle = "Freshwater Fishing"
            fetchMediaForTag(collectionTitle!)
        case HeroTag.FlyFishing.rawValue:
            collectionTitle = "Fly Fishing"
            fetchMediaForTag(collectionTitle!)
        default:
            return
        }
        
        print("Video count = \(videos?.count)")
        if videos?.count > 0 {
            performSegueWithIdentifier("presentVideoCollection", sender: self)
        }
        
    }
    
    func fetchMediaForTag(hero: String) {
        print("Fetching videos for tag \(hero)")
        let realm = try! Realm()
        videos = realm.objects(LocalMediaObject).filter("heroTag = '\(hero)'").sorted("title", ascending: true)

    }
    
    // MARK: - Slideshow
    
    func loadImages() {
        
        let imageNames = ["pfgSplash_01.png", "pfgSplash_03.png", "pfgSplash_04.png"]
        for name in imageNames {
            let newImage: UIImage = UIImage(named: name)!
            images.append(newImage)
        }
        
        imageView.image = images[0]
        
    }
    
    func startSlideShow() {
        slideshowTimer = NSTimer.scheduledTimerWithTimeInterval(6.0, target: self, selector: "advanceSlideShow", userInfo: nil, repeats: true)
    }
    
    func stopSlideShow() {
        if slideshowTimer != nil {
            if slideshowTimer!.valid {
                slideshowTimer!.invalidate()
            }
            slideshowTimer = nil
        }
        //print("Slideshow Timer killed")
    }
    
    func advanceSlideShow() {
        
       
        
        if slideCounter == self.images.count {
            slideCounter = 0
        }
        
         print("count = \(slideCounter)")
        
        let nextImage:UIImage = self.images[slideCounter]
        
        UIView.transitionWithView(imageView, duration: 0.25, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: { () -> Void in
            self.imageView.image = nextImage
            }) { (Bool) -> Void in
        }
        slideCounter += 1
    }

    
    
    //Mark Segue Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "presentVideoCollection" {
            let controller: VideoCollectionViewController = segue.destinationViewController as! VideoCollectionViewController
            controller.videos = self.videos
            controller.collectionTitle = self.collectionTitle?.uppercaseString
            
            
        }
    }
    
}

