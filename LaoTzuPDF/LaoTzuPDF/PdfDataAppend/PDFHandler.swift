//
//  PDFHandler.swift
//  LaoTzuPDF
//
//  Created by mozhe on 2019/3/5.
//  Copyright © 2019 mozhe. All rights reserved.
//

import Foundation

/**
 // PDF追加格式
 |-------PDF标准格式文件---|-------   length  --------|--------  version ----------|---------- id ---------|----------- extend ----------|
 |-------PDF自有格式区域---|-------   4 bytes --------|--------  4 bytes ----------|-------8 bytes --------|----------- ****** ----------|
 |-------PDF自由格式区域---|-------   长度     --------|--------  版本号   ----------|------- 文件编码 --------|----------- 扩展   ----------|
 |-------PDF自有格式区域---|------------------------固定段 -------------------------------------------------|----------- 扩展段  ----------|
 扩展段长度 = length - 固定段长度
 
 // version版本对照表
 |---序号---|----值---|---说明---|
 |--- 1 ---|--- 1 ---|-版本V1.0-|
 |--- 2 ---|----  ---|---------|
 
 */

protocol PDFTailerable {
    var length: Data { get set }
    var version: Data { get set }
    var id: Data { get set }
    var extend: Data? { get set }
}

protocol PDFAppendable {
    
    /// <#Description#>
    ///
    /// - Parameter tailer: <#tailer description#>
    /// - Returns: <#return value description#>
    func appending(tailer: PDFTailerable) -> Data
    
}

protocol PDFRemoveable {

    /// <#Description#>
    ///
    /// - Parameter completion: <#completion description#>
    /// - Returns: <#return value description#>
    func removedAppended(completion: @escaping (_: Data) -> ())
    

    /// <#Description#>
    ///
    /// - Parameter completion: <#completion description#>
    func pop(completion: @escaping (_: Data) -> ())
}

typealias PDFHandlerable = PDFAppendable & PDFRemoveable


struct PDFTailer: PDFTailerable {
    
    var length: Data
    
    var version: Data
    
    var id: Data
    
    var extend: Data?
    
    init(length: Data, version: Data, id: Data, extend: Data? = nil) {
        self.length = length
        self.version = version
        self.id = id
        self.extend = extend
    }
    
    // 长度限制
    
}


class PDFHandler {
    
    let inputData: Data
    
    init(inputData: Data) {
        self.inputData = inputData
    }
    
}

extension PDFHandler: PDFHandlerable {
    
    func appending(tailer: PDFTailerable) -> Data {
        var origin = inputData
        origin.append(tailer.length)
        origin.append(tailer.version)
        origin.append(tailer.id)
        if let extend = tailer.extend {
            origin.append(extend)
        }
        return origin
    }
    
    func removedAppended(completion: @escaping (Data) -> ()) {
        // ToDo -- 1000kb
        var mutableOrigin = inputData
        FindEOF.find(data: inputData) { (index, isPdf) in
            if let end = index?.1 {
                mutableOrigin = mutableOrigin.subdata(in: 0..<end)
                completion(mutableOrigin)
            }
        }
    }
    
    func pop(completion: @escaping (Data) -> ()){
        // ToDo -- 1000kb
        var mutableOrigin = inputData
        FindEOF.find(data: inputData) { (index, isPdf) in
            if let end = index?.1 {
                mutableOrigin = mutableOrigin.subdata(in: end..<self.inputData.count)
                completion(mutableOrigin)
            }
        }
    }
    
}
