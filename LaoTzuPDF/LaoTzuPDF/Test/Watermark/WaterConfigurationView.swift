//
//  WaterConfigurationView.swift
//  LaoTzuPDF
//
//  Created by mozhe on 2019/1/7.
//  Copyright © 2019 mozhe. All rights reserved.
//

import UIKit

private enum ContentType: Int {
    case text  = 0
    case image = 1
}

private enum Style: Int {
    case tile   = 0
    case center = 1
}


class WaterConfigurationView: UIView {
    
    var originModel: WatermarkTransferModel = WatermarkTransferModel() {
        didSet {
            model = originModel
            //            updateUI()
        }
    }
    
    private var model: WatermarkTransferModel = WatermarkTransferModel() {
        didSet {
            updateUI()
        }
    }
    
    @IBOutlet weak var typeSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var styleSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var alphaLabel: UILabel!
    @IBOutlet weak var alphaSlider: UISlider!
    
    
    @IBOutlet weak var angleTextfiels: UITextField!
    
    
    @IBOutlet weak var interSpaceTextField: UITextField!
    
    
    @IBOutlet weak var contentLabel: UILabel!
    
    @IBOutlet weak var fontScaleLabel: UILabel!
    @IBOutlet weak var inputWatermarkTextField: UITextField!
    
    
    @IBOutlet weak var selectOrTakePhotoButton: UIButton!
    
    @IBOutlet weak var fontScaleTextfield: UITextField!
    @IBOutlet weak var selectedImageView: UIImageView!
    
    // MARK: - Events
    @IBAction func typeSegmentedControlAction(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case ContentType.text.rawValue:
            model.type = .text
            //隐藏图片信息
            showUI(type: .text)
        case ContentType.image.rawValue:
            model.type = .image
            // 隐藏文字信息
            showUI(type: .image)
        default:
            print("Not support")
        }
    }
    
    @IBAction func styleSegmentedControlAction(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            model.style = .tile
        case 1:
            model.style = .center
        default:
            print("Not support")
        }
    }
    
    @IBAction func alphaSliderAction(_ sender: UISlider) {
        model.alpha = CGFloat(sender.value)
        alphaLabel.text = "透明度  \(model.alpha.roundTo(places: 2)) ："
    }
    
    @IBAction func slectedOrCameraPhotoAction(_ sender: UIButton) {
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        angleTextfiels.delegate          = self
        inputWatermarkTextField.delegate = self
        interSpaceTextField.delegate     = self
        fontScaleTextfield.delegate      = self
    }
    
    func save() {
        
        model.alpha = CGFloat(alphaSlider.value)
        if let angleText = angleTextfiels.text,
            let n = NumberFormatter().number(from: angleText) {
            model.angle = CGFloat.init(exactly: n) ?? 0
        }
        if let fontScaleText = fontScaleTextfield.text,
            let n = NumberFormatter().number(from: fontScaleText) {
            model.fontScale = CGFloat.init(exactly: n) ?? 20
        }
        if let lineSpace = interSpaceTextField.text,
            let n = NumberFormatter().number(from: lineSpace) {
           model.lineSpace = CGFloat.init(exactly: n) ?? 20
        }
        model.text = inputWatermarkTextField.text
        
        
        originModel.alpha     = model.alpha
        originModel.angle     = model.angle
        originModel.fontScale = model.fontScale
        originModel.lineSpace = model.lineSpace
        originModel.style     = model.style
        originModel.image     = model.image
        originModel.text      = model.text
        originModel.type      = model.type
        
        updateUI()
    }
    
    private func updateUI() {
        typeSegmentedControl.selectedSegmentIndex  = model.type.rawValue
        styleSegmentedControl.selectedSegmentIndex = model.style.rawValue
        alphaSlider.value = Float(model.alpha)
        alphaLabel.text = "透明度  \(model.alpha.roundTo(places: 2)) ："
        angleTextfiels.text = "\(model.angle)"
        fontScaleLabel.text = "\(model.fontScale ?? 0)"
        inputWatermarkTextField.text = model.text
        if let data = model.image {
            selectedImageView.image = UIImage(data: data)
        }
    }
    
    private  func showUI(type: ContentType) {
        switch type {
        case .text:
            selectOrTakePhotoButton.isHidden = true
            selectedImageView.isHidden = true
            
            fontScaleLabel.isHidden = false
            fontScaleTextfield.isHidden = false
            inputWatermarkTextField.isHidden = false
            
            contentLabel.text = "水印文字"
            
        case .image:
            selectOrTakePhotoButton.isHidden = false
            selectedImageView.isHidden = false
            
            fontScaleLabel.isHidden = true
            fontScaleTextfield.isHidden = true
            inputWatermarkTextField.isHidden = true
            
            contentLabel.text = "水印图片"
        }
    }
    
}

extension WaterConfigurationView: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == angleTextfiels {
            return  textField.decimalPlaces(beforeDot: 3, afterDot: 2, in: textField, shouldChangeCharactersIn: range, replacementString: string)
        }else if textField == interSpaceTextField {
            return  textField.decimalPlaces(beforeDot: 2, afterDot: 2, in: textField, shouldChangeCharactersIn: range, replacementString: string)
        }else if textField == inputWatermarkTextField {
            
        }else if textField == fontScaleTextfield {
            return  textField.decimalPlaces(beforeDot: 2, afterDot: 2, in: textField, shouldChangeCharactersIn: range, replacementString: string)
        }
        return true
    }
}

extension UITextField {
    // leadingCount >=  1
    func decimalPlaces(beforeDot leadingCount: Int,
                       afterDot trailingCount: Int,
                       in textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
        
        if let oldString = textField.text {
            let toString = oldString.replacingCharacters(in: Range(range, in: oldString)!, with: string)
            if toString.count > 0 {
                //保留规则：小数点前 leadingCount 位，小数点后trailingCount位
                let regex = "(\\+)?(([0]|(0[.]\\d{0,\(trailingCount)}))|([1-9]\\d{0,\(leadingCount - 1)}(([.]\\d{0,\(trailingCount)})?)))?"
                // 保留规则: 小数点前9位，小数点后4位
                // let regex = "(\\+)?(([0]|(0[.]\\d{0,4}))|([1-9]\\d{0,8}(([.]\\d{0,4})?)))?"
                let predicate = NSPredicate(format: "SELF MATCHES %@ ", regex)
                if !predicate.evaluate(with: toString) {
                    return false
                }
            }
        }
        return true
    }
}



protocol DecimalPlaceProtocol {
    associatedtype T
    
    func roundTo(places:  Int) -> T
    
}

//extension Double {
//
//    /// Rounds the double to decimal places value
//
//    func roundTo(places:Int) -> Double {
//
//        let divisor = pow(10.0, Double(places))
//
//        return (self * divisor).rounded() / divisor
//
//    }
//
//}

extension Double: DecimalPlaceProtocol{
    
    /// Rounds the double to decimal places value
    
    func roundTo(places: Int) -> Double {
        
        let divisor = pow(10.0, Double(places))
        
        return (self * divisor).rounded() / divisor
        
    }
    
}

extension CGFloat: DecimalPlaceProtocol {
    
    func roundTo(places: Int) -> CGFloat {
        let divisor = pow(10.0, CGFloat(places))
        
        return (self * divisor).rounded() / divisor
    }
}
