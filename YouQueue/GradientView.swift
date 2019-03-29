//
//  GradientView.swift
//  YouQueue
//
//  Created by Case Wright on 3/27/19.
//  Copyright © 2019 Case Wright. All rights reserved.
//

import UIKit

class GradientView: UIView {
    override open class var layerClass: AnyClass {
        return CAGradientLayer.classForCoder()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let gradientLayer = layer as! CAGradientLayer
        gradientLayer.colors = [UIColor(red: 236/255.0, green: 57/255.0, blue: 60/255.0, alpha: 1).cgColor, UIColor(red: 245/255.0, green: 130/255.0, blue: 48/255.0, alpha: 1).cgColor]
    }
}
