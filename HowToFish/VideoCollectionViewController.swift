//
//  VideoCollectionViewController.swift
//  HowToFish
//
//  Created by Kerr, James on 11/20/15.
//  Copyright © 2015 Columbia Sportswear Company. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift
import MessageUI

let reuseIdentifier = "videoCollectionCell"

class VideoCollectionViewController: UICollectionViewController,
    UIGestureRecognizerDelegate,
    UIPopoverPresentationControllerDelegate,
    SWRevealViewControllerDelegate {
    
    // Model
    var collectionTitle: String?
    var videos: Results<LocalMediaObject>!
    var selectedMediaObject: LocalMediaObject?
    
    // UI
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var homeButton: UIBarButtonItem!
    
    // MARK: - LifeCycle -
    
    override func viewDidLoad() {
        self.title = collectionTitle!.uppercaseString
        
        // Config SWRevealViewController
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = "revealToggle:"
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            self.revealViewController().delegate = self
        }

        
        //Add gesture recognizer for showing the OptionsViewController
        let lpgr : UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        lpgr.minimumPressDuration = 0.5
        lpgr.delegate = self
        lpgr.delaysTouchesBegan = true
        self.collectionView?.addGestureRecognizer(lpgr)
        
        // Listen for changes made in the OptionsViewController so we can reload the collectionView
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "videoOptionsChanged:", name: "kVideoOptionsDidChange", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "shareVideo:", name: "kUserDidSelectShare", object: nil)
        
        // Listen for return from background, so that we reload the collectionView in case recent videos were deleted
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadDataAfterReturnFromBackground", name: "kApplicationDidBecomeActive", object: nil)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        // Reload the collectionView when returning from the MediaPlayer to reflect the recentDownload state change
        self.collectionView?.reloadData()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - CollectionView DataSource -
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Video count = \(videos.count)")
        return videos.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
            
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! VideoCollectionViewCell
        cell.prepareForReuse()
        
        if let mediaObj: LocalMediaObject = videos[indexPath.row] {
            cell.titleLabel.text = mediaObj.title
            
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
    
    // Builds the filePath for the thumbnail images
    func filePathForImageNamed(imageName: String) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory: AnyObject = paths[0]
        let thumbnailsPath = documentsDirectory.stringByAppendingPathComponent("thumbnails/" + imageName)
        return thumbnailsPath

    }
    
    func reloadDataAfterReturnFromBackground() {
        collectionView?.reloadData()
    }
    
    // MARK: - CollectionView Delegate -
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedMediaObject = videos[indexPath.row]
        
        // Check for network availability if media is not local
        guard selectedMediaObject!.isRecent || selectedMediaObject!.isFavorite else {
            
            guard Reachability.isConnectedToNetwork() else {
                let message = "Please connect to the internet before downloading new videos."
                showAlertViewWithMessage(message)
                return
            }
            
            // Perform segue results in video being downloaded and played
            performSegueWithIdentifier("presentVideoPlayer", sender: self)
            return
        }
        
        // Perform segue results in local media being played
        performSegueWithIdentifier("presentVideoPlayer", sender: self)
    }
    
    // Resize the collectionViewCell width for different screen widths in iPhone
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let totalHorizontalPadding = CGFloat(30.0)
        let ratio = CGFloat(9.0/16.0)
        let titleLabelHeight = CGFloat(30.0)
        let cellWidth = collectionView.frame.width/2 - totalHorizontalPadding/2
        let cellHeight = cellWidth * ratio + titleLabelHeight

        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    // MARK: - Long Press Gesture Handling -
    
    func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
        
        if (gestureRecognizer.state != UIGestureRecognizerState.Began){
            return
        }
        
        let locInView = gestureRecognizer.locationInView(self.collectionView)
        
        // Returns false if point is not over a cell
        if let indexPath : NSIndexPath = (self.collectionView?.indexPathForItemAtPoint(locInView)){
            showOptionsForMediaObject(videos[indexPath.item], origin: locInView)
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
            vcPopoverPresentationController.delegate = self
            vcPopoverPresentationController.sourceView = self.collectionView
            vcPopoverPresentationController.permittedArrowDirections = [.Any]
            vcPopoverPresentationController.sourceRect = CGRectMake(origin.x, origin.y, 0.0, 0.0)
        }
        presentViewController(vc, animated: true, completion: nil)
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
            return .None
    }
    
    // Reload the collectionView after changes are made in the OptionsViewController
    func videoOptionsChanged(notification: NSNotification) {
        // Check for userInfo. If present, the medias isFavorite property was changed
        // If the media was added to favorites and has not been downloaded, play the media to force download
        if let userInfo = notification.userInfo {
            if let lmo = userInfo["lmo"] as? LocalMediaObject {
                
                if !lmo.isRecent && lmo.isFavorite {
                    selectedMediaObject = lmo
                    performSegueWithIdentifier("presentVideoPlayer", sender: self)
                }
            }
        }
        collectionView!.reloadData()
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
    
    //Mark Segue Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "presentVideoPlayer" {
            let controller: MediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
            controller.mediaObj = selectedMediaObject
            
            
        }
    }
    
    @IBAction func unwindToCollectionView(segue: UIStoryboardSegue) {
        print("unwindToCollectionView")
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    func showAlertViewWithMessage(message: String) {
        let alertView: UIAlertController = UIAlertController(title: "ERROR",
            message: message,
            preferredStyle: UIAlertControllerStyle.Alert)
        
        alertView.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertView, animated: true, completion: nil)
        
    }
    
    func revealController(revealController: SWRevealViewController!, didMoveToPosition position: FrontViewPosition) {
        if position == FrontViewPosition.Right {
            print("Right")
            self.collectionView?.userInteractionEnabled = false
        } else {
            print("Left")
            self.collectionView?.userInteractionEnabled = true
        }
    }
}