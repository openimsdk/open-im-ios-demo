//
//  LoginVC.swift
//  EEChat
//
//  Created by Snow on 2021/4/8.
//

import UIKit
//import OpenIM
import web3swift


private var __maxLengths = [UITextField: Int]()
extension UITextField {
    @IBInspectable var maxLength: Int {
        get {
            guard let l = __maxLengths[self] else {
                return 150 // (global default-limit. or just, Int.max)
            }
            return l
        }
        set {
            __maxLengths[self] = newValue
            addTarget(self, action: #selector(fix), for: .editingChanged)
        }
    }
    @objc func fix(textField: UITextField) {
        if let t = textField.text {
            textField.text = String(t.prefix(maxLength))
        }
    }
}

class LoginVC: BaseViewController {
    static let cacheKey = "LoginVC.cacheKey"
    
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    @IBOutlet weak var welcomeLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
//        textField.text = DBModule.shared.get(key: LoginVC.cacheKey)
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        welcomeLabel.addGestureRecognizer(tap)
    }
    
    @objc func doubleTapped() {
        performSegue(withIdentifier: "sip", sender: nil)
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
    
    @IBAction func doubleTapAction() {
        RegisterVC.show()
    }
}
