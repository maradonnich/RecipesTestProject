//
//  Recipe.swift
//  Recipes
//
//  Created by Andrey Dolgushin on 04/03/2019.
//  Copyright © 2019 Andrey Dolgushin. All rights reserved.
//

import UIKit
import CoreData

class Recipe: NSManagedObject {
    struct ResponseAttributeNames {
        static let uuid         = "uuid"
        static let name         = "name"
        static let images       = "images"
        static let lastUpdated  = "lastUpdated"
        static let description  = "description"
        static let instructions = "instructions"
        static let difficulty   = "difficulty"
    }
    
    /**
     Initialize recipe instance using raw dictionary data.
     
     - Parameter recipeInfo: recipe raw dictionary containing recipe's object attributes.
     - Parameter insertInto: insert initilized instance to specified managed context.
     */
    convenience init(recipeInfo: [String: Any?], insertInto context: NSManagedObjectContext) {
        self.init(context: context)
        
        let uuidString          = recipeInfo[ResponseAttributeNames.uuid] as? String ?? ""
        let imagesString        = recipeInfo[ResponseAttributeNames.images] as? [String] ?? [String]()
        
        self.uuid               = UUID(uuidString: uuidString)
        self.name               = recipeInfo[ResponseAttributeNames.name] as? String
        self.images             = imagesString.count > 0 ? imagesString.map{ URL(string: $0)! } : nil
        self.lastUpdated        = recipeInfo[ResponseAttributeNames.lastUpdated] as? TimeInterval != nil ? Date(timeIntervalSince1970: recipeInfo[ResponseAttributeNames.lastUpdated] as! TimeInterval) : nil
        self.recipeDescription  = recipeInfo[ResponseAttributeNames.description] as? String
        self.instructions       = recipeInfo[ResponseAttributeNames.instructions] as? String
        self.difficulty         = recipeInfo[ResponseAttributeNames.difficulty] as? Int16 ?? 1
    }
}
