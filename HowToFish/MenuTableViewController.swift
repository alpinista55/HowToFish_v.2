//
//  MenuTableViewController.swift
//  HowToFish
//
//  Created by Kerr, James on 12/4/15.
//  Copyright © 2015 Columbia Sportswear Company. All rights reserved.
//

import Foundation
import RealmSwift
import SafariServices

class MenuTableViewController: UITableViewController {
    
    let categories = ModelBuilder.sharedInstance.getCategories()
    
    // NOTE: TableView is a static layout in IB Storyboard
    
    // MARK: - TableView Delegate -
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        
        // get the top view navigation controller and its containerView (root VC)
        let navController: UINavigationController = revealViewController().frontViewController as! UINavigationController
        let categoriesVC: CategoryViewController = storyboard!.instantiateViewControllerWithIdentifier("categoryViewController") as! CategoryViewController
        let collectionVC: VideoCollectionViewController = storyboard!.instantiateViewControllerWithIdentifier("collectionViewController") as! VideoCollectionViewController
        
        // Section 0 is Favorites and Recent
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                collectionVC.collectionTitle = "Favorites"
                collectionVC.videos = ModelBuilder.sharedInstance.getFavorites()
                
            } else {
                collectionVC.collectionTitle = "Recent"
                collectionVC.videos = ModelBuilder.sharedInstance.getRecent()
            }
            
        // Section 1 is Categories
        } else if indexPath.section == 1 {
            
            let category = categories[indexPath.row]
            collectionVC.collectionTitle = category.displayName
            collectionVC.videos = ModelBuilder.sharedInstance.getMediaObjectsForCategory(category)
            
        // Section 2 is Settings, About and Shop PFG
        } else {
            switch indexPath.row {
            case 0:
                let settingsVC: SettingsViewController = storyboard!.instantiateViewControllerWithIdentifier("settingsViewController") as! SettingsViewController
                navController.setViewControllers([categoriesVC, settingsVC], animated: false)
                revealViewController().setFrontViewPosition(FrontViewPosition.Left, animated: true)
                return
            case 1:
                let aboutVC: AboutViewController = storyboard!.instantiateViewControllerWithIdentifier("aboutViewController") as! AboutViewController
                navController.setViewControllers([categoriesVC, aboutVC], animated: false)
                revealViewController().setFrontViewPosition(FrontViewPosition.Left, animated: true)
                return
            case 2:
                navController.setViewControllers([categoriesVC], animated: false)
                NSNotificationCenter.defaultCenter().postNotificationName("kUserDidSelectShopPFG", object: nil) // Notification handled by NavigationController
                revealViewController().setFrontViewPosition(FrontViewPosition.Left, animated: true)
                return

            default:
                return
            }
        }
        
        navController.setViewControllers([categoriesVC, collectionVC], animated: false)
        revealViewController().setFrontViewPosition(FrontViewPosition.Left, animated: true)
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 10.0, height: tableView.bounds.width))
        headerView.backgroundColor = UIColor.lightGrayColor()
        return headerView
    }
    
}
