//
//  AboutViewController.swift
//  HowToFish
//
//  Created by Kerr, James on 12/7/15.
//  Copyright © 2015 Columbia Sportswear Company. All rights reserved.
//

import Foundation

class AboutViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    var menuButton: UIBarButtonItem?
    var homeButton: UIBarButtonItem?
    var isPopover: Bool = false
    
    
    var status = ""{
        didSet{textView.text = status}
    }
    
    override func viewDidLoad() {
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        navigationItem.title = "ABOUT THE APP"
        
        if isPopover == false {
            menuButton = UIBarButtonItem(image: UIImage(named: "Hamburger"), style: UIBarButtonItemStyle.Plain, target: self, action: nil)
            navigationItem.leftBarButtonItem = menuButton
            
            homeButton = UIBarButtonItem(image: UIImage(named: "House"), style: UIBarButtonItemStyle.Plain, target: self, action: "goHome:")
            navigationItem.rightBarButtonItem = homeButton
        }
        
        
        guard let rtfFile = NSDataAsset(name: "about_help_rtf") else {
            status = "Could not find the rtf file"
            return
        }
        
        let options = [
            NSDocumentTypeDocumentAttribute : NSRTFTextDocumentType,
            NSCharacterEncodingDocumentAttribute : NSUTF8StringEncoding
            ] as [String : AnyObject]
        
        
        do{
            let rtfString = try NSAttributedString(data: rtfFile.data, options: options, documentAttributes: nil)
            self.textView.attributedText = rtfString
            
        } catch let err{
            status = "Error = \(err)"
        }
        
        if self.revealViewController() != nil {
            menuButton!.target = self.revealViewController()
            menuButton!.action = "revealToggle:"
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
    }
    
    @IBAction func goHome(sender: AnyObject) {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
}
