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
// 存取原则， 怎么存，怎么取， string utf8 存就得 string utf8 取， Int，Double,.. 存， Int，Double 取。

// 在iOS 64为系统中，
public protocol PDFTailerable {
    var length: Data { get set }
    var version: Data { get set }
    var id: Data { get set }
    var extend: Data? { get set }
}

public protocol PDFAppendable {
    
    /// <#Description#>
    ///
    /// - Parameter tailer: <#tailer description#>
    /// - Returns: <#return value description#>
    func appending(tailer: PDFTailerable) -> Data
    
    
    func retrieve(completion: @escaping (_: PDFTailer) -> () )
    
    
}

public protocol PDFRemoveable {
    
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

public typealias PDFHandlerable = PDFAppendable & PDFRemoveable


public struct PDFTailer: PDFTailerable {
    
    public var length: Data
    
    public var version: Data
    
    public var id: Data
    
    public var extend: Data?
    
    public init(length: Data, version: Data, id: Data, extend: Data? = nil) {
        self.length = length
        self.version = version
        self.id = id
        self.extend = extend
    }
    
    public func getLength() -> Int? {
        if let str = String(data: length, encoding: .utf8) {
            return Int(str)
        }
        return nil
    }
    
    public func getVersion() -> Int? {
        if let str = String(data: version, encoding: .utf8) {
            return Int(str)
        }
        return nil
    }
    
    public func getId() -> Int {
        return id.to(type: Int.self)
    }
    
}


public class PDFHandler {
    
    let inputData: Data
    var appendedData = Data()
    
    public init(inputData: Data) {
        self.inputData = inputData
    }
    
}

extension PDFHandler: PDFHandlerable {
    
    public func appending(tailer: PDFTailerable) -> Data {
        var origin = inputData
        origin.append(tailer.length)
        origin.append(tailer.version)
        origin.append(tailer.id)
        if let extend = tailer.extend {
            origin.append(extend)
        }
        appendedData = origin
        return origin
    }
    
    public  func removedAppended(completion: @escaping (Data) -> ()) {
        // ToDo -- 1000kb
        var mutableOrigin = Data()
        FindEOF.findEncrypted(data: appendedData) { (index, isPdf) in
            if let end = index?.1 {
                mutableOrigin = mutableOrigin.subdata(in: 0..<end)
                completion(mutableOrigin)
            }
        }
    }
    
    public  func pop(completion: @escaping (Data) -> ()){
        // ToDo -- 1000kb
        var mutableOrigin = Data()
        FindEOF.findEncrypted(data: inputData) { (index, isPdf) in
            if let end = index?.1 {
                let begin = (end - FileEndFlagData.PDF10.count) + 1
                mutableOrigin = self.appendedData.subdata(in: begin..<self.appendedData.count)
                completion(mutableOrigin)
            }
        }
    }
    
    public func retrieve(completion: @escaping (PDFTailer) -> ()) {
        pop { (appendedData) in
            
            let lengthData = appendedData.subdata(in: 0..<4) // 长度: 4-byte
            
            let versionData = appendedData.subdata(in: 4..<8)// 版本: 4-byte
            
            let idData = appendedData.subdata(in: 8..<16)    // id: 8-byte
            
            let count = appendedData.count
            var extendData: Data? = nil
            if count > 16 {
                extendData = appendedData.subdata(in: 16..<count)
            }
            
            let tailer = PDFTailer(length: lengthData,
                                   version: versionData,
                                   id: idData,
                                   extend: extendData)
            completion(tailer)
        }
    }
    
}

// https://stackoverflow.com/questions/38023838/round-trip-swift-number-types-to-from-data
public extension Data {
    
    init<T>(from value: T) {
        self = Swift.withUnsafeBytes(of: value) { Data($0) }
    }
    
    func to<T>(type: T.Type) -> T {
        return self.withUnsafeBytes { $0.pointee }
    }
}

//let value = 42.13 // implicit Double
//let data = Data(from: value)
//print(data as NSData) // <713d0ad7 a3104540>
//
//let roundtrip = data.to(type: Double.self)
//print(roundtrip) // 42.13

public extension Data {
    
    //let str = String(data: self, encoding: .utf8)
    //    let data = "str".data(using: .utf8)
}
