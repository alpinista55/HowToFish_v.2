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

class CategoryViewController: UIViewController,
    NSURLSessionDelegate,
    NSURLSessionDataDelegate,
    NSURLSessionTaskDelegate,
    SWRevealViewControllerDelegate{
    
    // Model
    var categories: Results<MediaCategory>?
    var videos: Results<LocalMediaObject>?
    var collectionTitle: String?
    var heroTag: String?
    
    // UI
    @IBOutlet weak var imageView: UIImageView! // Main in=mageview for slideshow images
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var progressBar: UIProgressView!
    
    // Slideshow
    var images = Array<UIImage>()
    var slideshowTimer: NSTimer?
    var slideCounter = 1;
    
    // SWReveal
    var buttonsEnabled: Bool = true

    // MARK: - LifeCycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "PFG: HOW TO FISH"
        
        // Config for SWReveal controller
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = "revealToggle:"
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            
        }
        
        loadImages()
        categories = ModelBuilder.sharedInstance.getCategories()
        
        if Reachability.isConnectedToNetwork() == false {
            showNoInternetAlert()
        }

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.title = "PFG: HOW TO FISH"
        startSlideShow()
        
        if self.revealViewController() != nil {
            self.revealViewController().delegate = self
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        stopSlideShow()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    deinit {
        
    }
    
    // MARK: - Button Tap Handler -
    
    @IBAction func handleButtonTap(sender: AnyObject) {
        
        guard buttonsEnabled else {
            return
        }
        
        // Use the button tag value to get the media category
        if let category: MediaCategory = categories![sender.tag]  {
            videos = ModelBuilder.sharedInstance.getMediaObjectsForCategory(category)
            collectionTitle = category.displayName
            
            guard videos?.count > 0 else {
                return
            }
            
            performSegueWithIdentifier("presentVideoCollection", sender: self)
        }
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
    
    @IBAction func unwindToCategoryView(segue: UIStoryboardSegue) {
        print("unwindToCategoryView")
    }
    
    // MARK: - Alert -
    
    func showNoInternetAlert() {
        
        let message = "This app requires an internet connection for some functions"
        let alertView: UIAlertController = UIAlertController(title: "NO INTERNET CONNECTION",
            message:  message,
            preferredStyle: UIAlertControllerStyle.Alert)
        
        alertView.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertView, animated: true, completion: nil)
        
    }
    
    func revealController(revealController: SWRevealViewController!, didMoveToPosition position: FrontViewPosition) {
        if position == FrontViewPosition.Right {
            print("Right")
            self.buttonsEnabled = false
        } else {
            print("Left")
            self.buttonsEnabled = true
        }
    }
    
}

