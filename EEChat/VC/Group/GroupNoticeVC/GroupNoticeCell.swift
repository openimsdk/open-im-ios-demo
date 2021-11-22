//
//  GroupNoticeCell.swift
//  EEChat
//
//  Created by Snow on 2021/7/9.
//

import UIKit
import OpenIMSDKiOS

class GroupNoticeCell: UITableViewCell {

    @IBOutlet var avatarImageView: ImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var msgLabel: UILabel!

    @IBOutlet var tipsLabel: UILabel!
    
    var model: GroupApplicationInfo! {
        didSet {
            refreshUI()
        }
    }
    
    private func refreshUI() {
        avatarImageView.setImage(with: model.fromUserFaceURL,
                                 placeholder: UIImage(named: "icon_default_avatar"))
        nameLabel.text = model.fromUserNickName
        msgLabel.text = model.reqMsg
        tipsLabel.superview?.isHidden = model.flag == .none
        switch model.flag {
        case 0:
            break
        case 2:
            tipsLabel.text = "Agreed"
        case 1:
            tipsLabel.text = "Refused"
        default:
            break
        }
    }
    
    @IBAction func agreeAction() {
//        _ = rxRequest(showLoading: true, action: { OIMManager.acceptGroupApplication(self.model,
//                                                                                     reason: "",
//                                                                                     callback: $0) })
//            .subscribe(onSuccess: {
//                self.model.flag = .agree
//                self.refreshUI()
//            })
        OpenIMiOSSDK.shared().acceptGroupApplication(self.model, reason: "") { msg in
            self.model.flag = 2
            self.refreshUI()
        } onError: { code, msg in
            
        }

    }
    
    @IBAction func refuseAction() {
//        _ = rxRequest(showLoading: true, action: { OIMManager.refuseGroupApplication(self.model,
//                                                                                     reason: "",
//                                                                                     callback: $0) })
//            .subscribe(onSuccess: {
//                self.model.flag = .refuse
//                self.refreshUI()
//            })
        
        OpenIMiOSSDK.shared().refuseGroupApplication(self.model, reason: "") { msg in
            DispatchQueue.main.async {
                self.model.flag = 1
                self.refreshUI()
            }
        } onError: { code, msg in
            
        }

    }

}
