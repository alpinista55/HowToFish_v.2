//
//  iPadNavigationController.swift
//  HowToFish
//
//  Created by Kerr, James on 12/11/15.
//  Copyright © 2015 Columbia Sportswear Company. All rights reserved.
//

import Foundation
import SafariServices

class iPadNavigationController: UINavigationController, SFSafariViewControllerDelegate {
    
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "shopPFG:", name: "kUserDidSelectShopPFG", object: nil)
    }
    
    // MARK: - SafariViewController -
    
    func shopPFG(notification: NSNotification) {
        let svc = SFSafariViewController(URL: NSURL(string: "http://columbia.com/pfg")!)
        svc.delegate = self
        self.presentViewController(svc, animated: true, completion: nil)
    }
    
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
