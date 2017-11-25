//
//  CryptoManager.swift
//  TestSwiftRSA
//
//  Created by Francisco Gorina Vanrell on 19/5/16.
//  Copyright © 2016 Docs. All rights reserved.
//

import Foundation
import CryptoSwift
import SwiftyRSA

public enum CryptoManagerError: Error {
    case base64EncodingError
    case base64DecodingError
    case utf8Encoding
    case noPublicKey
    case noPrivateKey
    case locked
    
    
    
    static let errorMessages = [
        base64EncodingError : "Error encoding Base 64",
        base64DecodingError : "Error decoding Base 64",
        utf8Encoding : "Error encoding/decoding UTF8",
        noPublicKey : "There is no public key",
        noPrivateKey : "There is no private key",
        locked : "System is locked"]
    
    func localizedMessage() -> String {
        if let errorMessage = CryptoManagerError.errorMessages[self] {
            return errorMessage
        } else {
            return "Unknown"
        }
    }
}

public enum CryptoManagerNotification : String{
    
    case Locked = "CryptoManagerUnidentified"
    case Unlocked = "CryptoManagerIdentified"
    case lockScreen = "CryptoManagerLockScreen"
    
}

/// CryptoManager is the main crypto class.
/// It has a simple state :
///
///     - **Locked** : Is its Natural state. Doesn't allow to decrypt anything
///     - **Unlocked** : It allows decryption
///
/// The main difference is that in Locked privateKey is null and in Unlocked is the decrypted private key
/// Once identified the public key is not nulled when unidentifying. In fact it is a public key, isn't it?
///
/// Private and Public keys are stored in .private.enc and .public.enc file in Library/Application Support directory
///
/// It maintains 2 timers. lockPeriod is the maximum time in seconds before it clears the private key in memory
/// and goes to locked state. fastLockPeriog generates events to help the application lock the screen but it doesn't
/// clear the private key in memory so it is not necessary to reenter the passphrase
///


class CryptoManager : NSObject {
    
    fileprivate let lockPeriod = 600.0       /// Locks the Manager erasing the private key from memory
    fileprivate let fastLockPeriod = 60.0    /// Generates lock notifications to lock the screen
    
    fileprivate var identifyTimer : Timer?  /// Locks the Manager erasing the private key from memory
    fileprivate var lockTimer : Timer?      /// Generates lock notifications to lock the screen
    
    fileprivate var privateKey : String?    /// The private key decrypted in PEM format
    internal var publicKey : String?        /// The public key decrypted in PEM format
    
    var  fingerTries = 0
    
    
    override init(){
        super.init()
        self.lockTimer = Timer.scheduledTimer(withTimeInterval: fastLockPeriod, repeats: false, block: { (t : Timer) in
            self.relock()
        })
    }
    
    /// Nulls the privateKey preventing decryption
    /// Also invaludates the identify Ti becasuse we are already unidentified
    /// Generates a .Locked notification for UI to update screen etc.
    
    func unidentify(){
        
        privateKey = nil
        // publicKey = nil public key is not cleared to be able to write new encrypted docs while locked.
        
        if let timer = self.identifyTimer {
            timer.invalidate()
            self.identifyTimer = nil
        }
        
        let not = Notification(name: Notification.Name(rawValue: CryptoManagerNotification.Locked.rawValue), object: self)
        NotificationCenter.default.post(not)
    }
    
    /// Function called by the Identify timer. Just calls unidentify
    ///
    func reidentify(){
        self.unidentify()
    }
    
    /// Function called to lock the Screen. Generates a .lockScreen notification
    /// and invalidates the lock timer
    func relock(){
        
        if let lt = lockTimer{
            lt.invalidate()
            lockTimer = nil
        }
        let not = Notification(name: Notification.Name(rawValue: CryptoManagerNotification.lockScreen.rawValue), object: self)
        NotificationCenter.default.post(not)
    }
    
    /// Function to update the timers.
    /// Must be called from UI when some user action takes place (writing, scrolling, selectiong a file)
    /// to prevent CryptoManager from locking
    
