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

protocol WatermarkConfigurationProtocol {
    var style: WatermarkStyle {get set}
    //    var contents: Any {get set}
    var angle: CGFloat {get set}
    var lineSpace: CGFloat {get set}
    
    func configurationProperties(in page: PDFPage , context: CGContext, box: PDFDisplayBox)
}

//MARK: - Image watermark
struct ImageWatermarkConfiguration: WatermarkConfigurationProtocol {
    
    var lineSpace: CGFloat
    
    /// 样式
    var style: WatermarkStyle = .tile
    
    let contents: UIImage
    let alpha: CGFloat
    
    /// [0...90], [-90...0]
    var angle: CGFloat = 0
    
    func configurationProperties(in page: PDFPage, context: CGContext, box: PDFDisplayBox) {
        
        let pageBounds = page.bounds(for: box)
        
        // convert cooridiate system
        context.translateBy(x: 0.0, y: pageBounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        
        // image size
        let imageSize = contents.size
        switch style {
        case .tile:
            
            // rotate 45° counterClockwise (+ 顺时针，- 逆时针)
            let radiusAngle: CGFloat
            if angle != 0 {
                radiusAngle = (CGFloat.pi / (180.0 / angle))
            }else {
                radiusAngle = 0
            }
            context.rotate(by: radiusAngle)
            
            let interSpace = lineSpace
            // singlePlace width
            let singlePlaceWidth = imageSize.width + interSpace
            
            let singlePlaceHeight = imageSize.height + interSpace
            
            // diagonal line width
            let diagonalLineWidth = sqrt(pow(pageBounds.width, 2) + pow(pageBounds.height, 2))
            
            // force ceil
            let count = Int(ceil(diagonalLineWidth  / singlePlaceWidth))
            
            let yCount = Int(ceil(diagonalLineWidth / singlePlaceHeight))
            
            let maxCount = max(count, yCount)
            
            let deltaY = (imageSize.height + lineSpace) / cos(radiusAngle)
            //            let lineCount = Int(pageBounds.width / deltaY)
            
            let range = 0..<maxCount
            var xNegativeArray = Array(range)
            var yNegativeArray = Array(range)
            if angle == 0 {
            }else if angle > 0 {
                let newRange = -(maxCount - 1)...(maxCount - 1)
                yNegativeArray = Array(newRange)
            }else {
                let newRange = -(maxCount - 1)...(maxCount - 1)
                xNegativeArray = Array(newRange)
            }
            
            for i in xNegativeArray {
                for j in yNegativeArray {
                    let point = CGPoint(x: 0 + singlePlaceWidth * CGFloat(i), y: deltaY * CGFloat(j))
                    contents.draw(at: point, blendMode: .normal, alpha: alpha)
                }
            }
            
        case .center:
            // draw point
            let x = (pageBounds.width - imageSize.width) * 0.5
            let y = (pageBounds.height - imageSize.height) * 0.5
            let point = CGPoint(x: x, y: y)
            
            //            let image = WaterImage.getWaterMark(contents, angle: angle)
            let image = WatermarkImage.watermarkImage(from: contents, angle: angle)
            image.draw(at: point, blendMode: CGBlendMode.normal, alpha: alpha)
            
        }
        
    }
    
}

//MARK: - Text watermark
struct TextWatermarkConfiguration: WatermarkConfigurationProtocol {
    
    /// 样式
    var style: WatermarkStyle = .tile
    
    /// text
    let contents: String
    let textColor: UIColor
    let font: UIFont
    
    
    /// [0...90], [-90...0]
    var angle: CGFloat = 0
    var lineSpace: CGFloat
    
    
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
            let interSpace: CGFloat = 20
            
            let attributeString = NSAttributedString(string: contents, attributes: attribues)
            let cellSize = attributeString.size()
            
            let pageBounds = page.bounds(for: box)
            
            // convert cooridiate system
            context.translateBy(x: 0.0, y: pageBounds.size.height)
            context.scaleBy(x: 1.0, y: -1.0)
            
            let context = UIGraphicsGetCurrentContext()
            
            //将绘制原点（0，0）调整到源image的中心
            context?.concatenate(CGAffineTransform(translationX: pageBounds.width/2, y: pageBounds.height/2))
            //以绘制原点为中心旋转
            context?.concatenate(CGAffineTransform(rotationAngle:  CGFloat.pi * angle / 180))
            //将绘制原点恢复初始值，保证当前context中心和源image的中心处在一个点(当前context已经旋转，所以绘制出的任何layer都是倾斜的)
            context?.concatenate(CGAffineTransform(translationX: -pageBounds.width/2, y: -pageBounds.height/2))
            
            // singlePlace width
            let singlePlaceWidth = cellSize.width + interSpace
            let singlePlaceHeight = cellSize.height + lineSpace
            // diagonal line width
            let diagonalLineWidth = sqrt(pow(pageBounds.width, 2) + pow(pageBounds.height, 2))
            
            // force ceil
            //            let count = Int(ceil(diagonalLineWidth - cellSize.width) / singlePlaceWidth)
            let horCount = Int(ceil(diagonalLineWidth / singlePlaceWidth))
            let verCount = Int(ceil(diagonalLineWidth / singlePlaceHeight))
            
            
            //此处计算出需要绘制水印文字的起始点，由于水印区域要大于图片区域所以起点在原有基础上移
            let orignX = -(diagonalLineWidth - pageBounds.width) / 2
            let orignY = -(diagonalLineWidth - pageBounds.height) / 2
            
            //在每列绘制时X坐标叠加
            var tempOrignX = orignX
            //在每行绘制时Y坐标叠加
            var tempOrignY = orignY
            
            for i in  0..<(horCount * verCount) {
                attributeString.draw(in: CGRect(x: tempOrignX, y: tempOrignY, width: cellSize.width, height: cellSize.height))
                if (i % horCount == 0 && i != 0) {
                    tempOrignX = orignX
                    tempOrignY += (cellSize.height + lineSpace)
                }else {
                    tempOrignX += (cellSize.width + interSpace)
                }
            }
            
        case .center:
            let attributeString = NSAttributedString(string: contents, attributes: attribues)
            let cellSize = attributeString.size()
            
            let pageBounds = page.bounds(for: box)
            
            // convert cooridiate system
            context.translateBy(x: 0.0, y: pageBounds.size.height)
            context.scaleBy(x: 1.0, y: -1.0)
            
            // draw point
            let x = (pageBounds.width - cellSize.width) * 0.5
            let y = (pageBounds.height - cellSize.height) * 0.5
            let point = CGPoint(x: x, y: y)
            
            let context = UIGraphicsGetCurrentContext()
            
            //将绘制原点（0，0）调整到源image的中心
            context?.concatenate(CGAffineTransform(translationX: pageBounds.width/2, y: pageBounds.height/2))
            //以绘制原点为中心旋转
            context?.concatenate(CGAffineTransform(rotationAngle:  CGFloat.pi * angle / 180))
            //将绘制原点恢复初始值，保证当前context中心和源image的中心处在一个点(当前context已经旋转，所以绘制出的任何layer都是倾斜的)
            context?.concatenate(CGAffineTransform(translationX: -pageBounds.width/2, y: -pageBounds.height/2))
            //先将原始image绘制上
            attributeString.draw(at: point)
            
        }
    }
    
}
