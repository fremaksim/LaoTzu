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
        
        let pageBounds = self.bounds(for: box)
        context.translateBy(x: 0.0, y: pageBounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.rotate(by: CGFloat.pi / 4.0)
        
        let string: NSString = "U s e r   3 1 4 1 5 9"
        let attributes = [
            NSAttributedString.Key.foregroundColor: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5),
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 64)
        ]
        
        string.draw(at: CGPoint(x:250, y:40), withAttributes: attributes)
        
        context.restoreGState()
        UIGraphicsPopContext()
        
    }
    
}