    func updateLock(){
        
        
        if let lt = lockTimer{
            lt.invalidate()
        }
        if let lt = identifyTimer{
            lt.invalidate()
        }
        self.lockTimer = Timer.scheduledTimer(withTimeInterval: fastLockPeriod, repeats: false, block: { (t : Timer) in
            self.relock()
        })
        

        if privateKey != nil {
            self.identifyTimer = Timer.scheduledTimer(withTimeInterval: lockPeriod, repeats: false, block: { (t : Timer) in
                self.reidentify()
            })
        }
    }
    
    
    /**
        This is the identification function.
     
        Receives a passphrase and uses it to:
 
    - Decrypt the private key and store it in memory
    - Decrypt the public key and store it in memory
    - Enable the timers
     
        It maintains a resource key with the number of failed atempts
        If it arrives to 3, just clears all key files so information
        is no more accessible until keys are replaced .
 
     - Parameter passphrase: The passphrase or password. Must be quite secure.
     - Returns: **true** if identified correctly, **false** otherwise
 
    */
    func identify(_ passphrase : String) -> Bool{
        if passphrase.count <= 0{
            return false
        }
        if let epk = CryptoManager.stringNamed(".private", withExtension: "enc", dir: AppDelegate.applicationSupportDirectory()){
            
            do {
                let aux = try self.decryptRSAKey(epk, passphrase: passphrase)
                if aux.contains("BEGIN RSA PRIVATE KEY"){
                    
                    self.privateKey = aux
                    self.resetFailCount()
                    let not = Notification(name: Notification.Name(rawValue: CryptoManagerNotification.Unlocked.rawValue), object: self)
                    NotificationCenter.default.post(not)
                    // Set the timer so
                    
                    self.identifyTimer = Timer.scheduledTimer(withTimeInterval: lockPeriod, repeats: false, block: { (t : Timer) in
                        self.reidentify()
                    })
                    
                    self.lockTimer = Timer.scheduledTimer(withTimeInterval: fastLockPeriod, repeats: false, block: { (t : Timer) in
                        self.relock()
                    })
                    
                }else{
                    self.checkFailCount()
                    return false
                }
            }catch{
                self.checkFailCount()
                return false
            }
        } else{
            return false
        }
        
        if let epuk = CryptoManager.stringNamed(".public", withExtension: "enc", dir: AppDelegate.applicationSupportDirectory()){
            
            do {
                let aux = try decryptLocalString(epuk)
                if aux.contains("BEGIN PUBLIC KEY"){
                    self.publicKey = aux
                    return true
                    
                }else {
                    return false
                }
            }catch{
                return false
            }
        } else {
            return false
        }
        
    }
    
    /**
        Function to manage the number of failed identify atempts.
 
        Be careful as it stores data un a UserDefaults and clear the keys from disk
        when failed more than 3 times independently of . It is extreme but it is secure
     
        It is called every time we get a failed identify attempt
    */
    func checkFailCount(){
        
        let store = UserDefaults.standard
        let n = store.integer(forKey: "x123")
        if n >= 2{
            do{ try self.resetAll() } catch {}
            
        } else {
            store.set(n+1, forKey: "x123")
        }
        store.synchronize()
    }
    
    /**
        Function that sets to 0 the number of failed atempts
 
        it is called when we get a correct identification
 
    */
    func resetFailCount(){
        
        let store = UserDefaults.standard
        store.set(0, forKey: "x123")
        store.synchronize()
    }
    /// - Returns: number of failed atempts + 1
    
    func getRemainingCount() -> Int{
        let store = UserDefaults.standard
        let n = store.integer(forKey: "x123")
        //return 3 - n
        return n+1
    }
    
    
    
    /// Returns if the CryptoManager has identified the user
    ///
    /// - parameter update : if true updates the lock timer
    /// - Returns: **true** if not identified
    
    func isNotIdentified(_ update : Bool = false) -> Bool{
        if update {
            self.updateLock()
        }
        return privateKey == nil
    }
    
    /**
        Changes the passphrase that encrypts the private key.
 
        It reads the key and decrypts it  with the old password, encrypts it with new one
        and writes it to the disk.
     
     - parameter oldPass: String with the **old password**
     - parameter newPass: String with the **new password**
     - Returns: **true** if all OK, **false** otherwise
    */
    func changeGeneralPassphrase(_ oldPass : String , newPass : String) -> Bool{
        
        if identify(oldPass){
            
            do{
                let newKey = try encryptRSAKey(self.privateKey!, passphrase: newPass)
                try CryptoManager.saveString(newKey, into: ".private", withExtension: "enc", dir: AppDelegate.applicationSupportDirectory())
                return true
            }catch {
                
            }
        }
        return false
    }
    
