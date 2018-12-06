//
//  AnnotationPopView.swift
//  LaoTzuPDF
//
//  Created by mozhe on 2018/12/6.
//  Copyright © 2018 mozhe. All rights reserved.
//

import UIKit

class AnnotationPopView: UIView {
    
    var contents: String? {
        didSet {
            textView.text = contents
        }
    }
    
    override var backgroundColor: UIColor? {
        didSet{
            textView.backgroundColor = backgroundColor
        }
    }
    private lazy var textView: UITextView = {
        let textView = UITextView(frame: .zero)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 9)
        return textView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 0.5
        
        addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leftAnchor.constraint(equalTo: self.leftAnchor),
            textView.rightAnchor.constraint(equalTo: self.rightAnchor),
            textView.widthAnchor.constraint(equalTo: self.widthAnchor),
            textView.heightAnchor.constraint(equalTo: self.heightAnchor),
            ])
        
        backgroundColor = UIColor.yellow.withAlphaComponent(0.8)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
}
