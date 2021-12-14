//
//  SwitchIPViewController.swift
//  EEChat
//
//  Created by xpg on 2021/12/13.
//

import UIKit
import OpenIMUI

class SwitchIPViewController: UIViewController {
    
    @IBOutlet weak var server: UITextField!
    @IBOutlet weak var loginReg: UITextField!
    @IBOutlet weak var imApi: UITextField!
    @IBOutlet weak var imWS: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let newServer = UserDefaults.standard.string(forKey: "serverip") ?? "47.112.160.66"
        
        server.text = newServer
        loginReg.text = "http://" + newServer + ":42233"
        imApi.text = "http://" + newServer + ":1000"
        imWS.text = "ws://" + newServer + ":17778"
        
        server.addTarget(self, action: #selector(SwitchIPViewController.textFieldDidChange(_:)), for: .editingChanged)

        // Do any additional setup after loading the view.
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        let newServer = textField.text ?? "47.112.160.66"
        
        server.text = newServer
        loginReg.text = "http://" + newServer + ":42233"
        imApi.text = "http://" + newServer + ":1000"
        imWS.text = "ws://" + newServer + ":17778"
    }
    
    @IBAction func save() {
        if(server.text?.isEmpty == true) {
            MessageModule.showMessage("服务器地址不能为空")
            return
        }
        UserDefaults.standard.set(server.text, forKey: "serverip")
        OUIKit.shared.initSDK()
        MessageModule.showMessage("保存成功")
        navigationController?.popViewController(animated: true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
