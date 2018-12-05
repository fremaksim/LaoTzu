//
//  UIViewControllerExtension.swift
//  LaoTzuPDF
//
//  Created by mozhe on 2018/12/5.
//  Copyright © 2018 mozhe. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    // Enable detection of shake motion
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
//            print("Why are you shaking me?")
            PAirSandbox.sharedInstance()?.showBrowser()
        }
    }
}
