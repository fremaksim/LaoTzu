//
//  WatermarkImage.swift
//  LaoTzuPDF
//
//  Created by mozhe on 2018/12/25.
//  Copyright © 2018 mozhe. All rights reserved.
//

import UIKit

struct WatermarkImage {
    
    /// 原始图片旋转angle后的图片
    ///
    /// - Parameters:
    ///   - originalImage: 原始图片
    ///   - angle: 旋转角度
    /// - Returns: 旋转后的新图
    static func watermarkImage(from originalImage: UIImage, angle: CGFloat) -> UIImage {
        
        //原始image的宽高
        let viewWidth  = originalImage.size.width
        let viewHeight = originalImage.size.height
        
        //为了防止图片失真，绘制区域宽高和原始图片宽高一样
        UIGraphicsBeginImageContext(CGSize(width: viewWidth, height: viewHeight));
        
        let context = UIGraphicsGetCurrentContext()
        
        //将绘制原点（0，0）调整到源image的中心
        context?.concatenate(CGAffineTransform(translationX: viewWidth/2, y: viewHeight/2))
        //以绘制原点为中心旋转
        context?.concatenate(CGAffineTransform(rotationAngle:  CGFloat.pi * angle / 180))
        //将绘制原点恢复初始值，保证当前context中心和源image的中心处在一个点(当前context已经旋转，所以绘制出的任何layer都是倾斜的)
        context?.concatenate(CGAffineTransform(translationX: -viewWidth/2, y: -viewHeight/2))
        //先将原始image绘制上
        originalImage.draw(in: CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight))
        
        //根据上下文制作成图片
        let finalImg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        context?.saveGState()
        context?.restoreGState()
        
        return finalImg ?? originalImage
    }
}
