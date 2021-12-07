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
    
    @IBAction func join() {
        if (icon.isEmpty) {
                MessageModule.showMessage("请上传头像")
              return;
            }
            if (nameTextField?.text?.isEmpty != false) {
                MessageModule.showMessage("名字不能为空")
              return;
            }
        struct Param: Encodable {
            var phoneNumber = ""
            var areaCode = "86"
            var verificationCode = ""
            var password = ""
        }
        var param = Param()
        param.phoneNumber = phone
        param.verificationCode = code
        param.password = password
        ApiModule.shared.request(ApiInfo(path: "auth/password"), parameters: param, showLoading: true, showError: true).subscribe { response in
            
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
