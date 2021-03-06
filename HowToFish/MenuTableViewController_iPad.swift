//
//  MenuViewController_iPad.swift
//  HowToFish
//
//  Created by Kerr, James on 12/10/15.
//  Copyright © 2015 Columbia Sportswear Company. All rights reserved.
//

import Foundation

class MenuTableViewController_iPad: UITableViewController {
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let sb: UIStoryboard = UIStoryboard(name: "Main_iPhone", bundle: NSBundle.mainBundle())
        
        switch indexPath.row {
        case 0:
            let controller: SettingsViewController = sb.instantiateViewControllerWithIdentifier("settingsViewController") as! SettingsViewController
            controller.isPopOver = true
            navigationController?.pushViewController(controller, animated: true)
        case 1:
            let controller: AboutViewController = sb.instantiateViewControllerWithIdentifier("aboutViewController") as! AboutViewController
            controller.isPopover = true
            navigationController?.pushViewController(controller, animated: true)
        default:
            dismissViewControllerAnimated(true, completion: { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName("kUserDidSelectShopPFG", object: nil)
            })
        }
    }
}
