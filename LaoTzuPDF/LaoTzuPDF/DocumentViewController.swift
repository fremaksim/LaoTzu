//
//  DocumentViewController.swift
//  LaoTzuPDF
//
//  Created by mozhe on 2018/12/5.
//  Copyright © 2018 mozhe. All rights reserved.
//

import UIKit
import PDFKit

protocol SettingsDelegate {
    //    var isVerticalWriting: Bool { get }
    //    var isRightToLeft: Bool { get }
    var isEncrypted: Bool { get }
    var allowsDocumentAssembly: Bool { get }
    func writing(vertically: Bool, rightToLeft: Bool) -> Void
    func goToPage(page: PDFPage) -> Void
    func selectOutline(outline: PDFOutline) -> Void
}

extension DocumentViewController: SettingsDelegate {
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
    
    @IBOutlet weak var pdfView: PDFView!
    
    var document: Document?
    
    let userDeaults = UserDefaults.standard
    
    var portraitScaleFactorForSizeToFit: CGFloat = 0.0
    var landscapeScaleFactorForSizeToFit: CGFloat = 0.0
    
    // delegate properties
    var isVerticalWriting = false
    var isRightToLeft = false
    var isEncrypted = false
    var allowsDocumentAssembly = false
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        updateInterface()
        super.viewWillAppear(animated)
        navigationController?.hidesBarsOnTap = true
        
        loadDocument()
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
                
                self.allowsDocumentAssembly = document.allowsDocumentAssembly
                self.isEncrypted = document.isEncrypted
                
                // watermark 1
                document.delegate = self
                self.pdfView.document = document
                
                
                self.moveToLastReadingProsess()
                if self.pdfView.displayDirection == .vertical {
                    self.getScaleFactorForSizeToFit()
                }
                
                self.writing(vertically: self.isVerticalWriting, rightToLeft: self.isRightToLeft)
                
