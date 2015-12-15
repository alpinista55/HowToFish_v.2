//
//  SharingManager.swift
//  HowToFish
//
//  Created by Kerr, James on 12/3/15.
//  Copyright © 2015 Columbia Sportswear Company. All rights reserved.
//

import Foundation
import Social
import Accounts
import MessageUI

enum ShareType: Int {
    case email = 0
    case message
    case facebook
    case twitter
}

class SharingManager: NSObject, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate{
    
    static let sharedInstance = SharingManager()
    
    func share(lmo: LocalMediaObject, theShareType: Int) -> UIViewController? {
        let choice: ShareType = ShareType(rawValue: theShareType)!
        switch choice {
        case ShareType.email:
            return shareWithEmail(lmo)
        case ShareType.message:
            return shareWithMessage(lmo)
        case ShareType.facebook:
            return shareToFacebook(lmo)
        case ShareType.twitter:
            return shareToTwitter(lmo)
        }
    }
    
    func shareToFacebook(lmo: LocalMediaObject) -> UIViewController {
        let facebookVC: SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
        facebookVC.setInitialText("Check out this great how-to video from Columbia Sportswear called \(lmo.title!). Thanks, Columbia!")
        facebookVC.addURL(NSURL(string: lmo.websiteURL!))
        return facebookVC
    }
    
    func shareToTwitter(lmo: LocalMediaObject) -> UIViewController {
        let twitterVC: SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
        twitterVC.setInitialText("Check out this great how-to video from Columbia Sportswear called \(lmo.title!). Thanks, Columbia!")
        twitterVC.addURL(NSURL(string: lmo.websiteURL!))
        return twitterVC
    }
    
    func shareWithEmail(lmo: LocalMediaObject) -> UIViewController {
        let emailVC = MFMailComposeViewController()
        emailVC.setSubject("Great PFG How to Fish Video from Columbia")
        emailVC.setMessageBody("Check out this great how-to video from Columbia Sportswear called \(lmo.title!). Thanks, Columbia!", isHTML: true)
        emailVC.mailComposeDelegate = self
        return emailVC
    }
    
    func shareWithMessage(lmo: LocalMediaObject) -> UIViewController {
        let messageVC = MFMessageComposeViewController()
        messageVC.messageComposeDelegate = self
        messageVC.body = "Check out this great how-to video from Columbia Sportswear called \(lmo.title!).\n\(lmo.websiteURL!)"
        return messageVC
    }
    
    func canSendEmail() -> Bool {
        if MFMailComposeViewController.canSendMail() {
            return true
        }
        return false
    }
    
    func canSendText() -> Bool {
        if MFMessageComposeViewController.canSendText() {
            return true
        }
        return false
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }

    
}