//
//  LockController.swift
//  SuperDoc
//
//  Created by Francisco Gorina Vanrell on 31/5/16.
//  Copyright © 2016 Docs. All rights reserved.
//

import UIKit
import LocalAuthentication

class LockController: UIViewController {

    
    var context = LAContext()
    var cm : CryptoManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1
        

        touchIDLoginAction()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func closeAll(_ src : AnyObject){
        
        dismiss(animated: true) { 
            
            
        }
    }
    
    func touchIDLoginAction() {
        
        if let cmb = cm {
        // 1.
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error:nil) {
            
            // 2.
            context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: "Unlock with Touch ID",
                                   reply: { (success : Bool, error : Error? ) -> Void in
                                    
                                    // 3.
                                    DispatchQueue.main.async(execute: {
                                        if success {
                                            cmb.fingerTries = 0
                                            cmb.updateLock()
                                            self.dismiss(animated: true
                                                , completion: {
                                                
                                                    
                                            })
                                            return
                                        } else {
                                            
                                            if error != nil {
                                                
                                                
                                                // 4.
                                                switch(error!) {
                                                case LAError.authenticationFailed:

                                                    cmb.fingerTries += 1
                                                    
                                                    if cmb.fingerTries > 3{
                                                        cmb.fingerTries = 0
                                                        cmb.unidentify()
                                                        self.dismiss(animated: true, completion: nil)
                                                    }else {
                                                        self.dismiss(animated: true, completion: {() in cmb.unidentify()})
                                                    }
                                                    
                                                case LAError.userCancel:
                                                    self.dismiss(animated: true, completion: {() in cmb.unidentify()})

                                                case LAError.Code.userFallback:
                                                    
                                                    self.dismiss(animated: true, completion: {() in cmb.unidentify()})
                                                    
                                                default:
                                                    self.dismiss(animated: true, completion: {() in cmb.unidentify()})
                                                }
                                             }
                                        }
                                    })
                                    
            })
        } else {
            // 5.
            self.dismiss(animated: true, completion: {() in cmb.unidentify()})
        }
        }
        
    }
    


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
