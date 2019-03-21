//
//  DocumentViewController.swift
//  LaoTzuPDF
//
//  Created by mozhe on 2018/12/5.
//  Copyright © 2018 mozhe. All rights reserved.
//

import UIKit
import PDFKit
import PDFKit.PDFSelection
import MoAESCryptor

extension DocumentViewController {
    func goToPage(page: PDFPage) {
        pdfView.go(to: page)
    }
    
    func selectOutline(outline: PDFOutline) {
        if let action = outline.action as? PDFActionGoTo {
            pdfView.go(to: action.destination)
        }
    }
}

class DocumentViewController: UIViewController {
    
    var pdfhandler: PDFHandler? = nil
    
    var watermarkLayer: AnyClass = PDFPage.self
    
    @IBOutlet weak var pdfView: PDFView!
    
    var document: Document?
    
    let userDeaults = UserDefaults.standard
    
    var portraitScaleFactorForSizeToFit: CGFloat = 0.0
    var landscapeScaleFactorForSizeToFit: CGFloat = 0.0
    
    var isEncrypted = false
    // var allowsDocumentAssembly = false
    
    // edit
    lazy var editButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = UIColor.blue
        btn.setTitle("Edit", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor.blue.withAlphaComponent(0.3)
        btn.addTarget(self, action: #selector(editButtonClick), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.layer.cornerRadius = 20
        btn.layer.masksToBounds = true
        btn.isExclusiveTouch = true
        return btn
    }()
    weak var popEditView: UIView?
    
    // annotation
//    var userAction: DocumentViewUserAction = .none
    
    override func viewDidLoad() {
        navigationController?.barHideOnTapGestureRecognizer.addTarget(self, action: #selector(barHideOnTapGestureRecognizerHandler(_:)))
        
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        
        
        pdfView.subviews.filter { (view) -> Bool in
            return view.isKind(of: UIScrollView.self)
            }.forEach { (view) in
                (view as? UIScrollView)?.scrollsToTop = false
                (view as? UIScrollView)?.contentInsetAdjustmentBehavior = .scrollableAxes
        }
        
        let center = NotificationCenter.default
        center.addObserver(self,
                           selector: #selector(updateInterface),
                           name: UIApplication.willEnterForegroundNotification,
                           object: nil)
        center.addObserver(self,
                           selector: #selector(saveAndClose),
                           name: UIApplication.didEnterBackgroundNotification,
                           object: nil)
        center.addObserver(self,
                           selector: #selector(didChangeOrientationHandler),
                           name: UIApplication.didChangeStatusBarOrientationNotification,
                           object: nil)
        // Annotations
        center.addObserver(self,
                           selector: #selector(didHitAnnotation), name: NSNotification.Name.PDFViewAnnotationHit, object: nil)
        
        // 测试 for watermark configuration
        center.addObserver(self, selector: #selector(waterConfigurationSaved(_:)), name: NSNotification.Name.WaterConfigurationSaved, object: nil)
        
        view.addSubview(editButton)
        NSLayoutConstraint.activate([
            editButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
            editButton.bottomAnchor.constraint(equalTo: view.readableContentGuide.bottomAnchor, constant: -60),
            editButton.widthAnchor.constraint(equalToConstant: 40),
            editButton.heightAnchor.constraint(equalToConstant: 40)
            ])
        view.bringSubviewToFront(editButton)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeLeft.direction = UISwipeGestureRecognizer.Direction.left
        
        view.addGestureRecognizer(swipeRight)
        view.addGestureRecognizer(swipeLeft)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateInterface()
        super.viewWillAppear(animated)
        
        // Key to Bars Hidden
        navigationController?.hidesBarsOnTap = true
        
        loadDocument()
        
    }
    
    deinit {
        LogManager.shared.log.debug("deinit")
    }
    
    private func loadDocument(){
        if (pdfView.document != nil) { return }
        // Access the document
        document?.open(completionHandler: { (success) in
            if success {
                // Display the content of the document, e.g.:
                self.navigationItem.title = self.document?.localizedName
                
                guard let pdfURL: URL = (self.document?.fileURL) else { return }
                guard let document = PDFDocument(url: pdfURL) else { return }
                
                // self.allowsDocumentAssembly = document.allowsDocumentAssembly
                self.isEncrypted = document.isEncrypted
                
                // watermark 1
                document.delegate = self
                self.pdfView.document = document
                
                self.moveToLastReadingProsess()
                if self.pdfView.displayDirection == .vertical {
                    self.getScaleFactorForSizeToFit()
                }
                
                self.setPDFThumbnailView()
            } else {
                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
            }
        })
    }
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        cleanAnnotationPopView()
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizer.Direction.right:
                if pdfView.canGoToPreviousPage() {
                    pdfView.goToPreviousPage(nil)
                }
            case UISwipeGestureRecognizer.Direction.left:
                if pdfView.canGoToNextPage() {
                    pdfView.goToNextPage(nil)
                }
            default:
                break
            }
        }
    }
    
    @objc func updateInterface() {
        if presentingViewController != nil {
            // use same UI style as DocumentBrowserViewController
            if UserDefaults.standard.integer(forKey: (presentingViewController as! DocumentBrowserViewController).browserUserInterfaceStyleKey) == UIDocumentBrowserViewController.BrowserUserInterfaceStyle.dark.rawValue {
                navigationController?.navigationBar.barStyle = .black
                navigationController?.toolbar.barStyle = .black
            } else {
                navigationController?.navigationBar.barStyle = .default
                navigationController?.toolbar.barStyle = .default
            }
            view.backgroundColor = presentingViewController?.view.backgroundColor
            navigationController?.navigationBar.tintColor = presentingViewController?.view.tintColor
        }
    }
    
    func setPDFThumbnailView() {
        if let margins = navigationController?.toolbar.safeAreaLayoutGuide {
            let pdfThumbnailView = PDFThumbnailView.init()
            pdfThumbnailView.pdfView = pdfView
            pdfThumbnailView.layoutMode = .horizontal
            pdfThumbnailView.translatesAutoresizingMaskIntoConstraints = false
            navigationController?.toolbar.addSubview(pdfThumbnailView)
            pdfThumbnailView.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
            pdfThumbnailView.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
            pdfThumbnailView.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
            pdfThumbnailView.bottomAnchor.constraint(equalTo: margins.bottomAnchor).isActive = true
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return navigationController?.isNavigationBarHidden == true || super.prefersStatusBarHidden
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    /* override func prefersHomeIndicatorAutoHidden() -> Bool {
     return navigationController?.isToolbarHidden == true
     }
     */
    
    @objc func barHideOnTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: pdfView)
        if editButton.frame.contains(point) || popEditView?.frame.contains(point) ?? false {
            hideBars()
            return
        }
   
        navigationController?.setToolbarHidden(navigationController?.isNavigationBarHidden == true, animated: true)
        setNeedsUpdateOfHomeIndicatorAutoHidden()
        
        cleanAnnotationPopView()
    }
    
    private func hideBars() {
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.setToolbarHidden(true, animated: true)
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
    private func showBars() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.setToolbarHidden(false, animated: false)
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
    
    func getScaleFactorForSizeToFit() {
        let frame = pdfView.frame
        let aspectRatio = frame.size.width / frame.size.height
        if UIApplication.shared.statusBarOrientation.isPortrait {
            portraitScaleFactorForSizeToFit = pdfView.scaleFactorForSizeToFit
            landscapeScaleFactorForSizeToFit = portraitScaleFactorForSizeToFit / aspectRatio
        } else if UIApplication.shared.statusBarOrientation.isLandscape {
            landscapeScaleFactorForSizeToFit = pdfView.scaleFactorForSizeToFit
            portraitScaleFactorForSizeToFit = landscapeScaleFactorForSizeToFit / aspectRatio
        }
    }
    
    func setScaleFactorForSizeToFit() {
        if pdfView.displayDirection == .vertical {
            // currentlly only works for vertical display direction
            if portraitScaleFactorForSizeToFit != 0.0 && UIApplication.shared.statusBarOrientation.isPortrait {
                pdfView.minScaleFactor = portraitScaleFactorForSizeToFit
                pdfView.scaleFactor = portraitScaleFactorForSizeToFit
            } else if landscapeScaleFactorForSizeToFit != 0.0 && UIApplication.shared.statusBarOrientation.isLandscape {
                let multiplier = (pdfView.frame.width - pdfView.safeAreaInsets.left - pdfView.safeAreaInsets.right) / pdfView.frame.width
                // set minScaleFactor to safe area for iPhone X and later
                pdfView.minScaleFactor = landscapeScaleFactorForSizeToFit * multiplier
                pdfView.scaleFactor = landscapeScaleFactorForSizeToFit
            }
        }
    }
    
    func moveToLastReadingProsess() {
        var pageIndex = 0
        if let documentURL = pdfView.document?.documentURL {
            if userDeaults.object(forKey: documentURL.path) != nil {
                // key exists
                pageIndex = userDeaults.integer(forKey: documentURL.path)
            }
            // TODO: if pageIndex == pageCount - 1, then go to last CGRect
            if let pdfPage = pdfView.document?.page(at: pageIndex) {
                pdfView.go(to: pdfPage)
            }
        }
    }
    
    @objc func saveAndClose() {
        guard let pdfDocument = pdfView.document else { return }
        if let currentPage = pdfView.currentPage,
            let documentURL = pdfView.document?.documentURL {
            let currentIndex = pdfDocument.index(for: currentPage)
            userDeaults.set(currentIndex, forKey: documentURL.path)
            print("saved page index: \(String(describing: currentIndex))")
        }
        
        self.document?.close(completionHandler: nil)
    }
    
    @objc func didChangeOrientationHandler() {
        setScaleFactorForSizeToFit()
    }
    
    @objc func didHitAnnotation(_ noti: NSNotification) {
        // clean
        DispatchQueue.main.async {
            self.cleanAnnotationPopView()
            DispatchQueue.main.async {
                guard let userInfo = noti.userInfo else { return }
                
                //        LogManager.shared.log.info(userInfo)
                if let annotation = userInfo["PDFAnnotationHit"] as? PDFAnnotation {
                    LogManager.shared.log.info(annotation.annotationKeyValues)
                    let convertRect = self.pdfView.convert(annotation.bounds, from: annotation.page!)
                    
                    let scale: CGFloat = 4.0
                    var targetRect = convertRect
                    targetRect.size.width  *= scale
                    targetRect.size.height *= scale
                    
                    let scaleView: AnnotationPopView = AnnotationPopView(frame: targetRect)
                    scaleView.contents = annotation.contents
                    self.view.addSubview(scaleView)
                    
                    func addKeyFrame(scaleView: UIView, convertRect: CGRect, scale: CGFloat) {
                        let startTime: Double
                        if scale == 1.0 {
                            startTime = 0.25
                        }else {
                            startTime  = 0.25 * Double(scale - 1)
                        }
                        UIView.addKeyframe(withRelativeStartTime: startTime ,
                                           relativeDuration: 0.25,
                                           animations: {
                                            var newFrame = scaleView.frame
                                            newFrame.size.width  = convertRect.width * scale
                                            newFrame.size.height = convertRect.height * scale
                                            scaleView.frame = newFrame
                        })
                    }
                    
                    UIView.animateKeyframes(withDuration: 1,
                                            delay: 0,
                                            options:.calculationModeCubic,
                                            animations: {
                                                for i in 1...4 {
                                                    addKeyFrame(scaleView: scaleView,
                                                                convertRect: convertRect,
                                                                scale: CGFloat(i))
                                                }
                    })
                    // pop menu
                    //            let popMenu = MKDropdownMenu(frame: targetRect)
                    //            popMenu.presentingView = pdfView
                    //            popMenu.delegate  = self
                    //            popMenu.dataSource = self
                    //            self.view.addSubview(popMenu)
                }
            }
        }
        

        
//        navigationController?.barHideOnTapGestureRecognizer.isEnabled = true
    }
    
    @objc func waterConfigurationSaved(_ noti: Notification) {
        watermarkLayer = WatermarkPage.self
        
        //        loadDocument()
        //        pdfView.setNeedsDisplay()
        
        // Access the document
        document?.open(completionHandler: { (success) in
            if success {
                // Display the content of the document, e.g.:
                self.navigationItem.title = self.document?.localizedName
                
                guard let pdfURL: URL = (self.document?.fileURL) else { return }
                guard let document = PDFDocument(url: pdfURL) else { return }
                
                // self.allowsDocumentAssembly = document.allowsDocumentAssembly
                self.isEncrypted = document.isEncrypted
                
                // watermark 1
                document.delegate = self
                self.pdfView.document = document
                
                self.moveToLastReadingProsess()
                if self.pdfView.displayDirection == .vertical {
                    self.getScaleFactorForSizeToFit()
                }
                
                self.setPDFThumbnailView()
            } else {
                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
            }
        })
    }
    
    private func cleanAnnotationPopView() {
        view.subviews.filter { (view) -> Bool in
            view is AnnotationPopView
            }.forEach { (view) in
                view.removeFromSuperview()
        }
    }
    
    //MARK: - UI Event
    @IBAction func dismissDocumentViewController() {
        dismiss(animated: true) {
            self.saveAndClose()
        }
    }
    
    @IBAction func watermarkTest(_ sender: Any) {
        
        let waterConfigurationVC = WatermarkConfigurationViewController()
        //        navigationController?.pushViewController(waterConfigurationVC, animated: true)
        let navi = UINavigationController(rootViewController: waterConfigurationVC)
        present(navi, animated: true, completion: nil)
        
        
    }
    
    
    @IBAction func shareAction() {
        let activityVC = UIActivityViewController(activityItems: [document?.fileURL as Any], applicationActivities: nil)
        self.present(activityVC, animated: true, completion: nil)
    }
    
    @IBAction func SaveAction(_ sender: UIBarButtonItem) {
        
        guard let document = pdfView.document else {
            return
        }
        
        let copyURL = URL(fileURLWithPath: DocumentFileFolder.LaoTzuDocumentFileCopyPath, isDirectory: false)
        if !FileManager.default.fileExists(atPath: copyURL.path) {
            do {
                try FileManager.default.createDirectory(at: copyURL, withIntermediateDirectories: true, attributes: nil)
            }catch {
                LogManager.shared.log.error(error)
            }
        }
        
        let fileName: String = "Se7enCopy"
        let url: URL = copyURL.appendingPathComponent(fileName)
        let dataFileName: String = "Se7enData.pdf"
        let _: URL = copyURL.appendingPathComponent(dataFileName)
        LogManager.shared.log.info(url)
        if  document.write(to: url, withOptions: nil) {
            LogManager.shared.log.debug("write to path \(url.path) success!")
        }
        
        // 字节操作
        let newDocument = PDFDocument(url: url)
        if var newData = newDocument?.dataRepresentation() {
            LogManager.shared.log.info("*before*: data bytes: \(newData.count)")
            encryptorInObjc(at: url, fileData: newData)
//            handlerDoing(at: url, fileData: newData)
            
            return
            let cafe: Data = "Orange".data(using: .utf8)!// non-nil
            
            
            //  *before*: data bytes: 23131808
            /*
             let before = newData.count
             newData.append(cafe)
             //  *after*: appended data bytes: 23131814
             LogManager.shared.log.info("*after*: appended data bytes: \(newData.count)")
             let length = newData.count - before
             
             let t: Int32 =  newData.scanValue(start: before, length: length)
             LogManager.shared.log.debug(t)
             let cafeData = newData.subdata(in: before..<(before+length))
             if let cafeString = String(bytes: cafeData, encoding: .utf8) {
             LogManager.shared.log.info(cafeString)
             }
             if let documentNew = PDFDocument(data: newData) {
             LogManager.shared.log.info(" done !!!!!")
             // 这方法不带 append data
             if  documentNew.write(to: url, withOptions: [PDFDocumentWriteOption.userPasswordOption : "123",PDFDocumentWriteOption.mozheOption : "ppx"]) {
             LogManager.shared.log.debug("write to path \(url.path) success! again!!")
             }
             do {
             // 带 append data， 也能解析PDF信息
             try newData.write(to: dataURL)
             LogManager.shared.log.debug("write newData to path \(dataURL.path) success!")
             }catch {
             LogManager.shared.log.debug(error.localizedDescription)
             }
             }
             */
            
          
                // 加解密
                DispatchQueue.global().async {
                    do {
                        let password = "123456"
                        let salt = AES256Crypter.randomSalt()
                        let iv   = AES256Crypter.randomIv()
                        let key  = try AES256Crypter.createKey(password: password.data(using: .utf8)!, salt: salt)
                        let aes  = try AES256Crypter(key: key, iv: iv)
                        
                        let encryptedData = try aes.encrypt(newData) // pdf file
                        
                        DispatchQueue.main.async {
                            print("encrypted success!",Date())
                        }
                        //            let decryptedData = try aes.decrypt(encryptedData)
                        DispatchQueue.main.async {
                            print("deencrypted success!",Date())
                        }
                        // 22.06Mb Encrypto needed 9s, all so need for with dencrypto, total 18s
                        
                        let fileType = "%PDF-"
                        let endOfFile = "%%EOF"
                        let headerData = fileType.data(using: .utf8)!
                        var fileTypeData = headerData
                        let endOfFileData = endOfFile.data(using: .utf8)!
                        
                        fileTypeData.append(encryptedData)
                        fileTypeData.append(endOfFileData)
                        fileTypeData.append(cafe)
                        
                        let targetPath = url.path.replacingOccurrences(of: "Se7enCopy.pdf", with: "Se7enDataEncrypted.file")
                        
                        print(targetPath)
                        let targetURL = URL(fileURLWithPath: targetPath)
                        print(targetURL)
                        try fileTypeData.write(to: targetURL)
                        LogManager.shared.log.info("write newData success")
                        
                        //去掉头
                        let notHeadFileData = fileTypeData.subdata(in: headerData.count..<fileTypeData.count)
                        
                        FindEOF.findEncrypted(data: notHeadFileData, completion: { (index, isSuccess) in
                            if isSuccess {
                                if let start = index?.0,
                                    let end   = index?.1 {
                                    do{
                                        let encryptPdfData = fileTypeData.subdata(in: headerData.count..<start)
                                        let decryptPdfData = try aes.decrypt(encryptPdfData)
                                        let newtargetPath = url.path.replacingOccurrences(of: "Se7enCopy.pdf", with: "Se7enDataDencrypted.pdf")
                                        let newtargetURL = URL(fileURLWithPath: newtargetPath)
                                        try  decryptPdfData.write(to: newtargetURL)
                                        LogManager.shared.log.info("find pdf success!")
                                        let privateData = fileTypeData.subdata(in: end..<fileTypeData.count)
                                        if let privateString = String(data: privateData, encoding: .utf8){
                                            LogManager.shared.log.debug(privateString)
                                        }
                                    }catch{
                                        LogManager.shared.log.error(error)
                                    }
                                }
                            }
                        })
                        
                    } catch  {
                        LogManager.shared.log.error("encrypto failer")
                        LogManager.shared.log.error(error)
                    }
            }
        }
    }
    
    private func handlerDoing(at url: URL, fileData: Data){
  
        let length = "0016"
        let lengthData = length.data(using: .utf8)!
      
        let version = "0001"
        let versionData = version.data(using: .utf8)!
        
        var id = 2501
        let idData = Data(bytes: &id, count: MemoryLayout.size(ofValue: id))

        let pdfTailer = PDFTailer(length: lengthData,
                                  version: versionData,
                                  id: idData)
//        var mutableData = fileData
        
        self.pdfhandler = PDFHandler(inputData: fileData)
        let appendedData = pdfhandler?.appending(tailer: pdfTailer)
        
        let targetPath = url.path.replacingOccurrences(of: "Se7enCopy",
                                                       with: "Se7enDataAppend.pdf")
        let targetURL = URL(fileURLWithPath: targetPath)
        try? appendedData?.write(to: targetURL)
        
//        pdfhandler?.pop(completion: { (data) in
//            LogManager.shared.log.info([UInt8](data))
//        })
        pdfhandler?.retrieve(completion: { (tailer) in
            print(tailer.getLength() ?? 0)
            print(tailer.getVersion() ?? 0)
            print(tailer.getId())
        })
        
        pdfhandler?.removedAppended(completion: { (origin) in
            let targetPath = url.path.replacingOccurrences(of: "Se7enCopy",
                                                           with: "Se7enCopyReback.pdf")
            let targetURL = URL(fileURLWithPath: targetPath)
            try? origin.write(to: targetURL)
        })
    }
    
    
    
    private func encryptorInObjc(at url: URL, fileData: Data) {
        let hammer = "Hammer".data(using: .utf8)!
//        let password = "passwordpasswordpasswordpassword".data(using: .utf8)! //32byte
        let password = MoAESKeyGenerater.key(byHashingPassword: "password",
                                             keySize: MoAESCryptorType256)
        
        let settings = MoAESCryptorSetting(type: MoAESCryptorType256,
                                           padding: MoAESCryptorPaddingZero,
                                           keyPadding: MoAESCryptorKeyPaddingZero,
                                           operation: MoAESCryptorOperationEncrypt)
        
        func encryptOrDecryptInBackground(fileData: Data,
                                          key: Data,
                                          settings: MoAESCryptorSetting,
                                          completion: @escaping (Data?, MoAESCryptorError) -> () )  {
            
            DispatchQueue.global().async {
                MoAESCryptor.ecbCipher(fileData,
                                       key: key,
                                       settings: settings) {  (encryptedData, error) in
                                        DispatchQueue.main.async {
                                            completion(encryptedData, error)
                                        }
                }
            }
        }
        
        encryptOrDecryptInBackground(fileData:fileData,
                                     key: password,
                                     settings: settings) { (data, error)  in
                                        if let encryptedData = data {
                                            LogManager.shared.log.info("encrypt success: \(encryptedData)")
                                            let fileType  = "%PDF-"
                                            let endOfFile = "%%EOF"
                                            let headerData = fileType.data(using: .utf8)!
                                            var fileTypeData = headerData
                                            let endOfFileData = endOfFile.data(using: .utf8)!
                                            
                                            fileTypeData.append(encryptedData)
                                            fileTypeData.append(endOfFileData)
                                            fileTypeData.append(hammer)
                                            
                                            let targetPath = url.path.replacingOccurrences(of: "Se7enCopy",
                                                                                           with: "Se7enDataEncrypted.file")
                                            let targetURL = URL(fileURLWithPath: targetPath)
                                            do {
                                                try fileTypeData.write(to: targetURL)
                                                LogManager.shared.log.info("write newData to path: \(targetPath) success")
                                                
                                                //去掉头
                                                let notHeadFileData = fileTypeData.subdata(in: headerData.count..<fileTypeData.count)
                                                FindEOF.findEncrypted(data: notHeadFileData, completion: { (index, isSuccess) in
                                                    if isSuccess,
                                                        let start = index?.0,
                                                        let end   = index?.1 {
                                                        let encryptPdfData = fileTypeData.subdata(in: headerData.count..<start)
                                                        settings.operation = MoAESCryptorOperationDecrypt
                                                        encryptOrDecryptInBackground(fileData: encryptPdfData,
                                                                                     key: password,
                                                                                     settings: settings,
                                                                                     completion: { (data, error) in
                                                                                        if let decryptPdfData = data {
                                                                                            let newtargetPath = url.path.replacingOccurrences(of: "Se7enCopy.pdf", with: "Se7enDataDencrypted.pdf")
                                                                                            let newtargetURL = URL(fileURLWithPath: newtargetPath)
                                                                                            try? decryptPdfData.write(to: newtargetURL)
                                                                                            LogManager.shared.log.info("find pdf success!")
                                                                                            let privateData = fileTypeData.subdata(in: end..<fileTypeData.count)
                                                                                            if let privateString = String(data: privateData, encoding: .utf8){
                                                                                                LogManager.shared.log.debug(privateString)
                                                                                            }
                                                                                        }
                                                        })
                                                    }else {
                                                        LogManager.shared.log.error("Encrypted Data Failure!!!")
                                                    }
                                                })
                                                
                                            }catch {
                                                LogManager.shared.log.error(error)
                                            }
                                        }
        }
        
        
        
    }
    
    @IBAction func findAction(_ sender: UIBarButtonItem) {
        if let selections =  pdfView.document?.findString("mozheanquan", withOptions: NSString.CompareOptions.literal) {
            for sel in selections {
                LogManager.shared.log.debug(sel.string ?? "")
                if sel.string == "mozheanquan" {
                    LogManager.shared.log.debug(selections.count)
                    break
                }
            }
            
        }
    }
    
    
    @objc func editButtonClick() {

        let annotationButton = UIButton(type: .custom)
        annotationButton.isExclusiveTouch = true
        annotationButton.setImage(R.image.editAnnotations(), for: .normal)
        annotationButton.addTarget(self, action: #selector(annotationButtonClick), for: .touchUpInside)
        let customView = UIView(frame: CGRect(x: 0,
                                              y: 100,
                                              width: UIScreen.main.bounds.width,
                                              height: 50))
        customView.backgroundColor = UIColor.yellow.withAlphaComponent(0.5)
        customView.addSubview(annotationButton)
        annotationButton.frame = CGRect(x: (UIScreen.main.bounds.width - 50 - 20),
                                        y: 0,
                                        width: 50,
                                        height: 50)
        self.popEditView = customView
        MaskPopViewController.show(on: self, with: customView)
    }
    
    @objc func annotationButtonClick() {
        
        // detect this file is in Document/Inbox
        if document?.isInDocumentInbox() == true { // Copy to folder
            
        }else {
            
        }
        
        guard let currentPage = pdfView.currentPage else { return }
        
        let textRect: CGRect = CGRect(x: 20, y: 100, width: 100, height: 40)
        let textAnnotation = PDFAnnotation(bounds: textRect, forType: .text, withProperties: nil)
        textAnnotation.contents = "Se7en"
        textAnnotation.iconType = .note
        textAnnotation.fontColor = UIColor.purple
        currentPage.addAnnotation(textAnnotation)
        
        //        documentPickerAction()
    }
}

extension DocumentViewController: PDFDocumentDelegate {
    // Watermark 2
    func classForPage() -> AnyClass {
        //        return WatermarkPage.self
        return watermarkLayer
    }
}

extension DocumentViewController: UIPopoverPresentationControllerDelegate {
    // MARK: - PopoverTableViewController Presentation
    // iOS Popover presentation Segue
    // http://sunnycyk.com/2015/08/ios-popover-presentation-segue/
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {}
    // fix for iPhone Plus
    // https://stackoverflow.com/q/36349303/4063462
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

extension DocumentViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        LogManager.shared.log.info(urls)
        if let fileURL = urls.first,
            fileURL.isFileURL{
            
            guard let delegate = UIApplication.shared.delegate as? AppDelegate else {return}
            
            // Reveal / import the document at the URL
            guard let documentBrowserViewController = delegate.window?.rootViewController  as? DocumentBrowserViewController else { return  }
            
            documentBrowserViewController.revealDocument(at: fileURL, importIfNeeded: true) { (revealedDocumentURL, error) in
                if let error = error {
                    // Handle the error appropriately
                    LogManager.shared.log.error("Failed to reveal the document at URL \(fileURL) with error: '\(error)'")
                    return
                }
                if let _ = revealedDocumentURL {
                }
                // Present the Document View Controller for the revealed URL
                documentBrowserViewController.presentDocument(at: revealedDocumentURL!)
            }
        }
    }
    
    func presentDocument(at documentURL: URL) {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        
        let navigationController = storyBoard.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
        
        let documentViewController = navigationController.viewControllers.first as! DocumentViewController
        documentViewController.document = Document(fileURL: documentURL)
        
        navigationController.modalTransitionStyle = .crossDissolve
        present(navigationController, animated: true, completion: nil)
    }
    
    /// picker document
    private func documentPickerAction() {
        
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["com.adobe.pdf"], in: .import)
        documentPicker.allowsMultipleSelection = false
        documentPicker.delegate = self
        navigationController?.pushViewController(documentPicker, animated: true)
    }
    
}



