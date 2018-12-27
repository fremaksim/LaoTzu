//
//  DataExtension.swift
//  LaoTzuPDF
//
//  Created by mozhe on 2018/12/26.
//  Copyright © 2018 mozhe. All rights reserved.
//

import Foundation
import PDFKit

extension Data {
    func scanValue<T: SignedInteger>(start: Int, length: Int) -> T {
        return self.subdata(in: start..<start+length).withUnsafeBytes {
            (pointer: UnsafePointer<T>) -> T in
            return pointer.pointee
        }
    }
}

extension PDFDocumentWriteOption {
     public static let mozheOption: PDFDocumentWriteOption = PDFDocumentWriteOption(rawValue: "mozhePDFwrite")
}

extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined() //406b8cf76092cbf2713f18a2613d687e
    }
}
