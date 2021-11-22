//
//  GroupMemberVC.swift
//  EEChat
//
//  Created by Snow on 2021/7/7.
//

import UIKit
import OpenIMSDKiOS

class GroupMemberVC: BaseViewController {
    
    override class func show(param: Any? = nil, callback: BaseViewController.Callback? = nil) {
        assert(param is String)
        let groupID = param as! String
//        _ = rxRequest(showLoading: true,
//                      action: { OIMManager.getGroupMemberList(gid: groupID,
//                                                              filter: .all,
//                                                              next: 0,
//                                                              callback: $0) })
//            .subscribe(onSuccess: { result in
//                super.show(param: result.data, callback: callback)
//            })
        OpenIMiOSSDK.shared().getGroupMemberList(groupID, filter: 0, next: 0) { result in
            DispatchQueue.main.async {
                super.show(param: result.data, callback: callback)
            }
        } onError: { code, msg in
            
        }

    }

    @IBOutlet var memberView: GroupMemberView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        memberView.layout.sectionInset = UIEdgeInsets(top: 20, left: 22, bottom: 20, right: 22)
        memberView.layout.itemSize = CGSize(width: 42, height: 62)
        
        assert(param is [GroupMembersInfo])
        let members = param as! [GroupMembersInfo]
        memberView.members = members
    }

}
