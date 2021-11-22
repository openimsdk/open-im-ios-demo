//
//  LocalSearchUserCell.swift
//  EEChat
//
//  Created by Snow on 2021/4/23.
//

import UIKit
import OpenIMSDKiOS
import OpenIMUI

class LocalSearchUserCell: UITableViewCell {

    @IBOutlet var avatarView: ImageView!
    @IBOutlet var nameLabel: UILabel!
    
    var model: Any! {
        didSet {
            func config(user: UserInfo?) {
                if let user = user {
                    nameLabel.text = user.name
                    avatarView.setImage(with: user.icon,
                                        placeholder: UIImage(named: "icon_default_avatar"))
                }
            }
            switch model {
            case let model as UserInfo:
                config(user: model)
            case let model as ConversationInfo:
                nameLabel.text = model.showName
                avatarView.setImage(with: model.faceUrl,
                                    placeholder: UIImage(named: "icon_default_avatar"))
            default:
                break
            }
        }
    }
    
}
