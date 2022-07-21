//
//  CompleteUserInfoViewController.swift
//  OpenIMSDKUIKit_Example
//
//  Created by x on 2022/7/20.
//  Copyright © 2022 rentsoft. All rights reserved.
//

import Foundation
import UIKit
import AlamofireImage
import RxSwift
import SVProgressHUD

class CompleteUserInfoViewController: UIViewController {
    
    var basicInfo: Dictionary<String, String>?
    
    @IBOutlet var avatarButton: UIButton!
    @IBOutlet var nickNameTextField: UITextField!
    @IBOutlet var compeleteButton: UIButton!
    
    private var avatarURL: String = ""
    
    private let _disposeBag: DisposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        avatarButton.layer.cornerRadius = 50
        avatarButton.af_setBackgroundImage(for: .normal,
                                           url: randAvatarURL(),
                                           placeholderImage: UIImage.init(named: "ic_camera"),
                                           filter: nil,
                                           progress: nil,
                                           progressQueue: DispatchQueue.main,
                                           completion: nil)
    }
    
    func randAvatarURL() -> URL {
        avatarURL = String.init(format: "https://picsum.photos/id/%d/200/200", arc4random() % 999)
        
        return URL(string:avatarURL)!
    }
    
    @IBAction func didTapCompelete() {
        view.endEditing(true)
        
        guard let info = basicInfo,
              let nickName = nickNameTextField.text,
              !nickName.isEmpty,
              !avatarURL.isEmpty else {
            return
        }
        SVProgressHUD.show(withStatus: "注册中...")
        
        LoginViewModel.registerAccount(phone: info["phone"]!,
                                       code: info["code"]!,
                                       password: info["password"]!,
                                       faceURL: avatarURL,
                                       nickName: nickName) { errMsg in
            
            if errMsg != nil {
                SVProgressHUD.showError(withStatus: errMsg)
            } else {
                SVProgressHUD.dismiss()
                self.dismiss(animated: true)
            }
        }
    }
    
    @IBAction func didTapAvatar() {
        avatarButton.af_setBackgroundImage(for: .normal,
                                           url: randAvatarURL(),
                                           placeholderImage: UIImage.init(named: "ic_camera"),
                                           filter: nil,
                                           progress: nil,
                                           progressQueue: DispatchQueue.main,
                                           completion: nil)
    }
}
