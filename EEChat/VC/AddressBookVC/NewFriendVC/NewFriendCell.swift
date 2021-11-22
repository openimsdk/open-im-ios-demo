//
//  NewFriendCell.swift
//  EEChat
//
//  Created by Snow on 2021/4/21.
//

import UIKit
import OpenIMSDKiOS

class NewFriendCell: UITableViewCell {

    @IBOutlet var avatarImageView: ImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var addBtn: UIButton!
    
    var model: UserInfo! {
        didSet {
            refresh()
        }
    }
    
    private func refresh() {
        let userInfo = model
        avatarImageView.setImage(with: userInfo!.icon,
                                 placeholder: UIImage(named: "icon_default_avatar"))
        
        nameLabel.text = userInfo?.name
        switch model.flag {
        case 0:
            addBtn.isUserInteractionEnabled = true
            addBtn.backgroundColor = UIColor.eec.rgb(0x1B72EC)
            addBtn.setTitleColor(.white, for: .normal)
            addBtn.setTitle(LocalizedString("Add"), for: .normal)
        case 2:
            fallthrough
        case 1:
            addBtn.isUserInteractionEnabled = false
            addBtn.backgroundColor = .clear
            addBtn.setTitleColor(UIColor.eec.rgb(0x666666), for: .normal)
            if model.flag == 2 {
                addBtn.setTitle(LocalizedString("Agreed"), for: .normal)
            } else {
                addBtn.setTitle(LocalizedString("Rejected"), for: .normal)
            }
        default:
            break
        }
    }
    
    @IBAction func addAction() {
        let uid = model.uid
//        _ = rxRequest(showLoading: true, action: { OIMManager.acceptFriendApplication(uid: uid, callback: $0) })
//            .subscribe(onSuccess: { _ in
//                self.model.flag = .agree
//                self.refresh()
//            })
        OpenIMiOSSDK.shared().acceptFriendApplication(uid!) { msg in
            DispatchQueue.main.async {
                self.model.flag = 2
                self.refresh()
            }
        } onError: { code, msg in
            
        }

    }
    
}
