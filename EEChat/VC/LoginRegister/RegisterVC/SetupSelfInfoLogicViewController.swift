//
//  SetupSelfInfoLogicViewController.swift
//  EEChat
//
//  Created by xpg on 2021/12/7.
//

import UIKit
import Foundation
import OpenIMSDKiOS
import Kingfisher
import RxSwift
import Alamofire
import web3swift
import SwiftUI

class SetupSelfInfoLogicViewController: BaseViewController {
    
    var icon = ""

    var code:String = ""
    var phone:String = ""
    var password:String = ""
    
    @IBOutlet var avatarBtn:UIButton!
    @IBOutlet var nameTextField:UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        avatarBtn.layer.cornerRadius = 45
        avatarBtn.layer.masksToBounds = true
        // Do any additional setup after loading the view.
    }
    
    struct DecodableType: Decodable { let url: String }
    
    @IBAction func changeAvatarAction() {
        PhotoModule.shared.showPicker(allowTake: true,
                                       allowCrop: true,
                                       cropSize: CGSize(width: 200, height: 200))
        { [unowned self] (image, asset) in
            avatarBtn.setImage(image, for: UIControl.State.normal)
            let imgData = image.pngData()!
            let key = String(Date().timeIntervalSince1970)+"_11.png"
            AF.upload(multipartFormData: { multipartFormData in
                multipartFormData.append(Data(key.utf8), withName: "Key")
                multipartFormData.append(Data("200".utf8), withName: "success_action_status")
                multipartFormData.append(Data("Signature".utf8), withName: "Signature")
                multipartFormData.append(Data("token".utf8), withName: "x-cos-security-token")
                multipartFormData.append(imgData, withName: "file",fileName: "11.png",mimeType: "image/png")
                print("upload success result: "+" "+"https://echat-1302656840.cos.ap-chengdu.myqcloud.com/"+key)
                
                icon = "https://echat-1302656840.cos.ap-chengdu.myqcloud.com/"+key
                
            }, to: "https://echat-1302656840.cos.ap-chengdu.myqcloud.com/",method: .post)
                .responseDecodable(of: DecodableType.self) { response in
                    debugPrint(response)
                }
        }
    }
    
    func adminOperate() {
        struct Param: Encodable {
            var secret = "tuoyun"
            var platform = 1
            var uid = "openIM123456"
        }
        let param = Param()
        var api = ApiInfo(path: "auth/user_token")
        let newServer = UserDefaults.standard.string(forKey: "serverip") ?? "47.112.160.66"
        api.baseURL = URL(string: "http://"+newServer+":10000/")!
        ApiModule.shared.request(api, parameters: param, showLoading: true, showError: true).subscribe { [self] response in
            let data = response.getDict();
            
            adminOperate1(uid: phone,token: data["token"] as! String)
            
        } onFailure: { error in
            
        } onDisposed: {
            
        }
    }
    
    func adminOperate1(uid:String,token:String) {
        struct Param: Encodable {
            var groupID = "082cad15fd27a2b6b875370e053ccd79"
            var uidList:[String] = []
            var reason = "Welcome join openim group"
            var operationID = "1111111111111"
        }
        var param = Param()
        param.uidList = [uid]
        var api = ApiInfo(path: "group/invite_user_to_group")
        api.headers = ["token":token]
        let newServer = UserDefaults.standard.string(forKey: "serverip") ?? "47.112.160.66"
        api.baseURL = URL(string: "http://"+newServer+":10000/")!
        ApiModule.shared.request(api, parameters: param, showLoading: true, showError: true).subscribe { response in
            //let data = response.getDict();
        } onFailure: { error in
            
        } onDisposed: {
            
        }
    }
    
    @IBAction func join() {
        if (icon.isEmpty) {
                MessageModule.showMessage("请上传头像")
              return;
        }
        if (nameTextField?.text?.isEmpty != false) {
                MessageModule.showMessage("名字不能为空")
              return;
        }
        adminOperate()
        struct Param: Encodable {
            var phoneNumber = ""
            var areaCode = "86"
            var verificationCode = ""
            var password = ""
        }
        var param = Param()
        param.phoneNumber = phone
        param.verificationCode = code
        param.password = password.md5()
        let name = nameTextField.text
        ApiModule.shared.request(ApiInfo(path: "auth/password"), parameters: param, showLoading: true, showError: true).subscribe { [self] response in
            let data = response.getDict();
            JPUSHService.setAlias(phone, completion: { code, msg, err in
                
            }, seq: 0)
            OpenIMiOSSDK.shared().login(data["uid"] as! String, token: data["token"] as! String) { [self] msg in
                OpenIMiOSSDK.shared().setSelfInfo(name, icon: icon, gender: nil, mobile: phone, birth: nil, email: nil) { msg in
                
                    var m = ApiUserLogin.Model()
                    m.userInfo = UserInfo1()
                    m.userInfo.uid = data["uid"] as? String
                    m.userInfo.name = name
                    m.userInfo.icon = icon
                    m.token = ApiUserLogin.ToeknModel()
                    m.token.accessToken = data["token"] as! String
                    DispatchQueue.main.async {
                        AccountManager.shared.login(model: m)
                    }
                    
                } onError: { code, msg in
                    
                }

            } onError: { code, msg in
                
            }

//            {
//              "errCode" : 0,
//              "data" : {
//                "token" : "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJVSUQiOiIxMjM0NTY3ODkwMCIsIlBsYXRmb3JtIjoiTGludXgiLCJleHAiOjE2Mzk0NzczNjEsIm5iZiI6MTYzODg3MjU2MSwiaWF0IjoxNjM4ODcyNTYxfQ.0QO3RD-hUsxl_3NybbnBiel-Vply16wE6uXqEEfrWp8",
//                "uid" : "12345678900",
//                "expiredTime" : 1639477361
//              },
//              "errMsg" : ""
//            }
        } onFailure: { error in
            
        } onDisposed: {
            
        }
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
