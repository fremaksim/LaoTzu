//
//  WatermarkConfigurationViewController.swift
//  LaoTzuPDF
//
//  Created by mozhe on 2019/1/7.
//  Copyright © 2019 mozhe. All rights reserved.
//

import UIKit
import Mummy

class WatermarkConfigurationViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target: self, action: #selector(WatermarkConfigurationViewController.cancelAll))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(WatermarkConfigurationViewController.saveAll))
    }
    
    @objc func cancelAll(){
        
        dismissSelf()
    }
    
    @objc func saveAll() {
        
        if let configurationView =  self.view as? WaterConfigurationView {
            configurationView.save()
//            let encoder = JSONEncoder()
        
//            do{
//                let data = try encoder.encode(configurationView.originModel)
//                try data.write(to: URL(fileURLWithPath: WatermarkTransferModel.savedPath))
//            }catch {
//                fatalError("WaterConfigurationView save failed!")
//            }
            
            MummyCaches.shared.store(configurationView.originModel, to: .documents, as: WatermarkTransferModel.defaultFilename)
            
            
            NotificationCenter.default.post(name: NSNotification.Name.WaterConfigurationSaved, object: nil, userInfo: ["model": configurationView.originModel])
        }
        
        
        dismissSelf()
    }
    
    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    
    
}
