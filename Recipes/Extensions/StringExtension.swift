//
//  StringExtensio.swift
//  Recipes
//
//  Created by Andrey Dolgushin on 07/03/2019.
//  Copyright © 2019 Andrey Dolgushin. All rights reserved.
//

import Foundation
import UIKit

extension String {
    func htmlAttributed(options dict: NSDictionary?) -> NSAttributedString? {
        do {
            guard let data = data(using: String.Encoding.utf8) else {
                return nil
            }
            
            var dict:NSDictionary?
            dict = NSMutableDictionary()
            
            return try NSAttributedString(data: data,
                                          options: [.documentType: NSAttributedString.DocumentType.html,
                                                     .characterEncoding: String.Encoding.utf8.rawValue],
                                          documentAttributes: &dict)
        } catch {
            print("error: ", error)
            return nil
        }
    }
    
    func htmlAttributed(using font: UIFont) -> NSAttributedString? {
        do {
            let htmlCSSString = "<style>" +
                "html *" +
                "{" +
                "font-size: \(font.pointSize)pt !important;" +
//                "color: #\(color.hexString!) !important;" +
                "font-family: \(font.familyName), Helvetica !important;" +
            "}</style> \(self)"
            
            guard let data = htmlCSSString.data(using: String.Encoding.utf8) else {
                return nil
            }
            
            return try NSAttributedString(data: data,
                                          options: [.documentType: NSAttributedString.DocumentType.html,
                                                    .characterEncoding: String.Encoding.utf8.rawValue],
                                          documentAttributes: nil)
        } catch {
            print("error: ", error)
            return nil
        }
    }
}
