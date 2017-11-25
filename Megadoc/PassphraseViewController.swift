//
//  PassphraseViewController.swift
//  Megadoc
//
//  Created by Francisco Gorina Vanrell on 20/11/17.
//  Copyright © 2017 Francisco Gorina. All rights reserved.
//

import UIKit

class PassphraseViewController: UIViewController {
    @IBOutlet weak var fPassField: UITextField!
    @IBOutlet weak var fAcceptButton: UIButton!
    @IBOutlet weak var fPasswordLabel: UILabel!
    
    weak var cm : CryptoManager?
    var userInfo : [String:Any]?
    var block : (([String:Any]?) -> Void)?
    
    let status = ["😀", "☹️", "😖", "😤"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let cma = cm {
            let iteration = cma.getRemainingCount()
            
            fPasswordLabel.text = status[iteration-1]
        }
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func validate(){
        
        if let pass = fPassField.text{
            fPassField.text = ""
            if let cma = cm{
                if cma.identify(pass) {
                    self.dismiss(animated: true, completion: {
                        if let b = self.block{
                            b(self.userInfo)
                        }
                    })
                } else {
                    let iteration = cma.getRemainingCount()
                    fPasswordLabel.text = status[iteration-1]
                }
            }
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
