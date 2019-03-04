//
//  MummyCachesProtocol.swift
//  MohistDataPersistenceModule
//
//  Created by mozhe on 2018/10/27.
//  Copyright © 2018 mozhe. All rights reserved.
//

import Foundation

public enum Directory {
    case documents
    case caches
}

public protocol MummyCachesProtocol {}

/// keyArchiver and keyUnarchiver
public protocol MummyCachesKeyArchiverUnArchiverable {
    func keyedArchiver<T: Codable>(path: URL, fileName: String, object: T) -> Bool
    func keyedUnArchiver<T: Codable>(path: URL, fileName: String, object: T.Type) -> T?
}

/// JSON Data Converts
public protocol MummyCachesJSONDatable: MummyCachesProtocol {
    
    func JSONToData(_ JSONResponse: AnyObject) -> Data?
    func dataToJSON(_ data: Data) -> AnyObject?
}

public protocol MummyCachesDataCodable {
    func store<T: Encodable>(_ object: T, to directory: Directory, as fileName: String)
    func retrieve<T: Decodable>(_ fileName: String, from directory: Directory, as type: T.Type) -> T
}

/// UserDefaults Preferences
public protocol MummyCachesUserDefaultsable {}

// TODO: -- CoreData
// TODO: -- SQLite3

