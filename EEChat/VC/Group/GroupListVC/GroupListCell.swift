//
//  GroupListCell.swift
//  EEChat
//
//  Created by Snow on 2021/7/13.
//

import UIKit
import OpenIMSDKiOS

class GroupListCell: UITableViewCell {

    @IBOutlet var avatarImageView: ImageView!
    @IBOutlet var nameLabel: UILabel!
    
    var model: GroupInfo! {
        didSet {
            avatarImageView.setImage(with: model.faceUrl,
                                     placeholder: UIImage(named: "icon_default_avatar"))
            nameLabel.text = model.groupName
        }
    }
    
}
