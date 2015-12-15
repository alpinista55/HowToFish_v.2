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
    
    
    @IBOutlet weak var favAndRecentsMessageLable: UILabel!
    @IBOutlet weak var videoPlayerContainerView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    var categories: Results<MediaCategory>?
    var videos: Results<LocalMediaObject>?
    var selectedCategory: Int?
    
    var mediaPlayerVC: MediaPlayerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "COLUMBIA SPORTSWEAR FISHING TIPS & TRICKS"
        
        buttons = [basicsButton, hardwareButton, freshwaterButton, saltwaterButton, flyfishingButton, favoritesButton, recentsButton]
        let category = categories![selectedCategory!]
        setSelectedButton(selectedCategory!)
        getVideosForCategory(category)
        collectionView.allowsMultipleSelection = false
        mediaPlayerVC = self.childViewControllers.last as? MediaPlayerViewController
        
        //Add gesture recognizer for showing the OptionsViewController
        let lpgr : UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        lpgr.minimumPressDuration = 0.5
        lpgr.delegate = self
        lpgr.delaysTouchesBegan = true
        self.collectionView?.addGestureRecognizer(lpgr)
        
        // Listen for changes made in the OptionsViewController so we can reload the collectionView
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "videoOptionsChanged:", name: "kVideoOptionsDidChange", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "shareVideo:", name: "kUserDidSelectShare", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "settingsChanged:", name: "kUserDidChangeSettings", object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)

    }
    
    func getVideosForCategory(category: MediaCategory) {
        let realm = try! Realm()
        videos = realm.objects(LocalMediaObject).filter("heroTag = '\(category.heroTag!)'").sorted("title", ascending: true)
    }
    
    func getFavorites() {
        let realm = try! Realm()
        videos = realm.objects(LocalMediaObject).filter("isFavorite = true").sorted("title", ascending: true)
        if videos!.count == 0 {
            favAndRecentsMessageLable.text = "No videos in your favorites.\nTap and hold on a video thumbnail to show the Options panel."
            favAndRecentsMessageLable.hidden = false
        }
    }
    
    func getRecent() {
        let realm = try! Realm()
        videos = realm.objects(LocalMediaObject).filter("isRecent = true").sorted("title", ascending: true)
        if videos!.count == 0 {
            favAndRecentsMessageLable.text = "No videos have been downloaded"
            favAndRecentsMessageLable.hidden = false
        }
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
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let lmoSelected = videos![indexPath.item]
        
        let cells = collectionView.visibleCells()
        
        for var index = 0; index < cells.count; index++ {
            let cell = cells[index] as! VideoCollectionViewCell
            cell.backgroundColor = UIColor.whiteColor()
            cell.titleLabel.textColor = CSC_Colors.csc_blue
        }
        
        let cell: VideoCollectionViewCell = collectionView.cellForItemAtIndexPath(indexPath) as! VideoCollectionViewCell
        cell.backgroundColor = CSC_Colors.csc_blue
        cell.titleLabel.textColor = UIColor.whiteColor()
        let titleString = lmoSelected.title! + " with " + videos![indexPath.item].spokesPerson!
        navigationItem.title = titleString.uppercaseString
        mediaPlayerVC!.mediaObj = lmoSelected
        
        print("path = \(lmoSelected.mediaURL)")
        mediaPlayerVC!.playMedia()
        
    }
    
    // Builds the filePath for the thumbnail images
    func filePathForImageNamed(imageName: String) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory: AnyObject = paths[0]
        let thumbnailsPath = documentsDirectory.stringByAppendingPathComponent("thumbnails/" + imageName)
        return thumbnailsPath
        
    }
    
    // MARK: - Button Handler -
    
    @IBAction func goHome(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func handleButtonTap(sender: AnyObject) {
        
        favAndRecentsMessageLable.text = ""
        favAndRecentsMessageLable.hidden = true
        
        let button: UIButton = sender as! UIButton
        
        setSelectedButton(button.tag)
        
        switch button.tag  {
        case 0, 1, 2, 3, 4:
            let category = categories![button.tag]
            getVideosForCategory(category)
        case 5:
            getFavorites()
        case 6:
            getRecent()
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
    
    override func prefersStatusBarHidden() -> Bool {
        return true;
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
    
    func showMenu() {
        
    }

    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
