//
//  VideoPlayerViewController.swift
//  HowToFish
//
//  Created by Kerr, James on 11/23/15.
//  Copyright © 2015 Columbia Sportswear Company. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation
import RealmSwift


struct Resolution {
    var width = 0
    var height = 0
}

enum filePathError: ErrorType {
    case FileNotFound
}

extension filePathError: CustomStringConvertible {
    var description: String {
        switch self {
        case .FileNotFound: return "A file was not found for the supplied file name and type"
        }
    }
}

extension Int {
    var degreesToRadians : CGFloat {
        return CGFloat(self) * (CGFloat(M_PI) / 180.0)
    }
}



class MediaPlayerViewController: AVPlayerViewController, NSURLSessionDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate {
    
    var playerLayer: AVPlayerLayer?
    var mediaObj: LocalMediaObject?
    var expectedContentLength = 0
    var buffer: NSMutableData = NSMutableData()
    var destinationURL: NSURL?
    var progressHUD: MBProgressHUD?
    var videoDownloadSession: NSURLSession?
    var coverView: UIImageView?
    
    private var myContext = 0
    
    
    // MARK: - Life Cycle -
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.translatesAutoresizingMaskIntoConstraints = true
        
        self.showsPlaybackControls = false
        
        // iPad cover view
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            coverView = UIImageView(frame: CGRectMake(0.0, 0.0, 1024.0, 576.0))
            coverView!.image = UIImage(named: "SelectAVideoBelow")
            coverView!.userInteractionEnabled = false
            self.view.addSubview(coverView!)
        }
        
        // If there is a url for the selected media then load it
        if let mediaURL = urlForMedia() {
            loadVideoAsync(mediaURL)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        removePlayer()
        
    }
    
    func playMedia() {
        
        removePlayer()
        
        if let mediaURL = urlForMedia() {
            loadVideoAsync(mediaURL)
        }
    }
    
    // MARK: - Video Download -
    
    // Set up an NSURLSession object
    func setupSession() {
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.timeoutIntervalForRequest = 20
        sessionConfig.timeoutIntervalForResource = 60
        videoDownloadSession = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        buffer = NSMutableData()
    }
    
    // Returns the URL for the selected mediaObject, or nil
    func urlForMedia() -> NSURL? {
        var path: String
        if mediaObj != nil {
            if mediaObj!.isHD {
                path = mediaObj!.mediaURL720p!
            } else {
                path = mediaObj!.mediaURL!
            }
            if let url: NSURL = NSURL(string: path) {
                return url
            }
        }
        return nil
    }

    
    // Checks for local media, and downloads the video to the device if file not found
    func loadVideoAsync(url: NSURL) -> Void {
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as NSURL!
        if let tempURL = documentsUrl.URLByAppendingPathComponent(url.lastPathComponent!) as NSURL!{
            self.destinationURL = tempURL

            if NSFileManager().fileExistsAtPath(destinationURL!.path!) {
                print("file already exists [\(destinationURL!.path!)]")
                playVideo()
            }
            else {
                
                // Check for network availability
                guard Reachability.isConnectedToNetwork() else {
                    let message = "Please connect to the internet before downloading new videos."
                    showAlertViewWithMessage(message)
                    return
                }
                
                setupSession()
                let request = NSMutableURLRequest(URL: url)
                request.HTTPMethod = "GET"
                let task = videoDownloadSession!.dataTaskWithRequest(request)
                
                task.resume()
                
                progressHUD  = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
                
                let tapRecognizer: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: "cancelDownload:")
                progressHUD?.addGestureRecognizer(tapRecognizer)
                progressHUD!.mode = MBProgressHUDMode.Determinate
                let hudTitleString = mediaObj!.isHD ? "LOADING VIDEO IN HD" : "LOADING VIDEO IN SD"
                progressHUD!.labelText = hudTitleString
                progressHUD!.detailsLabelText = "Tap to cancel download"
                progressHUD!.show(true)
            }
        }
    }
    
    func cancelDownload(tapRecognizer: UITapGestureRecognizer) {
        //print("Cancel Download")
        videoDownloadSession?.invalidateAndCancel()
    }
    
    
    
    // MARK: - NSURLSessionDelegate Methods -
    
    // Recieved Response
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        
        let httpResponse = response as! NSHTTPURLResponse
        
        //print("\n\n---------------\n\n")
        //print("Status Code: \(httpResponse.statusCode)")
        //print("Response: \(response)\n\n----------------\n\n")
        
        // Cancel the session if response status is not "OK"
        guard httpResponse.statusCode == 200 else {
            completionHandler(NSURLSessionResponseDisposition.Cancel)
            dispatch_async(dispatch_get_main_queue()) {
                self.progressHUD?.hide(true)
            }
            return
        }
        
        expectedContentLength = Int(response.expectedContentLength)
        //print("expectedContentLength = \(expectedContentLength)")
        completionHandler(NSURLSessionResponseDisposition.Allow)
        
    }
    
    // Recieved Data
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        
        buffer.appendData(data)
        
        let percentageDownloaded = Float(buffer.length) / Float(expectedContentLength)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.progressHUD?.progress = percentageDownloaded
        }
        
        //print("Percent downloaded: \(percentageDownloaded)")
    }
    
    // Task Completed
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) -> Void {
        
        // Present an alert if the download failed for any reason
        if error != nil {
            print("ErrorDownloading Video: \(error!.localizedDescription)")
            dispatch_async(dispatch_get_main_queue()) {
                self.progressHUD?.hide(true)
                let message = "There was a problem downloading the selected video. Please try again later, or tap and hold to show the streaming option."
                self.showAlertViewWithMessage(message)
                
            }
            return
        }
        
        // If Successful download, save the file locally and play video
        print("Completed download")
        
        // Save the file
        if self.buffer.writeToURL(self.destinationURL!, atomically: true) {
            print("file saved")
        }
        let filePath = self.destinationURL!.path

        self.buffer = NSMutableData()
        var fileSize : UInt64 = 0
        
        // Get the file size for saving to the localMediaObject
        do {
            let attr : NSDictionary? = try NSFileManager.defaultManager().attributesOfItemAtPath(filePath!)
            
            if let _attr = attr {
                fileSize = _attr.fileSize();
            }
        } catch {
            print("Error: \(error)")
        }
        
        // On the main thread, save localMediaObject, post notification, hide the HUD and call playVideo
        dispatch_async(dispatch_get_main_queue()) {
            
            self.saveToRealmWithSize(fileSize)
            NSNotificationCenter.defaultCenter().postNotificationName("kVideoOptionsDidChange", object: nil)
            self.progressHUD?.hide(true)
            print("Playing Video")
            self.playVideo()
        }
        
    }
    
    func saveToRealmWithSize(filesize: UInt64) {
        
        let realm = try! Realm()
        try! realm.write {
            self.mediaObj!.dateAdded = NSDate(timeIntervalSinceNow: 0.0)
            self.mediaObj!.isRecent = true
            self.mediaObj!.fileSize = Int64(filesize)
        }
    }
    
    // MARK: - AVPlayer -
    
    func playVideo() {
        // Create the AVPlayer and play the video
        if let videoURL = destinationURL {
            
            player = AVPlayer(URL: videoURL)
            playerLayer = AVPlayerLayer(player: player)
            
            self.view.layer.addSublayer(playerLayer!)
            self.showsPlaybackControls = true // Call this here to avoid autoLayout warnings from the playback control view
            
            // Register for notification of video reaching the end
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "videoPlaybackComplete:", name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
            
            // Add KVO to player status
            // NOTE: need to supply a context so that the AVPlayerViewController observeValueForKeyPath method is not overridden
            
            player!.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: &myContext)
            
            player!.play()
            
            print("Setting destinationURL to nil")
            destinationURL = nil
            
        }
    }
    
    // MARK: - CoverView for iPad
    
    // Hide the coverView when the video status changes to ReadyToPlay
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            if keyPath == "status" {
                if player!.status == AVPlayerStatus.ReadyToPlay {
                    //print("Ready to play")
                    hideCoverView()
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
        
    }
    
    func showCoverView() {
        if let cv = coverView {
            if player!.status == AVPlayerStatus.ReadyToPlay {
                //print("Ready to play")
            }
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                cv.alpha = 1.0
            })
        }
    }
    
    func hideCoverView() {
        if let cv = coverView {
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                cv.alpha = 0.0
            })
        }
    }
    
    // MARK: - Clean Up Methods -
    
    // Called when player reports playback reached the end
    func videoPlaybackComplete(notification: NSNotification) {
        
        print("Video Playback Complete")
        
        removePlayer()
        
        // Unwind if iPhone
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            performSegueWithIdentifier("unwindToCollectionView", sender: self)
        }
    }
    
    // Delete the player and show the coverView
    func removePlayer() {
        if player != nil {
            player!.pause()
            showCoverView()
            player!.removeObserver(self, forKeyPath: "status")
            playerLayer!.removeFromSuperlayer()
            playerLayer = nil
            player = nil
            print("Player is nil")
        }
    }
    
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        print("Deinit")
    }
    
    
}