    /**
     Encrypts a String with a public key
     
     - parameter src: String with the clear text
     - parameter publicKeyPEM:  String with the public key in PEM format
     - Returns: The encrypted string in base64 encoding
     
    */
    func encrypt(_ src : String, publicKeyPEM: String) throws  -> String{
        
        // Need all data
        
        
        let dades = src.utf8.map{$0}
        
        // Generate keys
        
        let myIV = AES.randomIV(AES.blockSize)  // create random IV (16 bytes9)
        let kKey = AES.randomIV(32)             // create AES256 random key
        
        
        // First encrypt message with AES256 and the key and iv generated
        
        let encrypted: [UInt8] = try AES(key: kKey, iv: myIV, blockMode: .CBC, padding: .pkcs7).encrypt(dades)
        
        // Now we concatenate iv (16 bytes) with kKey (32 bytes)
        
        let secret = myIV + kKey
        let secretData = Data(bytes: secret)
        
        // encrypt secretData with public key
        
        let clear = ClearMessage(data: secretData)
        let publicKey = try PublicKey(pemEncoded: publicKeyPEM)
        let encSecret = try clear.encrypted(with: publicKey, padding:.PKCS1)
        
        // Concatenate everything with first 2 bytes showing length of encrypted
        // IV + AES key
        let l = encSecret.data.count
        
        let l1 : UInt8 = UInt8(l / 256)
        let l0 : UInt8 = UInt8(l % 256)
        
        let allData : [UInt8] = [l1, l0] + encSecret.data.bytes + encrypted
        
        // Convert to base64
        
        let allNSData = Data(bytes: allData)
        
        let base64 = allNSData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)
        
