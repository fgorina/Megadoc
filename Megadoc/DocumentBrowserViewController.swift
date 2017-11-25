//
//  DocumentBrowserViewController.swift
//  Megadoc
//
//  Created by Francisco Gorina Vanrell on 14/11/17.
//  Copyright © 2017 Francisco Gorina. All rights reserved.
//

import UIKit


class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
    
    var cm = CryptoManager()
    
    var unlockButton : UIBarButtonItem?
    var panicButton : UIBarButtonItem?
    var settingsButton : UIBarButtonItem?
    var keysButton : UIBarButtonItem?
    
    var inited = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        delegate = self
        
        
        
        unlockButton = UIBarButtonItem(image: UIImage(named: "Locked"), style: .plain, target: self, action: #selector(self.lockUnlock(a:)))
        panicButton = UIBarButtonItem(image: UIImage(named: "Panic"), style: .plain, target: self, action: #selector(self.panic(_:)))
        settingsButton = UIBarButtonItem(image: UIImage(named: "Settings"), style: .plain, target: self, action: #selector(self.updatePasswords(_:)))
        keysButton = UIBarButtonItem(image: UIImage(named: "Keys"), style: .plain, target: self, action: #selector(self.exportKeys))

        self.additionalTrailingNavigationBarButtonItems = [self.unlockButton!, self.settingsButton!]
        self.additionalLeadingNavigationBarButtonItems = [self.panicButton!, self.keysButton!]
        allowsDocumentCreation = true
        allowsPickingMultipleItems = false
        
        
        // Update the style of the UIDocumentBrowserViewController
        // browserUserInterfaceStyle = .dark
        // view.tintColor = .white
        
        // Specify the allowed content types of your application via the Info.plist.
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    
    // If there exists .private.enc and .public.enc it does nothing
    //  Else if there existys private.pem and public.pem installs them
    // else does nothing
    
    
    func checkKeys(){
        let fm = FileManager.default
        let docDir = AppDelegate.applicationDocumentsDirectory()
        let libDir = AppDelegate.applicationSupportDirectory()
        do{
            
            let oldPublicEncUrl = docDir.appendingPathComponent(".public").appendingPathExtension("enc")
            let oldPrivateEncUrl = docDir.appendingPathComponent(".private").appendingPathExtension("enc")

            var publicEncUrl = libDir.appendingPathComponent(".public").appendingPathExtension("enc")
            var privateEncUrl = libDir.appendingPathComponent(".private").appendingPathExtension("enc")
            
            let publicUrl = docDir.appendingPathComponent("public.pem")
            let privateUrl = docDir.appendingPathComponent("private.pem")
            
            let publicUrlEnc = docDir.appendingPathComponent("public.enc")
            let privateUrlEnc = docDir.appendingPathComponent("private.enc")
            
            
           // Keys exist, use normal way to unlock them
            
            if fm.fileExists(atPath: oldPrivateEncUrl.path) && fm.fileExists(atPath: oldPublicEncUrl.path){
                cm.moveKeys()
            }

            
            if fm.fileExists(atPath: privateEncUrl.path) && fm.fileExists(atPath: publicEncUrl.path){
                // Just if in case
                
                var rsrcs = URLResourceValues()
                rsrcs.isHidden = true
                rsrcs.isExcludedFromBackup = true
                try publicEncUrl.setResourceValues(rsrcs)
                try privateEncUrl.setResourceValues(rsrcs)

                
                askPassword(Notification(name: Notification.Name(rawValue: CryptoManagerNotification.lockScreen.rawValue)))
                
            } else if fm.fileExists(atPath: privateUrl.path) && fm.fileExists(atPath: publicUrl.path){
                
                // Install .pem keys with a standard passphrase that must be changed afterwards
                if let priv = CryptoManager.stringNamed("private", withExtension: "pem"){
                    let pass = "con diez canyones por banda"
                    var enc = try cm.encryptRSAKey(priv, passphrase : pass)
                    try CryptoManager.saveString(enc, into: ".private", withExtension: "enc", dir: libDir)
                    
                    if let pubkey = CryptoManager.stringNamed("public", withExtension: "pem"){
                        cm.publicKey = pubkey
                        enc = try cm.encryptLocalString(pubkey)
                        try CryptoManager.saveString(enc, into: ".public", withExtension: "enc", dir: libDir)
                    }
                    
                    var rsrcs = URLResourceValues()
                    rsrcs.isHidden = true
                    rsrcs.isExcludedFromBackup = true
                    try publicEncUrl.setResourceValues(rsrcs)
                    try privateEncUrl.setResourceValues(rsrcs)
                    // Remove .pem files
                    
                    try fm.removeItem(at: publicUrl)
                    try fm.removeItem(at: privateUrl)
                }
            } else if fm.fileExists(atPath: privateUrlEnc.path) && fm.fileExists(atPath: publicUrlEnc.path){
                let fm = FileManager.default
                do {
                    try fm.moveItem(at: privateUrlEnc, to: privateEncUrl)
                    try fm.moveItem(at: publicUrlEnc, to: publicEncUrl)
                    
                    var rsrcs = URLResourceValues()
                    rsrcs.isHidden = true
                    rsrcs.isExcludedFromBackup = true
                    try publicEncUrl.setResourceValues(rsrcs)
                    try privateEncUrl.setResourceValues(rsrcs)
                    
                }catch{}

            
            }else {
                NSLog("Unsecure program")
            }
            
        } catch {
            
            // No Keys
        }
        
    }
    
     override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(DocumentBrowserViewController.showLocked(_:)), name: NSNotification.Name(rawValue: CryptoManagerNotification.Locked.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DocumentBrowserViewController.lockScreen(_:)), name: NSNotification.Name(rawValue: CryptoManagerNotification.lockScreen.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DocumentBrowserViewController.showUnlocked(_:)), name: NSNotification.Name(rawValue: CryptoManagerNotification.Unlocked.rawValue), object: nil)
    }
        

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
  
        
        /*
 NotificationCenter.default.addObserver(self, selector: #selector(DocumentBrowserViewController.showLocked(_:)), name: NSNotification.Name(rawValue: CryptoManagerNotification.Locked.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DocumentBrowserViewController.lockScreen(_:)), name: NSNotification.Name(rawValue: CryptoManagerNotification.lockScreen.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DocumentBrowserViewController.showUnlocked(_:)), name: NSNotification.Name(rawValue: CryptoManagerNotification.Unlocked.rawValue), object: nil)
        */
        
        // Set lock icon accordingly to state
        if cm.isNotIdentified(false){
            self.unlockButton = UIBarButtonItem(image: UIImage(named: "Locked"), style: .plain, target: self, action: #selector(self.lockUnlock(a:)))
        }
        else{
            self.unlockButton = UIBarButtonItem(image: UIImage(named: "Unlocked"), style: .plain, target: self, action: #selector(self.lockUnlock(a:)))

        }
        self.additionalTrailingNavigationBarButtonItems = [self.unlockButton!, self.settingsButton!]
        
        if !inited {
            
            inited = true
            checkKeys()
            
        }

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func lockUnlock(a : Any?) -> Void{
        
        if cm.isNotIdentified(){
            checkKeys()
        }else{
            cm.unidentify()
        }
        
    }
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        
        //Get the documents directory
        
        let docDir = FileManager.default.temporaryDirectory
        
        
        var i = 0
        var name = "Untitled \(i)"
        
        var aDocumentURL : URL?
        var path = ""
        repeat{
            i = i + 1
            name = "Untitled \(i)"
            aDocumentURL = docDir.appendingPathComponent(name).appendingPathExtension("emd")
            path = aDocumentURL!.path
            
        } while FileManager.default.fileExists(atPath: path)
        
        
        if let newDocumentURL = aDocumentURL,  cm.publicKey != nil{
            let doc = Document(fileURL: newDocumentURL)
            doc.encriptat = true
            doc.cm = self.cm
            doc.save(to: newDocumentURL, for: .forCreating) { (saveSuccess) in
                
                // Make sure the document saved successfully
                guard saveSuccess else {
                    // Cancel document creation
                    importHandler(nil, .none)
                    return
                }
                
                // Close the document.
                doc.close(completionHandler: { (closeSuccess) in
                    
                    // Make sure the document closed successfully
                    guard closeSuccess else {
                        // Cancel document creation
                        importHandler(nil, .none)
                        return
                    }
                    
                    // Pass the document's temporary URL to the import handler.
                    importHandler(newDocumentURL, .move  )
                })
            }
        }else {
            importHandler(nil, .none)
        }
        
        
        // Set the URL for the new document here. Optionally, you can present a template chooser before calling the importHandler.
        // Make sure the importHandler is always called, even if the user cancels the creation request.
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentURLs documentURLs: [URL]) {
        guard let sourceURL = documentURLs.first else { return }
        
        // Present the Document View Controller for the first document that was picked.
        // If you support picking multiple items, make sure you handle them all.
        
        openDocument(at: sourceURL)
        /*
        cm.updateLock()
        if cm.isNotIdentified(){
            checkKeys()
        } else {
            
            presentDocument(at: sourceURL)
        }
         */
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
        //presentDocument(at: destinationURL)
        openDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
        
        if let errorDesc = error?.localizedDescription{
            NSLog("Error importing document : %@", errorDesc)
        }else{
            NSLog("Unknown error while importing document")
        }
    }
    // MARK: Locking
    
    
    
    @objc func showUnlocked(_ not: Notification){
        DispatchQueue.main.async(execute: {
            self.unlockButton = UIBarButtonItem(image: UIImage(named: "Unlocked"), style: .plain, target: self, action: #selector(self.lockUnlock(a:)))
            self.additionalTrailingNavigationBarButtonItems = [self.unlockButton!, self.settingsButton!]
            
        })
    }
    
    @objc func showLocked(_ not: Notification){
        DispatchQueue.main.async(execute: {
            self.unlockButton = UIBarButtonItem(image: UIImage(named: "Locked"), style: .plain, target: self, action: #selector(self.lockUnlock(a:)))
            self.additionalTrailingNavigationBarButtonItems = [self.unlockButton!, self.settingsButton!]
        })
        askPassword(not)
    }
    
    @objc func lockScreen(_ not : Notification){
        let story = UIStoryboard(name: "Main", bundle: nil)
        
        let vc = story.instantiateViewController(withIdentifier: "lockScreen") as! LockController
        vc.cm = self.cm
        vc.modalPresentationStyle = .fullScreen
        UIApplication.shared.keyWindow!.rootViewController!.present(vc, animated: true) {
            
        }
    }
    
    @objc func askPassword(_ not : Notification){
        let story = UIStoryboard(name: "Main", bundle: nil)
        
        let vc = story.instantiateViewController(withIdentifier: "enterPassword") as! PassphraseViewController
        vc.cm = self.cm
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true) {
            
        }
        
    }

    
    func lockAll(_ not : Notification){
        askPassword(not)
    }
    
    // MARK: Functions
    
    @objc func exportKeys(){
        
        if !cm.isNotIdentified(true){
        
            let alertController = UIAlertController(title: "Atenció", message: "Estas segur que vols exportar les 🔑🔑?", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "SI", style: .default) { (UIAlertAction) in
                self.cm.exportKeys()
            }
            let cancelAction = UIAlertAction(title: "Cancel·la", style: .cancel) { (UIAlertAction) in
                NSLog("Cancel·lat")
            }
            alertController.addAction(defaultAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        } else {
            let alertController = UIAlertController(title: "Atenció", message: "⚠️ Per exportar les 🔑🔑 cal estar identificat!!!", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .default) { (UIAlertAction) in
               
            }

            alertController.addAction(defaultAction)

            present(alertController, animated: true, completion: nil)
        }
    }
    
    func openDocument(at url : URL?){
        
        if cm.isNotIdentified(true){
            
            let story = UIStoryboard(name: "Main", bundle: nil)
            let vc = story.instantiateViewController(withIdentifier: "enterPassword") as! PassphraseViewController
            vc.cm = cm
            vc.modalPresentationStyle = .formSheet
            vc.userInfo = ["URL": url!]
            vc.block = { (_ userInfo : [String:Any]?)->Void in
                if let info = userInfo {
                    if let url = info["URL"] as? URL{
                        self.presentDocument(at: url)
                    }
                }
            }
            UIApplication.shared.keyWindow!.rootViewController!.present(vc, animated: true) { }
        }else{
            cm.updateLock()
            self.presentDocument(at: url!)
        }
        
    }
    
    @objc func updatePasswords(_ a : Any?){
        let story = UIStoryboard(name: "Main", bundle: nil)
        
        let vc = story.instantiateViewController(withIdentifier: "changePassword") as! ChangePasswordViewController
        vc.cm = cm
        vc.modalPresentationStyle = .formSheet
        UIApplication.shared.keyWindow!.rootViewController!.present(vc, animated: true) {
            
            
        }
        
    }
    
    /* ATENCIO. Aquest reset elimina totes les claus. per tant tota l'incormació encriptada DEIXA DE SER ACCESIBLE!!!
     Per recuperar-la necessitem reinstal·lar les claus
     Afegint al directori de l'aplicació les claus .PEM no encriptades
     Al executar el unlock la primera vegada ens demanara el password i les instal·lara
     
     */
    @objc func panic(_ a : Any?){
        
        let alertController = UIAlertController(title: "Atenció", message: "😱 Has premut PANIC. Vols continuar?", preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "SI", style: .destructive) { (UIAlertAction) in
            do {try  self.cm.resetAll() } catch {}
        }
        let cancelAction = UIAlertAction(title: "Cancel·la", style: .default) { (UIAlertAction) in
            NSLog("Cancel·lat")
        }
        alertController.addAction(defaultAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    // MARK: Document Presentation
    
    func presentDocument(at documentURL: URL) {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let documentViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentViewController") as! DocumentViewController
        documentViewController.document = Document(fileURL: documentURL)
        documentViewController.document?.cm = self.cm
        present(documentViewController, animated: true, completion: nil)
    }
}

