//
//  WatermarkTransferModel.swift
//  LaoTzuPDF
//
//  Created by mozhe on 2019/1/7.
//  Copyright © 2019 mozhe. All rights reserved.
//

import UIKit

protocol WatermarkTextable {
    var fontScale: CGFloat? {set get}
    var text: String? {set get}
    
}

protocol WatermarkImageable {
    var image: Data? {set get}
}

class WatermarkTransferModel:
    WatermarkConfigurationProtocol,
WatermarkTextable,WatermarkImageable, Codable{
    static let defaultFilename = "WatermarkTransferModel.data"
    
    static var savedPath: String {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as NSString
        path.appendingPathComponent("WatermarkTransferModel.data")
        return path as String
    }
    
    var fontScale: CGFloat? = 30.0
    var text: String? = "Watermark"
    
    var alpha: CGFloat = 0.8
    
    var style: WatermarkStyle = .tile
    
    var angle: CGFloat = 0
    
    var lineSpace: CGFloat = 30
    
    var type: WatermarkType = .text
    
    var image: Data?
    
   /* init(type: WatermarkType = .text,
         style: WatermarkStyle = .tile,
         alpha: CGFloat = 0.8,
         angle: CGFloat = 0.0,
         lineSpace: CGFloat = 30,
         text: String? = "Watermark",
         fontScale: CGFloat? = 30,
         image: Data? = nil) {
        self .type = type
        self.style = style
        self.alpha = alpha
        self.angle = angle
        self.lineSpace = lineSpace
        self.text = text
        self.fontScale = fontScale
        self.image = image
    }
    */
}