                self.setPDFThumbnailView()
            } else {
                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
            }
        })
    }
    
    override func viewDidLoad() {
        navigationController?.barHideOnTapGestureRecognizer.addTarget(self, action: #selector(barHideOnTapGestureRecognizerHandler))
        
        
        pdfView.autoScales = true
        pdfView.displaysPageBreaks = false
        pdfView.displayBox = .cropBox
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        
        //        pdfView.usePageViewController(true, withViewOptions: nil)
        for view in pdfView.subviews {
            if view.isKind(of: UIScrollView.self) {
                (view as? UIScrollView)?.scrollsToTop = false
                (view as? UIScrollView)?.contentInsetAdjustmentBehavior = .scrollableAxes
            }
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
        center.addObserver(self,
                           selector: #selector(didHitAnnotation), name: NSNotification.Name.PDFViewAnnotationHit, object: nil)
        
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
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
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
    
    func writing(vertically: Bool, rightToLeft: Bool) {
        // experimental feature
        if let currentPage = pdfView.currentPage {
            if let document: PDFDocument = pdfView.document {
                let currentIndex: Int = document.index(for: currentPage)
                
                print("currentIndex: \(currentIndex)")
                
                if rightToLeft != isRightToLeft {
                    if !allowsDocumentAssembly {
                        return
                    }
                    //
                    let pageCount: Int = document.pageCount
                    
                    print("pageCount: \(pageCount)")
                    for i in 0..<pageCount/2 {
                        print("exchangePage at: \(i), withPageAt: \(pageCount-i-1)")
                        document.exchangePage(at: i, withPageAt: pageCount-i-1)
                    }
                    if currentIndex != pageCount - currentIndex - 1 {
                        if let pdfPage = document.page(at: pageCount - currentIndex - 1) {
                            print("go to: \(pageCount - currentIndex - 1)")
                            pdfView.go(to: pdfPage)
                        }
                    }
                    isRightToLeft = rightToLeft
                }
                
                if vertically != isVerticalWriting {
                    if vertically {
                        pdfView.displayDirection = .horizontal
                    } else {
                        pdfView.displayDirection = .vertical
                    }
                    isVerticalWriting = vertically
                }
                
                // reset document to update interface
                pdfView.document = nil
                pdfView.document = document
                pdfView.go(to: currentPage)
            }
        }
        
        setScaleFactorForSizeToFit()
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
    
    @objc func barHideOnTapGestureRecognizerHandler() {
        navigationController?.setToolbarHidden(navigationController?.isNavigationBarHidden == true, animated: true)
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
            } else if isVerticalWriting {
                //
                if let pageCount: Int = pdfView.document?.pageCount {
                    pageIndex = pageCount - 1
                }
            }
            // TODO: if pageIndex == pageCount - 1, then go to last CGRect
            if let pdfPage = pdfView.document?.page(at: pageIndex) {
                pdfView.go(to: pdfPage)
            }
        }
    }
    
    @objc func saveAndClose() {
        guard let pdfDocument = pdfView.document else { return }
        if let currentPage = pdfView.currentPage {
            var currentIndex = pdfDocument.index(for: currentPage)
            if isRightToLeft {
                currentIndex = pdfDocument.pageCount - currentIndex - 1
            }
            if let documentURL = pdfView.document?.documentURL {
                userDeaults.set(currentIndex, forKey: documentURL.path)
                print("saved page index: \(String(describing: currentIndex))")
            }
        }
        
        self.document?.close(completionHandler: nil)
    }
    
    @objc func didChangeOrientationHandler() {
        setScaleFactorForSizeToFit()
    }
    
    @objc func didHitAnnotation(_ noti: NSNotification) {
        //        Log.output().info(noti.userInfo)
        
        // clean
        view.subviews.filter { (view) -> Bool in
            view is AnnotationPopView
            }.forEach { (view) in
                view.removeFromSuperview()
        }
        
        
        guard let userInfo = noti.userInfo else {
            return
        }
        Log.output().info(userInfo)
        if let annotation = userInfo["PDFAnnotationHit"] as? PDFAnnotation { //
            Log.output().info(annotation.bounds)
            let convertRect = pdfView.convert(annotation.bounds, from: annotation.page!)
            Log.output().info(convertRect)
            
            let scale: CGFloat = 4.0
            var targetRect = convertRect
            targetRect.size.width *= scale
            targetRect.size.height *= scale
            
            let scaleView: AnnotationPopView = AnnotationPopView(frame: targetRect)
            scaleView.contents = annotation.contents
            
            view.addSubview(scaleView)
            UIView.animateKeyframes(withDuration: 1,
                                    delay: 0,
                                    options:.calculationModeCubic,
                                    animations: {
                                        
                                        UIView.addKeyframe(withRelativeStartTime: 0.25,
                                                           relativeDuration: 0.0,
                                                           animations: {
                                                            var newFrame = scaleView.frame
                                                            newFrame.size.width  = convertRect.width
                                                            newFrame.size.height = convertRect.height
                                                            scaleView.frame = newFrame
                                                            
                                        })
                                        UIView.addKeyframe(withRelativeStartTime: 0.25,
                                                           relativeDuration: 0.25,
                                                           animations: {
                                                            var newFrame = scaleView.frame
                                                            newFrame.size.width = convertRect.width * 2
                                                            newFrame.size.height = convertRect.height * 2
                                                            scaleView.frame = newFrame
                                                            
                                        })
                                        UIView.addKeyframe(withRelativeStartTime: 0.5,
                                                           relativeDuration: 0.25,
                                                           animations: {
                                                            var newFrame = scaleView.frame
                                                            newFrame.size.width = convertRect.width * 3
                                                            newFrame.size.height = convertRect.height * 3
                                                            scaleView.frame = newFrame
                                                            
                                        })
                                        UIView.addKeyframe(withRelativeStartTime: 0.75,
                                                           relativeDuration: 0.25,
                                                           animations: {
                                                            var newFrame = scaleView.frame
                                                            newFrame.size.width = convertRect.width * 4
                                                            newFrame.size.height = convertRect.height * 4
                                                            scaleView.frame = newFrame
                                                            
                                        })
                                        
                                        
                                        
            }) { (_) in
                
            }
            
            
        }
    }
    
    //MARK: - UI Event
    
    @IBAction func dismissDocumentViewController() {
        dismiss(animated: true) {
            self.saveAndClose()
        }
    }
    
    @IBAction func shareAction() {
        let activityVC = UIActivityViewController(activityItems: [document?.fileURL as Any], applicationActivities: nil)
        self.present(activityVC, animated: true, completion: nil)
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
        
        MaskPopViewController.show(on: self, with: customView)
    }
    
    @objc func annotationButtonClick() {
        // detect this file is in Document/Inbox
        if document?.isInDocumentInbox() == true { // Copy to folder
            
        }else {
            
        }
        
        if navigationController?.isNavigationBarHidden != true {
            navigationController?.isNavigationBarHidden = true
            navigationController?.isToolbarHidden = true
        }
        
        documentPickerAction()
    }
    
    /// picker document
    private func documentPickerAction() {
        
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["com.adobe.pdf"], in: .import)
        documentPicker.allowsMultipleSelection = false
        documentPicker.delegate = self
        navigationController?.pushViewController(documentPicker, animated: true)
    }
    
}

extension DocumentViewController: PDFDocumentDelegate {
    // Watermark 2
    func classForPage() -> AnyClass {
        return WatermarkPage.self
    }
}

extension DocumentViewController: UIPopoverPresentationControllerDelegate {
    // MARK: - PopoverTableViewController Presentation
    
    // iOS Popover presentation Segue
    // http://sunnycyk.com/2015/08/ios-popover-presentation-segue/
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /* if (segue.identifier == "PopoverSettings") {
         if let popopverVC: PopoverTableViewController = segue.destination as? PopoverTableViewController {
         popopverVC.modalPresentationStyle = .popover
         popopverVC.popoverPresentationController?.delegate = self
         popopverVC.delegate = self
         if !isEncrypted {
         // 201 - 44 = 157
         popopverVC.preferredContentSize = CGSize(width: 300, height: 157)
         }
         }
         } else if (segue.identifier == "Container") {
         if let containerVC: ContainerViewController = segue.destination as? ContainerViewController {
         containerVC.pdfDocument = pdfView.document
         containerVC.displayBox = pdfView.displayBox
         if let currentPage = pdfView.currentPage, let document: PDFDocument = pdfView.document {
         containerVC.currentIndex = document.index(for: currentPage)
         }
         containerVC.delegate = self
         }
         }
         */
    }
    
    // fix for iPhone Plus
    // https://stackoverflow.com/q/36349303/4063462
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

extension DocumentViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        Log.output().info(urls)
        if let fileURL = urls.first,
            fileURL.isFileURL{
            
            guard let delegate = UIApplication.shared.delegate as? AppDelegate else {return}
            
            // Reveal / import the document at the URL
            guard let documentBrowserViewController = delegate.window?.rootViewController  as? DocumentBrowserViewController else { return  }
            
            documentBrowserViewController.revealDocument(at: fileURL, importIfNeeded: true) { (revealedDocumentURL, error) in
                if let error = error {
                    // Handle the error appropriately
                    Log.output().error("Failed to reveal the document at URL \(fileURL) with error: '\(error)'")
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
}

