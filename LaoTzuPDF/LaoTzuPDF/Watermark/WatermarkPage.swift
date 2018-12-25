//
//  WatermarkPage.swift
//  LaoTzuPDF
//
//  Created by mozhe on 2018/12/6.
//  Copyright © 2018 mozhe. All rights reserved.
//

import Foundation
import PDFKit

class WatermarkPage: PDFPage {
    
    // 3. Override PDFPage custom draw
    /// - Tag: OverrideDraw
    override func draw(with box: PDFDisplayBox, to context: CGContext) {
        
        // Draw original content
        super.draw(with: box, to: context)
        
        // Draw rotated overlay string
        UIGraphicsPushContext(context)
        context.saveGState()
        
        /*
         let pageBounds = self.bounds(for: box)
         context.translateBy(x: 0.0, y: pageBounds.size.height)
         context.scaleBy(x: 1.0, y: -1.0)
         context.rotate(by: CGFloat.pi / 4.0)
         
         let string: NSString = "U s e r   3 1 4 1 5 9"
         
         let attributes = [
         NSAttributedString.Key.foregroundColor: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5),
         NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 40)
         ]
         
         string.draw(at: CGPoint(x:250, y:40), withAttributes: attributes)
         */
        
                textWatermark(context: context, box: box)
//        imageWatermark(context: context, box: box)
        
        context.restoreGState()
        UIGraphicsPopContext()
        
    }
    
    private func textWatermark(context: CGContext, box: PDFDisplayBox){
        
        let configuration = TextWatermarkConfiguration.init(
            style: .tile,
            contents: "mozheanquan",
            textColor: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5),
            font: UIFont.boldSystemFont(ofSize: 40),
            angle: 0,
            lineSpace: 20)
        
        
        configuration.configurationProperties(in: self, context: context, box: box)
        
    }
    
    private func imageWatermark(context: CGContext, box: PDFDisplayBox){
        
        let configuration = ImageWatermarkConfiguration.init(
            lineSpace: 10,
            style: .center,
            contents: R.image.foxIcon()!,
            alpha: 0.5,
            angle: -70)
        
        configuration.configurationProperties(in: self, context: context, box: box)
    }
    
    
}
