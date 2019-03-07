//
//  RecipesTableViewCell.swift
//  Recipes
//
//  Created by Andrey Dolgushin on 05/03/2019.
//  Copyright © 2019 Andrey Dolgushin. All rights reserved.
//

import UIKit

final class RecipesTableViewCell: UITableViewCell {
    
    // MARK: - Constants
    
    // MARK: - Outlets
    @IBOutlet weak var cellContentView: UIView!
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var mainImageNetworkIndicator: UIActivityIndicatorView! {
        didSet {
            self.mainImageNetworkIndicator.isHidden = true
        }
    }
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var recipeDescription: UILabel!
    @IBOutlet weak var updateLabel: UILabel!
    @IBOutlet weak var updateLabelStubLeadingConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    private var shadowLayer: CAShapeLayer!
    private var cornerRadius: CGFloat = 10.0
    /// Set updateLabel text
    public var lastUpdated: String? {
        didSet {
            // Fix right constrained label SkeletonView bug
            // just remove left stub constraint when skeleton is hidden
            self.removeStubConstraints()
            
            self.updateLabel.text = self.lastUpdated
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.baseInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        self.baseInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // set shadow layer
        if self.shadowLayer != nil {
            self.shadowLayer.removeFromSuperlayer()
            self.shadowLayer = nil
        }
        self.shadowLayer = CAShapeLayer()
        
        var shadowRect = self.cellContentView.bounds
        shadowRect.size.width = self.bounds.size.width - 2*self.cellContentView.frame.origin.x
        self.shadowLayer.path = UIBezierPath(roundedRect: shadowRect, cornerRadius: cornerRadius).cgPath
        self.shadowLayer.fillColor = UIColor.white.cgColor
        
        self.shadowLayer.shadowColor = UIColor.black.cgColor
        self.shadowLayer.shadowPath = self.shadowLayer.path
        self.shadowLayer.shadowOffset = .zero
        self.shadowLayer.shadowOpacity = 0.2
        self.shadowLayer.shadowRadius = 3.0
        
        self.cellContentView.layer.insertSublayer(shadowLayer, at: 0)
    }
    
    func baseInit() {
        self.isSkeletonable                 = true
        self.cellContentView.isSkeletonable = true
        
        // Set rounded corners to content view
        self.cellContentView.layer.cornerRadius = self.cornerRadius
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: - Helpers
    /// Fix SkeletonView bug
    fileprivate func removeStubConstraints() {
        guard let constraint = self.updateLabelStubLeadingConstraint else {
            return
        }
        NSLayoutConstraint.deactivate([constraint])
        self.updateLabelStubLeadingConstraint = nil
    }
    
    /// Format recipe last update date to human friendly string
    func lastUpdateFormatted(lastUpdate date: Date?) -> String? {
        guard let date = date else {
            return nil
        }
        let intervalSinceNow = -date.timeIntervalSinceNow
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle    = .full
        formatter.allowedUnits  = [.year, .month, .day, .hour, .minute]
        
        let result = formatter.string(from: intervalSinceNow)
        
        return result != nil ? result! + " ago" : ""
    }
}

extension RecipesTableViewCell: NibInstantiable {
    static func nimbName() -> String {
        return String(describing: self)
    }
    
    static func instantiateFromNib() -> RecipesTableViewCell {
        return UINib(nibName: nimbName(), bundle: nil).instantiate(withOwner: nil, options: nil).first as! RecipesTableViewCell
    }
}

extension RecipesTableViewCell: CellReuseIdentifiable {
    static func reuseIdentifier() -> String {
        return String(describing: self)
    }
}
