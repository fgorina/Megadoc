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
    
    @IBOutlet weak var documentNameLabel: UILabel!
    @IBOutlet weak var fTextArea: UITextView!
    @IBOutlet weak var fRenderButton: UIButton!
    var document: Document?
    
    var downView : DownView?
    var webView : WKWebView?
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // register notifications for the Keyboard
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.showKeyboard(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideKeyboard(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // Access the document
        document?.open(completionHandler: { (success) in
            if success {
                // Display the content of the document, e.g.:
                self.fTextArea.text = self.document?.contingut
                self.documentNameLabel.text = self.document?.fileURL.lastPathComponent
            } else {
                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        
    }
    
    @IBAction func dismissDocumentViewController() {
        dismiss(animated: true) {
            self.document?.contingut = self.fTextArea.text
            self.document?.save(to: (self.document?.fileURL)!, for: UIDocumentSaveOperation.forOverwriting, completionHandler: { (done : Bool) in
                self.document?.close(completionHandler: nil)
            })
            
        }
    }
    
    @IBAction func closeKeyboard(){
        fTextArea.resignFirstResponder()
    }
    
    @IBAction func render(){
        
        if let dw = webView{
            dw.removeFromSuperview()
            webView  = nil
            fRenderButton.setTitle("Render", for: .normal)
            let image = UIImage(named: "View")
            fRenderButton.setImage(image!, for: .normal)
        }else {
            do {
                closeKeyboard()
                let down = Down(markdownString: (document?.contingut)!)
                let html = try down.toHTML()
                let webConfiguration = WKWebViewConfiguration()
                webView = WKWebView(frame: self.fTextArea.frame, configuration: webConfiguration)
                self.view.addSubview(self.webView!)
                self.fRenderButton.setTitle("Edit", for: .normal)
                webView?.loadHTMLString(html, baseURL: nil)
                let image = UIImage(named: "Edit")
                fRenderButton.setImage(image!, for: .normal)
                
                
            }catch {
                
            }
            
        }
        
    }
    
    @IBAction func render_x(){
        
        if let dw = downView{
            dw.removeFromSuperview()
            downView = nil
            fRenderButton.setTitle("Render", for: .normal)
        }else {
            do {
                let down = Down(markdownString: (document?.contingut)!)
                let html = try? down.toHTML()
                NSLog(html!)
                downView = try DownView(frame: self.fTextArea.frame, markdownString: (document?.contingut)!) {
                    // Optional callback for loading finished
                    self.view.addSubview(self.downView!)
                    self.fRenderButton.setTitle("Edit", for: .normal)
                }
            }catch {
                
            }
            
        }
        
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
    
}

extension DocumentViewController : UITextViewDelegate{
    
    func textViewDidChange(_ textView: UITextView){
        self.document?.contingut = self.fTextArea.text
        
    }
}
