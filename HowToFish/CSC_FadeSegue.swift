
//
//  CSC_FadeSegue.swift
//  HowToFish
//
//  Created by Kerr, James on 12/10/15.
//  Copyright © 2015 Columbia Sportswear Company. All rights reserved.
//

import Foundation
import QuartzCore

class CSC_FadeSegue: UIStoryboardSegue {
    
    override func perform() {
        let transition: CATransition = CATransition()
        transition.duration = 0.5
        transition.type = kCATransitionFade
        
        sourceViewController.view.window?.layer.addAnimation(transition, forKey: kCATransitionFade)
        sourceViewController.navigationController?.pushViewController(destinationViewController, animated: false)
    }
    
}
