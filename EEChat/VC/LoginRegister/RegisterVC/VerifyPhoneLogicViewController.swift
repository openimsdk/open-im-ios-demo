//
//  VerifyPhoneLogicViewController.swift
//  EEChat
//
//  Created by xpg on 2021/12/7.
//

import UIKit

class VerifyPhoneLogicViewController: UIViewController {
    
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var codeTextField: UITextField!
    
    var phone:String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        phoneLabel.text = "+86 "+phone;
        
        struct Param: Encodable {
            var phoneNumber = ""
            var areaCode = "86"
        }
        var param = Param()
        param.phoneNumber = phone
        ApiModule.shared.request(ApiInfo(path: "auth/code"), parameters: param, showLoading: true, showError: true).subscribe { response in
            
        } onFailure: { error in
            
        } onDisposed: {
            
        }

        // Do any additional setup after loading the view.
    }
    
    @IBAction func check() {
        if(codeTextField.text?.isEmpty != false) {
            MessageModule.showMessage("请输入验证码")
            return
        }
        
        struct Param: Encodable {
            var phoneNumber = ""
            var areaCode = "86"
            var verificationCode = ""
        }
        var param = Param()
        param.phoneNumber = phone
        param.verificationCode = codeTextField.text ?? ""
        ApiModule.shared.request(ApiInfo(path: "auth/verify"), parameters: param, showLoading: true, showError: true).subscribe { response in
            self.performSegue(withIdentifier: "pw", sender: nil)
        } onFailure: { error in
            
        } onDisposed: {
            
        }
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if(segue.destination is SetupPwdLogicViewController) {
            let vc = segue.destination as! SetupPwdLogicViewController
            vc.phone = phone
            vc.code = codeTextField.text ?? ""
        }
    }
    

}
