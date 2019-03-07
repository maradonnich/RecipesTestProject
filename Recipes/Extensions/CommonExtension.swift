//
//  UIViewControllerExtension.swift
//  Recipes
//
//  Created by Andrey Dolgushin on 04/03/2019.
//  Copyright © 2019 Andrey Dolgushin. All rights reserved.
//

import Foundation
import UIKit

public protocol NibInstantiable {
    static func nimbName() -> String
    static func instantiateFromNib() -> Self
}

public protocol CellReuseIdentifiable {
    static func reuseIdentifier() -> String
}
