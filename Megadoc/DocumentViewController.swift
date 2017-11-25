//
//  DocumentViewController.swift
//  Megadoc
//
//  Created by Francisco Gorina Vanrell on 14/11/17.
//  Copyright © 2017 Francisco Gorina. All rights reserved.
//

import UIKit
import Down
import WebKit

class DocumentViewController: UIViewController {
    
    @IBOutlet weak var fTextArea: UITextView!
    @IBOutlet weak var  webView : WKWebView!
    @IBOutlet weak var fRenderButton: UIButton!
    @IBOutlet weak var fNavigationBar: UINavigationBar!
    @IBOutlet weak var fDocTitle: UINavigationItem!
    
    @IBOutlet weak var fTextAreaTrailing: NSLayoutConstraint!
    @IBOutlet weak var fTextAreaLeading: NSLayoutConstraint!
    
    var document: Document?
    var downView : DownView?
    
    enum states {
        case editor
        case mixed
        case viewer
    }
    
    var state = states.mixed
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.traitCollection.horizontalSizeClass == .regular {
            if self.view.bounds.size.height < self.view.bounds.width{
                setState(.mixed)
            }else{
                setState(.editor)
            }
        } else {
            setState(.editor)
        }
        
        // register notifications for the Keyboard
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.showKeyboard(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideKeyboard(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(DocumentViewController.showLocked(_:)), name: NSNotification.Name(rawValue: CryptoManagerNotification.Locked.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DocumentViewController.lockScreen(_:)), name: NSNotification.Name(rawValue: CryptoManagerNotification.lockScreen.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DocumentViewController.showUnlocked(_:)), name: NSNotification.Name(rawValue: CryptoManagerNotification.Unlocked.rawValue), object: nil)

        
        // Access the document
        document?.open(completionHandler: { (success) in
            if success {
                // Display the content of the document, e.g.:
                self.fTextArea.text = self.document?.contingut
                self.fDocTitle.title = self.document?.localizedName
                //self.documentNameLabel.text = self.document?.fileURL.lastPathComponent
                self.document?.cm?.updateLock()
                let down = Down(markdownString: (self.document?.contingut)!)
                if let html = try? down.toHTML(){
                    self.webView .loadHTMLString(html, baseURL: nil)
                }
                self.document?.cm?.updateLock()
                
            } else {
                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        
        if self.traitCollection.horizontalSizeClass == .regular {
            if let pt = previousTraitCollection{
                if pt.horizontalSizeClass != .regular {
                    if self.view.bounds.size.height < self.view.bounds.size.width{
                        self.setState(.mixed)
                    } else {
                        self.setState(.viewer)
                    }
                }
            }
            
        } else if self.traitCollection.horizontalSizeClass == .compact {
            if let pt = previousTraitCollection{
                if pt.horizontalSizeClass != .compact && state == .mixed{
                    self.setState(.viewer)
                }
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        if self.traitCollection.horizontalSizeClass == .regular {
            if size.height < size.width{
                self.setState(.mixed, width : size.width)
            } else {
                self.setState(.viewer, width : size.width)
            }
            
        }
    }
    
    @IBAction func dismissDocumentViewController() {
        dismiss(animated: true) {
            self.document?.contingut = self.fTextArea.text
            self.document?.save(to: (self.document?.fileURL)!, for: UIDocumentSaveOperation.forOverwriting, completionHandler: { (done : Bool) in
                self.document?.close(completionHandler: nil)
            })
            
        }
        
    }
    
    @IBAction func exportDoc(_ item : Any){
        if let doc = document, let button = item as? UIBarButtonItem {
            if let url = doc.exportToTempURL(){
            
                let activityController = UIActivityViewController(activityItems: [url ], applicationActivities: nil)
                if let popoverPresentationController = activityController.popoverPresentationController {
                    popoverPresentationController.barButtonItem = button
                }
                activityController.completionWithItemsHandler = { (a : UIActivityType?, completed : Bool, returned : [Any]?, err : Error?) -> Void in
                    let fm = FileManager.default
                    do { try fm.removeItem(at: url) } catch {}
                }
                    
                self.present(activityController, animated: true, completion: nil)
                
            }
            
        }
    }
    
    @IBAction func closeKeyboard(){
        fTextArea.resignFirstResponder()
    }
    
    
    @IBAction func back(){
        if let wb = webView{
            if wb.canGoBack{
                wb.goBack()
            }
        }
    }
    
    @IBAction func forward(){
        if let wb = webView{
            if wb.canGoForward{
                wb.goForward()
            }
        }
    }
    
    @objc func showKeyboard(_ notification : Notification){
        if let info = notification.userInfo{
            let kbSize = (info[UIKeyboardFrameEndUserInfoKey] as! CGRect).size
            let contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0)
            fTextArea.contentInset = contentInsets
            let range = fTextArea.selectedRange
            fTextArea.scrollRangeToVisible(range)
            
        }
    }
    @objc func hideKeyboard(_ notification : Notification){
        let contentInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
        fTextArea.contentInset = contentInsets
        fTextArea.scrollIndicatorInsets = contentInsets
        
    }
    
    @IBAction func allEdit(){
        
        if self.traitCollection.horizontalSizeClass == .compact{
            setState(.editor)
            
        }else if self.traitCollection.horizontalSizeClass == .regular && state == .viewer{
            setState(.mixed)
        }else if self.traitCollection.horizontalSizeClass == .regular && state == .mixed{
            setState(.editor)
        }
    }
    
    @IBAction func allView(){
        if self.traitCollection.horizontalSizeClass == .compact{
            setState(.viewer)
            
        }else if self.traitCollection.horizontalSizeClass == .regular && state == .editor{
            setState(.mixed)
        }else if self.traitCollection.horizontalSizeClass == .regular && state == .mixed{
            setState(.viewer)
        }
    }
    
    @objc func showUnlocked(_ not: Notification){
        DispatchQueue.main.async(execute: {
            //self.unlockButton = UIBarButtonItem(image: UIImage(named: "Unlocked"), style: .plain, target: self, action: #selector(self.lockUnlock(a:)))
            //self.additionalTrailingNavigationBarButtonItems = [self.unlockButton!, self.settingsButton!]
            
        })
    }
    
    @objc func showLocked(_ not: Notification){
        self.dismissDocumentViewController()
        let bvc = UIApplication.shared.keyWindow!.rootViewController! as! DocumentBrowserViewController
        bvc.askPassword(not)
        
    }
    
    @objc func lockScreen(_ not : Notification){
        
        let story = UIStoryboard(name: "Main", bundle: nil)
        let vc = story.instantiateViewController(withIdentifier: "lockScreen") as! LockController
        vc.cm = self.document!.cm!
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true) {
            
        }
    }

    @objc func askPassword(_ not : Notification){
        let story = UIStoryboard(name: "Main", bundle: nil)
        
        let vc = story.instantiateViewController(withIdentifier: "enterPassword") as! PassphraseViewController
        vc.cm = self.document!.cm!
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true) {
            
        }
    }

    func setState(_ aState : states, width : CGFloat = 0.0){
        
        switch aState{
        case .editor:
            screen(0.0, width:width)
            
        case .mixed:
            screen(0.5, width:width)
            
        case .viewer:
            screen(1.0, width:width)
        }
        self.state = aState
    }
    
    
    func screen(_ percent : Double, width : CGFloat = 0.0){
        var w = view.bounds.size.width
        if width > 0 {
            w = width
        }
        let pwidth : CGFloat = w * CGFloat(percent)
        
        fTextAreaTrailing.constant = -pwidth
    }
    
    
}

extension DocumentViewController : UITextViewDelegate{
    
    func textViewDidChange(_ textView: UITextView){
        if let cm = document?.cm {
            cm.updateLock()
        }
        self.document?.contingut = self.fTextArea.text
        let down = Down(markdownString: (document?.contingut)!)
        if let html = try? down.toHTML(){
            webView .loadHTMLString(html, baseURL: nil)
        }
        
        
    }
}
