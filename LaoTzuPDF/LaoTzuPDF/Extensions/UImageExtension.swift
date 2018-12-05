//
//  UImageExtension.swift
//  LaoTzuPDF
//
//  Created by mozhe on 2018/12/5.
//  Copyright © 2018 mozhe. All rights reserved.
//

import UIKit


extension UIImage {
    
    // bounds.width = bounds.height
    func projectedSizeForImage(_ image: UIImage, bounds: CGSize) -> CGSize {
        
        let aspectRatio = image.size.width/image.size.height
        var projectedWidth = bounds.width
        var projectedHeight = projectedWidth/aspectRatio
        
        if projectedHeight > bounds.height {
            projectedHeight = bounds.height
            projectedWidth = projectedHeight * aspectRatio
        }
        
        return CGSize(width: projectedWidth, height: projectedHeight)
    }
    
    
    
}
