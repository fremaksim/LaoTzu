//
//  WatermarkConfiguration.swift
//  LaoTzuPDF
//
//  Created by mozhe on 2018/12/7.
//  Copyright © 2018 mozhe. All rights reserved.
//

import Foundation
import UIKit
import PDFKit

enum WatermarkStyle {
    case tile   //平铺
    case center //居中
}

struct WatermarkConfiguration {
    
    /// 样式
    var style: WatermarkStyle = .tile
    
    /// text
    let contents: String
    let textColor: UIColor
    let font: UIFont
    
    
    /// [0...90], [-90...0]
    var angle: CGFloat = 0
    let lineSpace: CGFloat
    
    
    func configurationProperties(in page: PDFPage , context: CGContext, box: PDFDisplayBox) {
        let attributes = [
            NSAttributedString.Key.foregroundColor: textColor,
            NSAttributedString.Key.font: font
        ]
        calculateDisplayMultiLines(page: page, box: box, context: context, attribues: attributes)
    }
    
    private func calculateDisplayMultiLines(
        page: PDFPage,
        box: PDFDisplayBox,
        context: CGContext,
        attribues: [NSAttributedString.Key: Any]) {
        
        switch style {
        case .tile:
            let interSpace: CGFloat = 5.0
            
            let attributeString = NSAttributedString(string: contents, attributes: attribues)
            let cellSize = attributeString.size()
            
            let pageBounds = page.bounds(for: box)
            
            // convert cooridiate system
            context.translateBy(x: 0.0, y: pageBounds.size.height)
            context.scaleBy(x: 1.0, y: -1.0)
            
            // rotate 45° counterClockwise (+ 顺时针，- 逆时针)
            let radiusAngle = (CGFloat.pi / (180.0 / angle))
            context.rotate(by: radiusAngle)
            
            // singlePlace width
            let singlePlaceWidth = cellSize.width + interSpace
            
            // diagonal line width
            let diagonalLineWidth = sqrt(pow(pageBounds.width, 2) + pow(pageBounds.height, 2))
            
            // force ceil
            let count = Int(ceil(diagonalLineWidth - cellSize.width) / singlePlaceWidth)
            
            let newAttributeString: NSMutableAttributedString = NSMutableAttributedString(attributedString: attributeString)
            for _ in 0...count {
                // inter placeholder
                newAttributeString.append(NSMutableAttributedString(string:"        "))
                newAttributeString.append(attributeString)
            }
            // maximun text width
            let maximumTextWidth = newAttributeString.size().width
            
            // draw Center
            newAttributeString.draw(at: CGPoint.zero)
            
            let deltaY = (cellSize.height + lineSpace) / cos(radiusAngle)
            let lineCount = Int(pageBounds.width / deltaY)
            
            // attach Y
            let attachXAttributeString: NSMutableAttributedString = NSMutableAttributedString(attributedString: newAttributeString)
            
            if lineCount > 1 {
                
                let range = 1...lineCount
                var negativeRage = (-lineCount)...(-1)
                if angle <= 0 {
                    negativeRage = (lineCount + 1)...(2 * lineCount)
                }
                let array = Array(range)
                var negativeArray = Array(negativeRage)
                negativeArray.append(contentsOf: array)
                
                for i in negativeArray {
                    // angle is postive
                    if angle > 0 {
                        attachXAttributeString.draw(at: CGPoint(x: 0, y: deltaY * CGFloat(i)))
                    }else{// angle is negative
                        attachXAttributeString.draw(at: CGPoint(x: -maximumTextWidth * 0.5, y: deltaY * CGFloat(i)))
                    }
                }
            }
            
        case .center:
            let attributeString = NSAttributedString(string: contents, attributes: attribues)
            let cellSize = attributeString.size()
            
            let pageBounds = page.bounds(for: box)
            
            // convert cooridiate system
            context.translateBy(x: 0.0, y: pageBounds.size.height)
            context.scaleBy(x: 1.0, y: -1.0)
            
            // rotate 45° counterClockwise (+ 顺时针，- 逆时针)
            if angle != 0 {
            let radiusAngle = (CGFloat.pi / (180.0 / angle))
            context.rotate(by: radiusAngle)
            }
            
            // draw point
            let x = (pageBounds.width - cellSize.width) * 0.5
            let y = (pageBounds.height - cellSize.height) * 0.5
            let point = CGPoint(x: x, y: y)
            attributeString.draw(at: point)
            
            
        }
  
    }
    
    
}
