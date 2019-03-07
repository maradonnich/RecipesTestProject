//
//  RecipesAPIRouter.swift
//  Recipes
//
//  Created by Andrey Dolgushin on 04/03/2019.
//  Copyright © 2019 Andrey Dolgushin. All rights reserved.
//

import Foundation
import Alamofire

enum RecipesAPIRouter: URLRequestConvertible {
    // MARK: - Constatns fileds
    static let baseURL      = "https://test.kode-t.ru"
    
    struct ResponseAttributeNames {
        static let error            = "error"
        static let errorDescription = "message"
        static let recipesArray     = "recipes"
    }
    
    // MARK: - Network errors definitions
    enum RecipesAPIRouterErrors: Error {
        case receivedFromServerError(description: String)
        case unknownError
        
        // NSError compatible methods definition
        enum RecipesAPIRouterCodes: Int {
            case
            receivedFromServerErrorCode = 1000,
            unknownErrorCode            = 1001
        }
        
        var code: RecipesAPIRouterCodes {
            switch self {
            case .receivedFromServerError:
                return RecipesAPIRouterCodes.receivedFromServerErrorCode
            default:
                return RecipesAPIRouterCodes.unknownErrorCode
            }
        }
        
        var localizedDescription: String {
            switch self {
            case .receivedFromServerError(let description):
                return description
            default:
                return "Unknown error has been occuried."
            }
        }
        
        /**
         Create corresponding error instance for NSError-compatible methods.

         - Returns: Corresponding application bundle domain NSError.
         */
        func error() -> NSError {
            return NSError(domain: Bundle.main.bundleIdentifier!,
                           code: self.code.rawValue,
                           userInfo: [NSLocalizedDescriptionKey : self.localizedDescription])
        }
    }
    
    // MARK: - Enum cases
    case getAllRecipes()
    
    // Specify attributes passing method for appropriate HTTP-request
    fileprivate var method: HTTPMethod {
        switch self {
        case .getAllRecipes():
            return .get
        }
    }
    
    // ... request's URI
    fileprivate var path: String {
        switch self {
        case .getAllRecipes():
            return "/recipes.json"
        }
    }
    
    // ... HTTP-headers applied to request
    fileprivate var headers: [String: String] {
        let headersDict = [String: String]()
        
        switch self {
        default:
            break
        }
        
        return headersDict
    }
    
    // MARK: - URLRequestConvertible protocol implementation
    func asURLRequest() throws -> URLRequest {
//        var params: [String: Any]?
        let requestBaseURL = URL(string: RecipesAPIRouter.baseURL)!
        var request = try URLRequest(url: requestBaseURL.appendingPathComponent(self.path),
                                     method: self.method,
                                     headers: self.headers)
        
        switch self {
        case .getAllRecipes():
            request = try JSONEncoding.default.encode(request, with: nil)
        }
        
        debugPrint(request)
        
        return request
    }
    
    
    /**
     It defines whether received JSON response contains external(web service)/internal(decoding and etc.) errors or it has been handled successfully. And return result in more convinient way.
     
     - Parameter responseJSON: JSON data response.
     - Returns: The tuple of success and error **RecipesAPIRouterErrors** enumeration object defined here internally.
     */
    static func validate(responseJSON response: DataResponse<Any>) -> (success: Bool, error: RecipesAPIRouterErrors) {
        let json: [String: AnyObject]?
        let success: Bool
        let errorDescription: String?
        let error: RecipesAPIRouterErrors
        switch response.result {
        case .success(let value):
            json                = value as? [String: AnyObject]
            let errorDict       = json?[ResponseAttributeNames.error] as? [String: AnyObject]
            errorDescription    = errorDict?[ResponseAttributeNames.errorDescription] as? String
            success             = errorDict == nil
            if let errorDescription = errorDescription {
                error = RecipesAPIRouterErrors.receivedFromServerError(description: errorDescription)
            } else {
                error = RecipesAPIRouterErrors.unknownError
            }
        case .failure(let errorOccurred):
            json                = nil
            success             = false
            
            errorDescription    = (errorOccurred as NSError).localizedDescription
            if let errorDescription = errorDescription {
                error = RecipesAPIRouterErrors.receivedFromServerError(description: errorDescription)
            } else {
                error = RecipesAPIRouterErrors.unknownError
            }
        }
        
        return (success: success, error: error)
    }
}
