//
//  AppDelegate.swift
//  Megadoc
//
//  Created by Francisco Gorina Vanrell on 14/11/17.
//  Copyright © 2017 Francisco Gorina. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var settings : [String:Double] = ["identifyTimeout":300.0, "lockTimeout": 30.0, "panicEnabled": 1.0]

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // Check if threre are settings
        return true
      }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ app: UIApplication, open inputURL: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        // Ensure the URL is a file URL
        guard inputURL.isFileURL else { return false }
                
        // Reveal / import the document at the URL
        guard let documentBrowserViewController = window?.rootViewController as? DocumentBrowserViewController else { return false }

        documentBrowserViewController.revealDocument(at: inputURL, importIfNeeded: true) { (revealedDocumentURL, error) in
            if let error = error {
                // Handle the error appropriately
                print("Failed to reveal the document at URL \(inputURL) with error: '\(error)'")
                return
            }
            //documentBrowserViewController.presentDocument(at: revealedDocumentURL!)
            
            documentBrowserViewController.openDocument(at: revealedDocumentURL!)
             
            // Present the Document View Controller for the revealed URL
        }

        return true
    }
    
    //MARK: Utilities
    
    static func applicationDocumentsDirectory() -> URL{
        
        let fm = FileManager.default
        var docs = fm.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last! as URL
 
        var isDir : ObjCBool = ObjCBool(false)
        do{
            if !fm.fileExists(atPath: docs.path, isDirectory: &isDir){
                try fm.createDirectory(at: docs, withIntermediateDirectories: true, attributes: [:])
            }else if !isDir.boolValue{
                try fm.removeItem(at: docs)
                try fm.createDirectory(at: docs, withIntermediateDirectories: true, attributes: [:])
            }else{
                var rsrcs = URLResourceValues()
                rsrcs.isHidden = false
                rsrcs.isExcludedFromBackup = false
                try docs.setResourceValues(rsrcs)

            }
        }catch{
            NSLog(error.localizedDescription)
        }

        return docs
    }

    static func applicationSupportDirectory() -> URL{
        
        let fm = FileManager.default
        let support = fm.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last! as URL
        
        var isDir : ObjCBool = ObjCBool(false)
        do{
            if !fm.fileExists(atPath: support.path, isDirectory: &isDir){
                try fm.createDirectory(at: support, withIntermediateDirectories: true, attributes: [:])
            }else if !isDir.boolValue{
                try fm.removeItem(at: support)
                try fm.createDirectory(at: support, withIntermediateDirectories: true, attributes: [:])
            }
        }catch{
            NSLog(error.localizedDescription)
        }
        
        return support
    }

    
    static func showErrorMessage(_ text : String){
        
        NSLog("Error %@", text)
        
        return
        
        let alertController = UIAlertController(title: "Error", message: text, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default) { (UIAlertAction) in
        }
        alertController.addAction(defaultAction)
        UIApplication.shared.keyWindow!.rootViewController!.present(alertController, animated: true, completion: nil)
    }



}

