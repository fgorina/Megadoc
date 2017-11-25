//
//  ChangePasswordViewController.swift
//  Megadoc
//
//  Created by Francisco Gorina Vanrell on 22/11/17.
//  Copyright © 2017 Francisco Gorina. All rights reserved.
//

import UIKit

class ChangePasswordViewController: UIViewController {

    @IBOutlet weak var fOldPassword: UITextField!
    @IBOutlet weak var fNewPassword: UITextField!
    @IBOutlet weak var fOtherNewPassword: UITextField!
    
    weak var cm : CryptoManager?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func update(){
        
        let oldPassword = fOldPassword.text!
        let newPassword = fNewPassword.text!
        let otherPassword = fOtherNewPassword.text!
        
        if otherPassword != newPassword{
            AppDelegate.showErrorMessage("Els dos nous passwords no coincideixen")
            return
        }

        if let cma = cm {

            if cma.changeGeneralPassphrase(oldPassword, newPass: newPassword){
                self.dismiss(animated: true, completion: {
                    AppDelegate.showErrorMessage("Password modificat")
                })
            } else {
                self.dismiss(animated: true, completion: {
                    AppDelegate.showErrorMessage("Error al modificar password")
                })
            }
        }
        
        
    }
    
    @IBAction func close(){
        
        self.dismiss(animated: true) {
            
        }
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
