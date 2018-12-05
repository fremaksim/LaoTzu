
//
//  DocumentFileFolder.swift
//  LaoTzuPDF
//
//  Created by mozhe on 2018/12/5.
//  Copyright © 2018 mozhe. All rights reserved.
//

import Foundation


// File Path
struct DocumentFileFolder {
    
    /// Documents/Inbox
    /// Use this directory to access files that your app was asked to open by outside entities
    
    static let LaoTzuDocumentFileFolder: String = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("Inbox") as String
    
    static let LaoTzuDocumentFileCopyPath: String = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("LaoTzu") as String
    
    
}
