//
//  WatermarkPage.swift
//  LaoTzuPDF
//
//  Created by mozhe on 2018/12/6.
//  Copyright © 2018 mozhe. All rights reserved.
//

import Foundation
import PDFKit
import Mummy

class WatermarkPage: PDFPage {
    
    override init() {
        super.init()
        
        
    }
    
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
        
        //                textWatermark(context: context, box: box)
        //        imageWatermark(context: context, box: box)
        
        // load data from memery
//        do {
//            let data = try Data(contentsOf: URL(fileURLWithPath: WatermarkTransferModel.savedPath))
//
//            let decoder = JSONDecoder()
//            let watermarkTransferModel = try decoder.decode(WatermarkTransferModel.self, from: data)
            let watermarkTransferModel = MummyCaches.shared.retrieve(WatermarkTransferModel.defaultFilename, from: Directory.documents, as: WatermarkTransferModel.self)
            
            // 根据类型展示不同样式
            switch watermarkTransferModel.type {
                //TODO: - paraser type detail
            case .text:
//                textWatermark(context: context, box: box)
                let configuration = TextWatermarkConfiguration.init(
                    style: watermarkTransferModel.style,
                    contents: watermarkTransferModel.text!,
                    textColor: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: watermarkTransferModel.alpha),
                    font: UIFont.boldSystemFont(ofSize: watermarkTransferModel.fontScale!),
                    angle: watermarkTransferModel.angle,
                    lineSpace: watermarkTransferModel.lineSpace)
                 configuration.configurationProperties(in: self, context: context, box: box)
                
            case .image:
                imageWatermark(context: context, box: box)
            }
            
//        } catch  {
//            fatalError("load  WatermarkTransferModel failed1!!")
//        }
        
        
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
            style: .tile,
            contents: R.image.foxIcon()!,
            alpha: 0.5,
            angle: -45)
        
        configuration.configurationProperties(in: self, context: context, box: box)
    }
    
    
}