        return base64
    }
    
    /// Decrypts with the private key. Needs to be identified to be able to use the private key which should be decrypted and stored in the local variable
    /// - parameter base64: A base64 encoded String with the encrypted text
    /// - Returns: A String with the clear data
    /// - throws: if there is a decription or decoding error
    func decrypt(_ base64 : String) throws -> String{
        
        if isNotIdentified(){
            throw CryptoManagerError.locked
        }
        
        // First we get the message and convert from base64 to UInt8
        
        guard let decodedData = Data(base64Encoded: base64, options: [NSData.Base64DecodingOptions.ignoreUnknownCharacters]) else {
            throw CryptoManagerError.base64DecodingError
        }
        
        // OK Fem un print del decodedData
        
        // NSLog("Input Message : %@", decodedData);
        
        let bytes = decodedData.bytes
        
        if bytes.count < 2{
             throw CryptoManagerError.base64DecodingError
        }
        
        
        // First two bytes is length of encrypted IV + AES Key
        
        let len = (Int( bytes[0]) * 256 ) + Int(bytes[1])
        
        if bytes.count < len+2{
            throw CryptoManagerError.base64DecodingError
        }
        
        let encSecret : [UInt8] = Array(bytes[2..<len+2])
        
        // Decrypt encSecret with private key (must be unlocked, of course)
        
        do{
            let encryptedSecretMessage = EncryptedMessage(data: Data(bytes: encSecret))
            let pkey = try PrivateKey(pemEncoded: privateKey!)
            let clearSecretMessage = try encryptedSecretMessage.decrypted(with: pkey, padding: .PKCS1)
            let secret = clearSecretMessage.data.bytes
            
            // Now bytes 0-15 is the IV, 16-47 are the key and the rest is the message
            
            let iv : [UInt8] = Array(secret[0..<16])
            let key : [UInt8] = Array(secret[16..<48])
            let encMsg  = Data(bytes:Array(bytes[len+2..<bytes.count]))
            
            // OK now we may decrypt the message
            
            let msg = try  encMsg.decrypt(cipher: AES(key: key, iv: iv))
            
            if let clearMsg = String(data: msg, encoding: String.Encoding.utf8){
                return clearMsg
            }
        }catch{
            
        }
        
        throw CryptoManagerError.utf8Encoding
        
    }
    
    //TODO: Modify the salt although is not very important as we use only one key and don't store it

    /// Generate a key for AES from a string
    /// I see that iterations are quite long. That mades identification longer
    /// which usually is a good idea.
    ///
    /// - parameter str: The password string
    /// - Returns: the key
    func AESKeyFromString(_ str : String) -> [UInt8]{
        
        let salt: [UInt8] = "nacl".utf8.map {$0}
        
        let key = try! PKCS5.PBKDF2(password: str.utf8.map {$0}, salt: salt, iterations: 4096, variant: .sha256).calculate()
        
        return key
    }
    
    /// Encrypts a  string with the public key. Just RSA
    ///
    /// - parameter str: The String to be encrypted
    /// - Returns: The base64 encrypted String
    /// - Throws: Any encryption or encoding error
    func encryptLocalString(_ str : String) throws -> String{
        if let pk = self.publicKey{
            do{
                let clearMessage = try ClearMessage(string: str, using: String.Encoding.utf8)
                let key = try PublicKey(pemEncoded: pk)
                let encryptedMessage = try clearMessage.encrypted(with: key, padding: .PKCS1)
                let encData = encryptedMessage.data
                
                //let encData = try SwiftyRSA.encryptData(str.dataUsingEncoding(String.Encoding.utf8)!, publicKeyPEM: pk, padding: .PKCS1)
                let encStr = encData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)
                return encStr
            }catch{
                
            }
        }
        throw  CipherError.encrypt
        
    }

    /// Decrypts a  string with the private key. Just RSA
    ///
    /// - parameter str: The encrypted String in base64 format
    /// - Returns: The clear String
    /// - Throws: Any encryption or encoding error

    func decryptLocalString(_ str : String) throws -> String{
        if let pk = self.privateKey{
            do {
                guard let decodedData = Data(base64Encoded: str, options: [NSData.Base64DecodingOptions.ignoreUnknownCharacters]) else {
                    throw CryptoManagerError.base64DecodingError
                }
                let encryptedMessage = EncryptedMessage(data: decodedData)
                let key = try PrivateKey(pemEncoded: pk)
                let clearMessage = try encryptedMessage.decrypted(with: key, padding: .PKCS1)
                let aux = try clearMessage.string(encoding: .utf8)
                return aux
            }catch{
                
            }
        }
        
        throw  CipherError.decrypt
    }
    
    
    /// Encrypts a string with AES
    /// The IV is put in front of the encoded key
    /// and everything is encoded Base64
    /// - parameter key : String with the private key in PEM format
    /// - parameter passphrase : String with the passphrase
    /// - returns : The encrypted key in base64 format
    /// - throws: Encryption or decoding errors
    func encryptRSAKey(_ key : String, passphrase : String) throws -> String {
        
        // Get AES key
        
        let aesKey = AESKeyFromString(passphrase)
        let iv = AES.randomIV(AES.blockSize)
        //let keyData = key.data(using: .utf8)
        let encryptedKey = try Array(key.utf8).encrypt(cipher: AES(key: aesKey, iv: iv))
        
        //let encryptedKey = try key.encrypt(cipher: AES(key: aesKey, iv: iv))
        
        // OK now we create a new array of UInt8
        
        let binKey = iv + encryptedKey
        // Now we encode it with Base64
        
        let str = Data(bytes: binKey).base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)
        
        return str
        
    }
    
    /// Expects a base64 encrypted key and the passphrase
    /// Decodes from Base64 and extracts the IV from the beginning
    /// Then decrypts the rest with the key + IV
    /// All keys are pem format
    /// - parameter encryptedBase64Key: String with the key encrypted ib Base64 format
    /// - parameter passphrase : The passphrase used to encrypt the key
    /// - returns: The .pem format decrypted key
    /// - throws: Decryptyon er decoding errors
    
    func decryptRSAKey(_ encryptedBase64Key : String, passphrase : String) throws -> String {
        
        
        // Convert passphrase to AES key
        
        let aesKey = AESKeyFromString(passphrase)
        
        // Decode from base64
        
        guard let decodedData = Data(base64Encoded: encryptedBase64Key, options: [NSData.Base64DecodingOptions.ignoreUnknownCharacters]) else {
            throw CipherError.decrypt
        }
        
        // Convert to byte array
        
        let binKey = decodedData.bytes
        
        // Extract iv
        
        let iv = Array(binKey[0..<AES.blockSize])
        let encryptedKey = Array(binKey[AES.blockSize..<binKey.count])
        
        let decrypted = try AES(key: aesKey, iv: iv).decrypt(encryptedKey)
        
        let decryptedData = Data(bytes: decrypted)
        let decryptedKey = String(data: decryptedData, encoding: String.Encoding.utf8)
        
        if let dc = decryptedKey {
            
            return dc
        }
        
        throw CipherError.decrypt
    }
    
    /// rsrcStringNamed returns a String from a resource in main bundle.
    ///
    /// - Parameter name : The name of the resource
    /// - Parameter withExtension: The extension
    /// - returns: the contents of the resource
    class func rsrcStringNamed(_ name : String, withExtension : String) -> String?{
        if let url = Bundle.main.url(forResource: name, withExtension: withExtension){
            do {
                let s = try String(contentsOf: url)
                return s
            }catch  {
                return nil
            }
        }
        return nil
    }
    
    
    /// Reads a resource from main bundles, parses the lines and returns it as an String Array
    ///
    /// - Parameter name : The name of the resource
    /// - Parameter withExtension: The extension
    /// - returns: A String array with one element for each line
    class func rsrcArrayNamed(_ name : String, withExtension : String) -> [String]?{
        
        if let string = rsrcStringNamed(name, withExtension: withExtension){
            
            var arr = [String]()
            
            string.enumerateLines(invoking: { (line, stop) in
                arr.append(line)
            })
            
            return arr
            
        }
        return nil
        
    }

    
    /// Returns the contents of a file from the Documents directory
    /// - Parameter name : The name of the file
    /// - Parameter withExtension: The extension of the file
    /// - returns: the contents of the file
    
    class func stringNamed(_ name : String, withExtension : String, dir: URL) -> String?{
        
        let docs = dir
        
        let url = docs.appendingPathComponent(name).appendingPathExtension(withExtension)
        do {
            let s = try String(contentsOf: url, encoding: String.Encoding.utf8)
            return s
        }catch  let error as NSError{
            
            AppDelegate.showErrorMessage(error.localizedDescription)
            return nil
        }catch {
            return nil
        }
        
    }
    
    /// writes a String into a file in the Documents directory
    /// - Parameter string : The String to write
    /// - Parameter name : The name of the file
    /// - Parameter withExtension: The extension of the fie
    ///
    
    class func saveString(_ string: String, into name: String, withExtension: String, dir: URL) throws{
        
        let docs = dir
        
        var url = docs.appendingPathComponent(name).appendingPathExtension(withExtension)
        try string.write(to: url, atomically: true, encoding: String.Encoding.utf8)
        
        var rsrcs = URLResourceValues()
        rsrcs.isHidden = name.hasPrefix(".")
        rsrcs.isExcludedFromBackup = (withExtension == "enc")
        try url.setResourceValues(rsrcs)
        
    }
    
    /// Returns the contents of a file from the Documents directory
    /// - Parameter name : The name of the file
    /// - Parameter withExtension: The extension of the file
    /// - returns: the contents of the file

    class func stringNamed(_ name : String,  withExtension ext: String) -> String?{
        
        return stringNamed(name, withExtension: ext, dir: AppDelegate.applicationDocumentsDirectory())
        /*
        let docs = AppDelegate.applicationDocumentsDirectory()
        
        let url = docs.appendingPathComponent(name).appendingPathExtension(withExtension)
        do {
            let s = try String(contentsOf: url, encoding: String.Encoding.utf8)
            return s
        }catch  let error as NSError{
            
            AppDelegate.showErrorMessage(error.localizedDescription)
            return nil
        }catch {
            return nil
        }
         */
        
    }

    /// writes a String into a file in the Documents directory
    /// - Parameter string : The String to write
    /// - Parameter name : The name of the file
    /// - Parameter withExtension: The extension of the fie
    ///

    class func saveString(_ string: String, into name: String, withExtension ext: String) throws{
        
        try saveString(string, into: name, withExtension: ext, dir: AppDelegate.applicationDocumentsDirectory())
        
        /*
        let docs = AppDelegate.applicationDocumentsDirectory()
        
        var url = docs.appendingPathComponent(name).appendingPathExtension(withExtension)
        try string.write(to: url, atomically: true, encoding: String.Encoding.utf8)
        
        var rsrcs = URLResourceValues()
        rsrcs.isHidden = name.hasPrefix(".")
        rsrcs.isExcludedFromBackup = (withExtension == "enc")
         try url.setResourceValues(rsrcs)
         */
        
    }
    
    
    /// Reads a file from Documents dyrectory, parses the lines and returns it as an String Array
    ///
    /// - Parameter name : The name of the file
    /// - Parameter withExtension: The extension of the rile
    /// - returns: A String array with one element for each line

    class func arrayNamed(_ name : String, withExtension : String) -> [String]?{
        
        if let string = stringNamed(name, withExtension: withExtension){
            
            var arr = [String]()
            
            string.enumerateLines(invoking: { (line, stop) in
                arr.append(line)
            })
            
            return arr
            
        }
        return nil
        
    }
    
    /// Exports keys as .enc files to the Document directory
    ///
    /// Keys are exported encrypted with the current passphrase.
    
    func exportKeys(){
        if privateKey != nil{
            do{
                let fm = FileManager.default
                let docs = AppDelegate.applicationDocumentsDirectory()
                let publicUrl = docs.appendingPathComponent(".public").appendingPathExtension("enc")
                let newPublicUrl = docs.appendingPathComponent("public").appendingPathExtension("enc")
                try fm.copyItem(at: publicUrl, to: newPublicUrl)
           
                let privateUrl = docs.appendingPathComponent(".private").appendingPathExtension("enc")
                let newPrivateUrl = docs.appendingPathComponent("private").appendingPathExtension("enc")
                try fm.copyItem(at: privateUrl, to: newPrivateUrl)
            } catch{}
            
        }
    }
    
    /// Moves .public.enc and .private.enc in Documents Directory to Application Support Directory
    ///
    ///
    
    func moveKeys(){
            do{
                let fm = FileManager.default
                let docs = AppDelegate.applicationDocumentsDirectory()
                let lib = AppDelegate.applicationSupportDirectory()
                
                let publicUrl = docs.appendingPathComponent(".public").appendingPathExtension("enc")
                var newPublicUrl = lib.appendingPathComponent(".public").appendingPathExtension("enc")
                try fm.moveItem(at: publicUrl, to: newPublicUrl)
                
                let privateUrl = docs.appendingPathComponent(".private").appendingPathExtension("enc")
                var newPrivateUrl = lib.appendingPathComponent("private").appendingPathExtension("enc")
                try fm.moveItem(at: privateUrl, to: newPrivateUrl)
                
                var rsrcs = URLResourceValues()
                rsrcs.isHidden = true
                rsrcs.isExcludedFromBackup = true
                try newPublicUrl.setResourceValues(rsrcs)
                try newPrivateUrl.setResourceValues(rsrcs)

            } catch{
                
                NSLog("Error when moving")
            }
            
 
    }


    /// We are PANICKING. Some unwanted authority wants to get access to our files
    /// ... Or we are getting Alzheimer and forgetting the password.
    ///
    /// So just clear the keys and block everything.
    ///
    /// That means that for securtity we must store a copy of the keys
    /// in some secure place. An interesting possibility is to save them and
    /// send them to a remote not accesible place.
    ///
    /// The idea is that WE ARE NOT ABLE to recover the KEYS unless all is proved OK
    ///
    /// Keys are exported encrypted with the current passphrase.

    func resetAll() throws{
        
        self.privateKey = nil
        self.publicKey = nil
        
        // Remove normal keys
        
        let docsURL = AppDelegate.applicationDocumentsDirectory()
        let privateUrl = docsURL.appendingPathComponent(".private.enc")
        let publicUrl = docsURL.appendingPathComponent(".public.enc")
        
        
        let mgr = FileManager.default
        do{ try mgr.removeItem(at: privateUrl); } catch {}
        do{ try mgr.removeItem(at: publicUrl); } catch {}

        
        
    }
    
    ///This routine returns the UInt8 array in binhex
    ///
    /// Parameter input: UInt8 array
    /// Returns: A String with the binhex data
    
    class func toBinHex(_ input : [UInt8]) -> String{
        let data = Data(bytes: input)
        return data.description
    }
}

