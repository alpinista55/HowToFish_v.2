//
//  VideoCollectionViewCell.swift
//  HowToFish
//
//  Created by Kerr, James on 11/20/15.
//  Copyright © 2015 Columbia Sportswear Company. All rights reserved.
//

import Foundation

class VideoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var hdLabel: UILabel!
    
    
    required init(coder aDecoder: NSCoder)  {
        super.init(coder: aDecoder)!
        // make border pretty
        self.layer.borderWidth = 1.0;
        self.layer.cornerRadius = 1.0;
        self.layer.borderColor = UIColor(red: 210.0/255.0, green: 210.0/255.0, blue: 210.0/255.0, alpha: 1.0).CGColor
        
    }
    
    func viewDidLoad() {
        
    }
    
    override func prepareForReuse() {
        
        super.prepareForReuse()
        imageView.image = nil
        iconImageView.image = nil
        titleLabel.text = nil
        hdLabel.hidden = true
        self.titleLabel.textColor = CSC_Colors.csc_blue
        self.backgroundColor = UIColor.whiteColor()
    }
}