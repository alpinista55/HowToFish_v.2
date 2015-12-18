//
//  VideoPlayerContainerViewController_iPad.swift
//  HowToFish
//
//  Created by Kerr, James on 12/8/15.
//  Copyright © 2015 Columbia Sportswear Company. All rights reserved.
//

import Foundation
import RealmSwift
import SafariServices

class VideoSelectorViewController_iPad: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UIGestureRecognizerDelegate,
    SFSafariViewControllerDelegate {
    
    //UI
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var basicsButton: UIButton!
    @IBOutlet weak var hardwareButton: UIButton!
    @IBOutlet weak var freshwaterButton: UIButton!
    @IBOutlet weak var saltwaterButton: UIButton!
    @IBOutlet weak var flyfishingButton: UIButton!
    @IBOutlet weak var favoritesButton: UIButton!
    @IBOutlet weak var recentsButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    
    var buttons = [UIButton]()
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var favAndRecentsMessageLable: UILabel!
    @IBOutlet weak var videoPlayerContainerView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    var categories: Results<MediaCategory>?
    var videos: Results<LocalMediaObject>?
    var selectedCategory: Int?
    var selectedMediaObject: LocalMediaObject?
    
    var mediaPlayerVC: MediaPlayerViewController?
    
    // MARK: - LifeCycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "COLUMBIA SPORTSWEAR FISHING TIPS & TRICKS"
        
        buttons = [basicsButton, hardwareButton, freshwaterButton, saltwaterButton, flyfishingButton, favoritesButton, recentsButton]
        let category = categories![selectedCategory!]
        setSelectedButton(selectedCategory!)
        videos = ModelBuilder.sharedInstance.getMediaObjectsForCategory(category)

        collectionView.allowsMultipleSelection = false
        mediaPlayerVC = self.childViewControllers.last as? MediaPlayerViewController
        
        //Add gesture recognizer for showing the OptionsViewController
        let lpgr : UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        lpgr.minimumPressDuration = 0.5
        lpgr.delegate = self
        lpgr.delaysTouchesBegan = true
        self.collectionView?.addGestureRecognizer(lpgr)
        
        // Listen for changes made in the OptionsViewController  and MenuViewControllerso we can reload the collectionView
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "videoOptionsChanged:", name: "kVideoOptionsDidChange", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "shareVideo:", name: "kUserDidSelectShare", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "settingsChanged:", name: "kUserDidChangeSettings", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showBackgroundImageview", name: "kVideoDidPlayToEnd", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadDataAfterReturnFromBackground", name: "kApplicationDidBecomeActive", object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)

    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true;
    }
    
    // MARK: - CollectionView DataSource -
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! VideoCollectionViewCell
        cell.prepareForReuse()
        
        if cell.selected {
            //print("cell selected")
            cell.backgroundColor = CSC_Colors.csc_blue
            cell.titleLabel.textColor = UIColor.whiteColor()
        }
        
        if let mediaObj: LocalMediaObject = videos![indexPath.row] {
            cell.titleLabel.text = mediaObj.title
            
            // NOTE: Changed to embedded png thumbnails instead of downloaded jpgs
            
            //let thumbFilename = "CSC_" + String(mediaObj.sequenceNumber) + "_thumb.jpg" // Downloaded jpgs
            let thumbFilename = "CSC_HowTo_" + String(mediaObj.sequenceNumber) + "_thumb" // Embedded pngs
            
            //cell.imageView.image = UIImage(contentsOfFile: filePathForImageNamed(thumbFilename)) // Downloaded jpgs
            cell.imageView.image = UIImage(named: thumbFilename) // Embedded pngs

            if  mediaObj.isFavorite {
                cell.iconImageView.image = UIImage(named: "StarOnOrange_small")
            } else if mediaObj.isRecent {
                cell.iconImageView.image = UIImage(named: "DownloadOnOrange_small")
            }
            
            if mediaObj.isHD {
                cell.hdLabel.hidden = false
            }
        }
        
        return cell
    }
    
    func reloadDataAfterReturnFromBackground() {
        collectionView?.reloadData()
    }
    
    // MARK: - CollectionView Delegate Methods -
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        selectedMediaObject = videos![indexPath.item]
        
        // Check for local media and present if local
        guard selectedMediaObject!.isRecent || selectedMediaObject!.isFavorite else {
            
            // Check for network availability and present if internet is available
            guard Reachability.isConnectedToNetwork() else {
                let message = "Please connect to the internet before downloading new videos."
                showAlertViewWithMessage(message)
                return
            }
            
            presentVideoForIndexPath(indexPath)
            return
        }
        
        presentVideoForIndexPath(indexPath)
    }
    
    func presentVideoForIndexPath(indexPath: NSIndexPath) {
        let cells = collectionView.visibleCells()
        
        // Reset all cell appearence
        for var index = 0; index < cells.count; index++ {
            let cell = cells[index] as! VideoCollectionViewCell
            cell.backgroundColor = UIColor.whiteColor()
            cell.titleLabel.textColor = CSC_Colors.csc_blue
        }
        
        // Set up the selected cells appearence and the NAvigationBar title
        let cell: VideoCollectionViewCell = collectionView.cellForItemAtIndexPath(indexPath) as! VideoCollectionViewCell
        cell.backgroundColor = CSC_Colors.csc_blue
        cell.titleLabel.textColor = UIColor.whiteColor()
        let titleString = selectedMediaObject!.title! + " with " + videos![indexPath.item].spokesPerson!
        navigationItem.title = titleString.uppercaseString
        
        // Give the selected media object to the player and play
        mediaPlayerVC!.mediaObj = selectedMediaObject!
        mediaPlayerVC!.playMedia()
        
        UIView.animateWithDuration(0.25) { () -> Void in
            self.backgroundImageView.alpha = 0.0
        }

    }
    
    // Builds the filePath for the thumbnail images
    func filePathForImageNamed(imageName: String) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory: AnyObject = paths[0]
        let thumbnailsPath = documentsDirectory.stringByAppendingPathComponent("thumbnails/" + imageName)
        return thumbnailsPath
        
    }
    
    // MARK: - Category Button Handler -
    
    @IBAction func handleButtonTap(sender: AnyObject) {
        
        favAndRecentsMessageLable.text = ""
        favAndRecentsMessageLable.hidden = true
        
        let button: UIButton = sender as! UIButton
        
        setSelectedButton(button.tag)
        
        switch button.tag  {
        case 0, 1, 2, 3, 4:
            let category = categories![button.tag]
            videos = ModelBuilder.sharedInstance.getMediaObjectsForCategory(category)
        case 5:
            videos = ModelBuilder.sharedInstance.getFavorites()
            if videos!.count == 0 {
                favAndRecentsMessageLable.text = "No videos in your favorites.\nTap and hold on a video thumbnail to show the Options panel."
                favAndRecentsMessageLable.hidden = false
            }
        case 6:
            videos = ModelBuilder.sharedInstance.getRecent()
            if videos!.count == 0 {
                favAndRecentsMessageLable.text = "No videos have been downloaded"
                favAndRecentsMessageLable.hidden = false
            }
        default:
            return
        }
        
        collectionView.reloadData()
    }
    
    func setSelectedButton(index: Int) {
        for button in buttons {
            button.enabled = true
            button.backgroundColor = CSC_Colors.csc_blue
        }
        
        buttons[index].enabled = false
        buttons[index].backgroundColor = UIColor.whiteColor()
    }
    
    // MARK: - Long Press Gesture Handling -
    
    func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
        
        if (gestureRecognizer.state != UIGestureRecognizerState.Began){
            return
        }
        
        let locInView = gestureRecognizer.locationInView(self.collectionView)
        
        // Returns false if point is not over a cell
        if let indexPath : NSIndexPath = (self.collectionView?.indexPathForItemAtPoint(locInView)){
            showOptionsForMediaObject(videos![indexPath.item], origin: locInView)
        }
        
    }
    
    // MARK: - Options Popover -
    
    func showOptionsForMediaObject(lmo: LocalMediaObject, origin: CGPoint) {
        
        // Create the OptionsVC
        let storyboard = UIStoryboard(name: "Main_iPhone", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("optionsViewController") as! OptionsViewController
        vc.lmo = lmo
        
        vc.modalPresentationStyle = .Popover
        
        if let vcPopoverPresentationController = vc.popoverPresentationController{
            vcPopoverPresentationController.sourceView = self.collectionView
            vcPopoverPresentationController.permittedArrowDirections = [.Any]
            vcPopoverPresentationController.sourceRect = CGRectMake(origin.x, origin.y, 0.0, 0.0)
        }
        presentViewController(vc, animated: true, completion: nil)
    }

    
    func videoOptionsChanged(notification: NSNotification) {
        
        // Check for userInfo. If present, the medias isFavorite property was changed
        // If the media was added to favorites and has not been downloaded, play the media to force download
        if let userInfo = notification.userInfo {
            if let lmo = userInfo["lmo"] as? LocalMediaObject {
                
                if !lmo.isRecent && lmo.isFavorite {
                    mediaPlayerVC?.mediaObj = lmo
                    mediaPlayerVC?.playMedia()
                }
            }
        }
        collectionView.reloadData()
    }
    
    func settingsChanged(notification: NSNotification) {
        collectionView.reloadData()
    }
    
    // MARK: - Sharing -
    
    func shareVideo(notification: NSNotification) {
        
        // Get the user info from the notification
        let targetVideo = notification.userInfo!["lmo"] as! LocalMediaObject
        let shareTypeInt = notification.userInfo!["shareType"] as! Int
        
        //Check for email send ability
        if shareTypeInt == ShareType.email.rawValue {
            if SharingManager.sharedInstance.canSendEmail() == false {
                print("No EMail")
                return
            }
        }
        
        //Check for text send ability
        if shareTypeInt == ShareType.message.rawValue {
            if SharingManager.sharedInstance.canSendText() == false {
                print("No Messaging")
                return
                
            }
        }
        
        // Get the correct interface from the sharing manager and present
        if let sharingVC = SharingManager.sharedInstance.share(targetVideo, theShareType: shareTypeInt) {
            presentViewController(sharingVC, animated: true, completion: nil)
        } else {
            print("No sharing VC")
        }
        
    }
    
    func showBackgroundImageview() {
        UIView.animateWithDuration(0.25) { () -> Void in
            self.backgroundImageView.alpha = 1.0
        }
    }
    
    // MARK: - Alert View -
    
    func showAlertViewWithMessage(message: String) {
        let alertView: UIAlertController = UIAlertController(title: "ERROR",
            message: message,
            preferredStyle: UIAlertControllerStyle.Alert)
        
        alertView.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertView, animated: true, completion: nil)
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            self.performSegueWithIdentifier("unwindToCollectionView", sender: self)
        }
        
    }

    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
