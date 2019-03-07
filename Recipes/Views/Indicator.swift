//
//  Indicator.swift
//  Recipes
//
//  Created by Andrey Dolgushin on 07/03/2019.
//  Copyright © 2019 Andrey Dolgushin. All rights reserved.
//

import UIKit

@IBDesignable class Indicator: UIView {

    // MARK: - Properties
    /// current indicator value in range 1...5
    @IBInspectable var value: UInt = 3 {
        willSet {
            if self.value < 1 {
                self.value = 1
            }
            if self.value > 5 {
                self.value = 5
            }
        }
        
        didSet {
            if self.value > 1 && self.value <= 5 {
                self.setNeedsDisplay()
            }
        }
    }
    
    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        baseInit()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        baseInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func baseInit() {
        
    }
    
    override func draw(_ rect: CGRect) {
        // Drawing code
        let rectWidth: CGFloat = 20
        let rectHeight: CGFloat = 10
        let rectsMargin: CGFloat = 5   // horizontal margin between neighbouring rects
        let leftX: CGFloat = 0.5*(rect.size.width - 5*(rectWidth + rectsMargin))
        
        for i in 1...5 {
            let rectPath = UIBezierPath(rect: CGRect(origin: CGPoint(x: leftX + CGFloat(i-1)*(rectWidth + rectsMargin),
                                                                     y: rect.height - CGFloat(i)*rectHeight),
                                                     size: CGSize(width: rectWidth, height: CGFloat(i)*rectHeight)))
            if i > self.value {
                UIColor.lightGray.setFill()
            } else {
                switch i {
                    case 1:
                        UIColor.green.setFill()
                    case 2:
                        UIColor.green.setFill()
                    case 3:
                        UIColor.yellow.setFill()
                    case 4:
                        UIColor(red: 1.0, green: 99/255.0, blue: 0, alpha: 1).setFill()
                    case 5:
                        UIColor.red.setFill()
                    default:
                        break
                }
            }
            
            rectPath.fill()
        }
    }
}
