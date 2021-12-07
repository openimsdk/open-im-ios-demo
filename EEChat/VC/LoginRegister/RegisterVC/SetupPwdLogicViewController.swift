//
//  SetupPwdLogicViewController.swift
//  EEChat
//
//  Created by xpg on 2021/12/7.
//

import UIKit

class SetupPwdLogicViewController: UIViewController {
    
    @IBOutlet weak var pwTextField: UITextField!
    
    var code:String = ""
    var phone:String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func setPassword() {
        if (pwTextField.text!.count < 6 || pwTextField.text!.count > 20) {
            MessageModule.showMessage("密码格式不正确")
              return;
        }
        
        performSegue(withIdentifier: "selfinfo", sender: nil)
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if(segue.destination is SetupSelfInfoLogicViewController) {
            let vc = segue.destination as! SetupSelfInfoLogicViewController
            vc.phone = phone
            vc.code = code
            vc.password = pwTextField.text ?? ""
        }
    }

}
