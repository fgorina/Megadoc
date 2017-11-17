//
//  Document.swift
//  Megadoc
//
//  Created by Francisco Gorina Vanrell on 14/11/17.
//  Copyright © 2017 Francisco Gorina. All rights reserved.
//

import UIKit

class Document: UIDocument {
    
    var contingut = ""
    
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        //return Data()
        
        return contingut.data(using: .utf8)!
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
        
        if contents is Data {
            let dcontent = contents as! Data
            contingut = String(data: dcontent, encoding: .utf8)!
            
        }
        
    }
}

