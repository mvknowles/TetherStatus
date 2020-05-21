//
//  Errors.swift
//  tetherinfo
//
//  Created by Mark Knowles on 11/5/20.
//  Copyright © 2020 Mark Knowles. All rights reserved.
//

import Foundation

class StringError: LocalizedError {
    var message: String
    
    init(_ message: String) {
        self.message = message
     }
    
     init(format: String, _ vargs: String...) {
        self.message = String(format: format, vargs)
        //self.localizedDescription = message
     }
    
     public var errorDescription: String? {
        return NSLocalizedString(self.message, comment: "My error")
     }
}

class FatalError: StringError {
    
}
