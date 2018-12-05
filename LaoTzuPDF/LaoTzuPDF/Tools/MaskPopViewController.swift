//
//  MaskPopViewController.swift
//  LaoTzuPDF
//
//  Created by mozhe on 2018/12/5.
//  Copyright © 2018 mozhe. All rights reserved.
//

import UIKit

private enum MaskCustomViewAction {
    case show,hide
}

class MaskPopViewController: UIViewController {
    private let backgroundAlpha: CGFloat = 0.4
    static let screenHeight: CGFloat = UIScreen.main.bounds.height
    
    //MARK: - Properties
    weak var customView: UIView? = nil
    
    //MARK: - Life Cycle
    init(customView: UIView? = nil) {
        if let customView = customView {
            self.customView = customView
        }
        super.init(nibName: nil, bundle: nil)
        if let customView = customView {
            self.view.addSubview(customView)
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    //MARK: - Instance Methods
    private func setupUI(){
        view.backgroundColor = UIColor.black.withAlphaComponent(backgroundAlpha)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        animateCustomView(action: .hide)
    }
    
    //MARK: - Class Methods
    @discardableResult
    static func show(on controller: UIViewController, with customView: UIView? = nil) -> MaskPopViewController {
        customView?.frame.origin.y = MaskPopViewController.screenHeight
        let vc = MaskPopViewController(customView: customView)
        
        controller.addChild(vc)
        controller.view.addSubview(vc.view)
        vc.view.frame = controller.view.bounds
        
        vc.animateCustomView(action: .show)
        
        return vc
    }
    
    //MARK: --- Help Methods
    private func animateCustomView(action: MaskCustomViewAction){
        let height: CGFloat = customView?.frame.height ?? 0
        
        switch action {
        case .show:
            UIView.animate(withDuration: 0.25, animations: {
                
                self.view.alpha = self.backgroundAlpha
                self.customView?.frame.origin.y = MaskPopViewController.screenHeight - height
                
            }) { (_) in
                
            }
        case .hide:
            UIView.animate(withDuration: 0.25, animations: {
                self.view.alpha = 0.0
                self.customView?.frame.origin.y = MaskPopViewController.screenHeight
                
            }) { (_) in
                self.dismissIt()
            }
        }
    }
    
    private func dismissIt(){
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
    
    
}
