//
//  LoginVC.swift
//  EEChat
//
//  Created by Snow on 2021/4/8.
//

import UIKit
//import OpenIM
import web3swift

class LoginVC: BaseViewController {
    static let cacheKey = "LoginVC.cacheKey"
    
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
//        textField.text = DBModule.shared.get(key: LoginVC.cacheKey)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    @IBOutlet var textField: UITextField!
    @IBAction func loginAction() {
        if(phoneTextField.text?.isEmpty != false) {
            MessageModule.showMessage("请输入手机号和密码")
            return
        }
        if(passwordTextField.text?.isEmpty != false) {
            MessageModule.showMessage("请输入手机号和密码")
            return
        }
        
        view.endEditing(true)
        var mnemonic = phoneTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        if mnemonic == "" {
            mnemonic = try! BIP39.generateMnemonics(bitsOfEntropy: 128)!
        }
        
        ApiUserLogin.login(mnemonic: mnemonic,phone:phoneTextField.text!,password:passwordTextField.text!)
    }
    
    @IBOutlet var agreementView: AgreementView!
    
    @IBAction func registerAction() { 
        RegisterVC.show()
    }
}
