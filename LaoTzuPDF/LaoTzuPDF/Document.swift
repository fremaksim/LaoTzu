//
//  Document.swift
//  LaoTzuPDF
//
//  Created by mozhe on 2018/12/5.
//  Copyright © 2018 mozhe. All rights reserved.
//

import UIKit

class Document: UIDocument {
    
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        return Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
    }
}

extension Document {
    
    // file:///private/var/mobile/Containers/Data/Application/8D80C08E-E0C7-4E52-9C43-55E0CACEAB3A/Documents/Inbox/%E4%B8%9D%E8%B7%AF%E5%AE%89%E8%A3%85%E6%96%87%E6%A1%A3-8.pdf
    func isInDocumentInbox() -> Bool {
        return fileURL.path.contains("/Documents/Inbox/")
    }
    
}
