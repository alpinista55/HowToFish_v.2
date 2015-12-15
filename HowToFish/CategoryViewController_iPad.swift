//
//  CategoryViewController_iPad.swift
//  HowToFish
//
//  Created by Kerr, James on 12/8/15.
//  Copyright © 2015 Columbia Sportswear Company. All rights reserved.
//

import Foundation
import RealmSwift
import SafariServices

class CategoryViewController_iPad: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    SFSafariViewControllerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var categories: Results<MediaCategory>?
    var selectedCategory: Int?
    @IBOutlet weak var imageView: UIImageView!
    
    //slideshow
    var images = Array<UIImage>()
    var slideshowTimer: NSTimer?
    var slideCounter = 0;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "COLUMBIA SPORTSWEAR FISHING TIPS & TRICKS"
        
        loadImages()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        getMediaCategories()
        startSlideShow()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        stopSlideShow()
    }
    
    func getMediaCategories() {
        let realm = try! Realm()
        
        categories = realm.objects(MediaCategory).sorted("id")
        collectionView.reloadData()
    }
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if categories == nil {
            return 0
        }
        return categories!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell: CategoryCollectionViewCell_iPad = collectionView.dequeueReusableCellWithReuseIdentifier("categoryCell_iPad", forIndexPath: indexPath) as! CategoryCollectionViewCell_iPad
        
        let myCategory: MediaCategory = categories![indexPath.item]
        
        cell.imageView.image = UIImage(named: myCategory.thumbnailName!)
        cell.categoryLabel.text = myCategory.displayName
        return cell
    }
    
    // MARK: - Slideshow
    
    func loadImages() {
        
        let imageNames = ["SplashImage_01_iPad", "SplashImage_02_iPad", "SplashImage_03_iPad"]
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

    
    // MARK: - Navigation -
    
    @IBAction func unwindToCategoryViewController(segue: UIStoryboardSegue) {
        print("unwind to categoryVC")
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedCategory = indexPath.item
        
        performSegueWithIdentifier("presentVideoPlayer", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "presentVideoPlayer" {
            
            let controller: VideoSelectorViewController_iPad = segue.destinationViewController as! VideoSelectorViewController_iPad
            controller.categories = categories
            controller.selectedCategory = selectedCategory
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true;
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    
}
