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

class VideoCollectionViewController: UICollectionViewController, UIGestureRecognizerDelegate, UIPopoverPresentationControllerDelegate {
    
    var collectionTitle: String?
    var videos: Results<LocalMediaObject>!
    var selectedMediaObject: LocalMediaObject?
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var homeButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        self.title = collectionTitle!.uppercaseString
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = "revealToggle:"
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
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
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        // Reload the collectionView when returning from the MediaPlayer to reflect the recentDOwnload state change
        self.collectionView?.reloadData()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
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
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedMediaObject = videos[indexPath.row]
        performSegueWithIdentifier("presentVideoPlayer", sender: self)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        var cellWidth = collectionView.frame.width/2
        cellWidth -= 30
        return CGSize(width: cellWidth, height: cellWidth * 0.7)
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
    
//    func showOptionsForMediaObject(lmo: LocalMediaObject) {
//        
//        // Create the OptionsVC
//        let storyboard = UIStoryboard(name: "Main_iPhone", bundle: nil)
//        let vc = storyboard.instantiateViewControllerWithIdentifier("optionsViewController") as! OptionsViewController
//        vc.lmo = lmo
//        vc.parentVC = parentVC!
//        parentVC!.optionsVC = vc
//        
//        
//        // create blocking view
//        parentVC!.blockingView = UIView(frame: parentVC!.view.bounds)
//        parentVC!.blockingView!.backgroundColor = UIColor(red: 0.10, green: 0.1, blue: 0.1, alpha: 0.5)
//        parentVC!.view.addSubview(parentVC!.blockingView!);
//        
//        // Add gesture recognixzr to blocking view targeting the OptionsVC
//        let tapRecognizer = UITapGestureRecognizer(target: parentVC!.optionsVC!, action: "dismissOptionsVC:")
//        parentVC!.blockingView!.addGestureRecognizer(tapRecognizer)
//        
//        // Add child and its view to parent
//        parentVC!.addChildViewController(parentVC!.optionsVC!)
//        parentVC!.view.addSubview(parentVC!.optionsVC!.view)
//        parentVC!.optionsVC!.didMoveToParentViewController(parentVC!)
//        
//        // Position the view offscreen and animate it to final position centered in parent view
//        let parentFrame = parentVC!.view.bounds
//        var startFrame = parentFrame
//        
//        startFrame.origin.y = parentFrame.size.height
//        startFrame.size.width = 300
//        startFrame.size.height = 310
//        startFrame.origin.x = (parentVC!.view.bounds.size.width - startFrame.size.width) / 2
//        parentVC!.optionsVC!.view.frame = startFrame
//        
//        var endFrame = startFrame
//        endFrame.origin.y = (parentFrame.size.height - endFrame.size.height) / 2
//        
//        UIView.animateWithDuration(0.25) { () -> Void in
//            self.parentVC!.optionsVC!.view.frame = endFrame
//        }
//    }
    
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
    
    func showMenu() {
        
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
    
    @IBAction func goHome(sender: AnyObject) {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
}