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
    
    let realm = try! Realm()
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        
        // get the top view navigation controller and its containerView (root VC)
        let navController: UINavigationController = revealViewController().frontViewController as! UINavigationController
        let categoriesVC: CategoryViewController = storyboard!.instantiateViewControllerWithIdentifier("categoryViewController") as! CategoryViewController
        let collectionVC: VideoCollectionViewController = storyboard!.instantiateViewControllerWithIdentifier("collectionViewController") as! VideoCollectionViewController
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                collectionVC.collectionTitle = "Favorites"
                collectionVC.videos = realm.objects(LocalMediaObject).filter("isFavorite = true").sorted("dateAdded", ascending: false)
                
            } else {
                collectionVC.collectionTitle = "Recent"
                collectionVC.videos = realm.objects(LocalMediaObject).filter("isRecent = true").sorted("dateAdded", ascending: false)
            }
        } else if indexPath.section == 1 {
            
            switch indexPath.row {
            case 0:
                collectionVC.collectionTitle = "Fishing Basics"
                collectionVC.videos = realm.objects(LocalMediaObject).filter("heroTag = 'Fishing Basics'").sorted("title", ascending: true)
            case 1:
                collectionVC.collectionTitle = "Fishing Hardware"
                collectionVC.videos = realm.objects(LocalMediaObject).filter("heroTag = 'Tackle'").sorted("title", ascending: true)
            case 2:
                collectionVC.collectionTitle = "Freshwater Fishing"
                collectionVC.videos = realm.objects(LocalMediaObject).filter("heroTag = 'Freshwater Fishing'").sorted("title", ascending: true)
            case 3:
                collectionVC.collectionTitle = "Saltwater Fishing"
                collectionVC.videos = realm.objects(LocalMediaObject).filter("heroTag = 'Saltwater Fishing'").sorted("title", ascending: true)
            case 4:
                collectionVC.collectionTitle = "Fly Fishing"
                collectionVC.videos = realm.objects(LocalMediaObject).filter("heroTag = 'Fly Fishing'").sorted("title", ascending: true)
            default:
                return
            }
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
                //let shopPFGVC: ShopPFGViewController = storyboard!.instantiateViewControllerWithIdentifier("shopPFGViewController") as! ShopPFGViewController
                //let shopPFGVC = SFSafariViewController(URL: NSURL(string: "http://columbia.com/pfg")!)
                //shopPFGVC.navigationItem.title = "Shop Columbia PFG"
                navController.setViewControllers([categoriesVC], animated: false)
                NSNotificationCenter.defaultCenter().postNotificationName("kUserDidSelectShopPFG", object: nil)
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
