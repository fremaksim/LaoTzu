
//
//  FindEOF.swift
//  LaoTzuPDF
//
//  Created by mozhe on 2018/12/27.
//  Copyright © 2018 mozhe. All rights reserved.
//

import Foundation
//// hex进制  %%PDF
//let EndOfFile: [UInt8] = [0x25, 0x25, 0x45, 0x4F, 0x46]

// 10进制  %%PDF.
//let EndOfFile: [UInt8] = [37, 37, 69, 79, 70, 10]

// 10进制  %%PDF
//let EndOfFile: [UInt8] = [37, 37, 69, 79, 70]

private struct FileEndFlagData {
    
    static var PDF: [UInt8]   = [0x25, 0x25, 0x45, 0x4F, 0x46]
    static var PDF10: [UInt8] = [37, 37, 69, 79, 70]
    
}

public struct FindEOF {
    
    /// Find EOF location carry on completion with in turple(start,end) if true
    /// only for standard PDF file
    /// - Parameters:
    ///   - data: Source data only PDF not encrypted
    ///   - threshold: for quick find from data trailer
    ///   - completion: result callback
    static func find(data: Data,
                     threshold: Int = 1000,
                     completion: @escaping (_ : (Int, Int)?,_ : Bool)->()){
        let bytes = data.count
        let compareCount = FileEndFlagData.PDF10.count
        guard bytes > compareCount else {
            completion(nil,false)
            return
        }
        let count = bytes / compareCount
        //TODO: - (count - threshold) is dangerous
        var start = (count - threshold) * compareCount + 1
        var end   = start + compareCount
        DispatchQueue.global().async {
            for slice in stride(from: start, to: bytes, by: compareCount) {
                let sliceData = data.subdata(in: start..<end)
                print([UInt8](sliceData))
                let slices = [UInt8](sliceData)
                if FileEndFlagData.PDF10 == slices || FileEndFlagData.PDF == slices {
                    DispatchQueue.main.async {
                        completion((start,end),true)
                    }
                }
                start = slice + 1
                end   = start + compareCount
            }
        }
    }
    
    static func findEncrypted(data: Data,
                              threshold: Int = 1000,
                              completion: @escaping (_ : (Int, Int)?,_ : Bool)->()){
        
        //从后查找，加一分割法
        let bytes = data.count
        let compareCount = FileEndFlagData.PDF10.count
        guard bytes > compareCount else {
            completion(nil,false)
            return
        }
        let target = bytes - threshold
        
        var start = (bytes - compareCount)
        var end   = bytes
        //TODO: - to 0 or -1
        DispatchQueue(label: "com.mohist.findEOF").async {
            for slice in stride(from: bytes, to: target, by: -1){
                let sliceData = data.subdata(in: start..<end )
                let slices = [UInt8](sliceData)
                if FileEndFlagData.PDF10 == slices || FileEndFlagData.PDF == slices {
                    DispatchQueue.main.async {
                        completion((start+compareCount,end+compareCount),true)
                    }
                    break
                }
                start = (slice - compareCount)
                end   = slice
            }
        }
    }
}
