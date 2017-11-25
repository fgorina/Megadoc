//
//  Document.swift
//  Megadoc
//
//  Created by Francisco Gorina Vanrell on 14/11/17.
//  Copyright © 2017 Francisco Gorina. All rights reserved.
//

import UIKit

class Document: UIDocument {
    
    weak var cm : CryptoManager?
    var contingut = "# Untitled"
    var encriptat = false
    
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        //return Data()
        
        if self.fileURL.pathExtension == "emd" && encriptat{
            if let cma = cm {
                cma.updateLock()
                if let pkey = cma.publicKey{
                    if let encstr = try? cma.encrypt(contingut, publicKeyPEM: pkey){
                        return encstr.data(using: .utf8)!
                    }
                }
            }
        }
        
        // Default save a plain document
        return contingut.data(using: .utf8)!
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
        
        if contents is Data {
            encriptat = false
            let dcontent = contents as! Data
            contingut = String(data: dcontent, encoding: .utf8)!
            if self.fileURL.pathExtension == "emd"{
                if let cma = cm {
                    cma.updateLock()
                    if !cma.isNotIdentified(){
                        if let data  = try? cma.decrypt(contingut){
                            contingut = data
                            encriptat = true
                        }
                        
                    }
                }
            }
        }
    }
    
    override func fileAttributesToWrite(to url: URL, for saveOperation: UIDocumentSaveOperation) throws -> [AnyHashable : Any] {
        
        if let thumb = UIImage(named: "doc_320x320.png"){
            return [
                URLResourceKey.hasHiddenExtensionKey : true,
                URLResourceKey.thumbnailDictionaryKey : [
                    URLThumbnailDictionaryItem.NSThumbnail1024x1024SizeKey : thumb
                ]
            ]
        } else {
            return [:]
        }
        
    }
    
    func exportToTempURL() -> URL?{
        
        let name = self.fileURL.deletingPathExtension().lastPathComponent
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(name).appendingPathExtension("md")
        do{
            try contingut.write(to: tempFile, atomically: true, encoding: .utf8)
            return tempFile
        }catch {
            return nil
        }
    }
    
}

