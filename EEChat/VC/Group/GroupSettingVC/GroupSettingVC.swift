//
//  GroupSettingVC.swift
//  EEChat
//
//  Created by Snow on 2021/7/7.
//

import UIKit
import RxSwift
import OpenIMSDKiOS
import OpenIMUI

class GroupSettingVC: BaseViewController {
    
    override class func show(param: Any? = nil, callback: BaseViewController.Callback? = nil) {
        assert(param is ConversationInfo)
        let conversation = param as! ConversationInfo
        var members: [GroupMembersInfo] = []
//        _ = rxRequest(showLoading: true, action: { OIMManager.getGroupMemberList(gid: conversation.groupID,
//                                                                                   filter: .all,
//                                                                                   next: 0,
//                                                                                   callback: $0) })
//            .do(onSuccess: { memberResult in
//                members = memberResult.data
//            })
//            .flatMap({ _ -> Single<[OIMGroupInfo]> in
//                return rxRequest(showLoading: true,
//                                 action: { OIMManager.getGroupsInfo(gids: [conversation.groupID], callback: $0) })
//            })
//            .subscribe(onSuccess: { array in
//                if let groupInfo = array.first {
//                    super.show(param: (conversation, groupInfo, members), callback: callback)
//                }
//            })
        OpenIMiOSSDK.shared().getGroupMemberList(conversation.groupID!, filter: 0, next: 0) { memberResult in
            members = memberResult.data!
            OpenIMiOSSDK.shared().getGroupsInfo([conversation.groupID!]) { array in
                if let groupInfo = array.first {
                    DispatchQueue.main.async {
                        super.show(param: (conversation, groupInfo, members), callback: callback)
                    }
                }
            } onError: { code, msg in
                
            }

        } onError: { code, msg in
            
        }

    }
    
    private var conversation: ConversationInfo!
    private var groupInfo: GroupInfo! {
        didSet {
            refreshUI()
        }
    }
    private var members: [GroupMembersInfo] = [] {
        didSet {
            memberView.members = members.count <= 5 ? members : Array(members[0..<5])
        }
    }

    @IBOutlet var avatarImageView: ImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var detailLabel: UILabel!
    
    @IBOutlet var memberView: GroupMemberView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindAction()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.request()
    }
    
    private func bindAction() {
        assert(param is (ConversationInfo, GroupInfo, [GroupMembersInfo]))
        (conversation, groupInfo, members) = param as! (ConversationInfo, GroupInfo, [GroupMembersInfo])
        
        memberView.layout.itemSize = CGSize(width: 34, height: 54)
        
    }
    
    private func request() {
//        OIMManager.getGroupMemberList(gid: conversation.groupID,
//                                      filter: .all,
//                                      next: 0) { [weak self] result in
//            guard let self = self else { return }
//            if case .success(let result) = result {
//                self.members = result.data
//            }
//        }
        OpenIMiOSSDK.shared().getGroupMemberList(conversation.groupID!, filter: 0, next: 0) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.members = result.data!
            }
        } onError: { code, msg in
            
        }

    }
    
    private func refreshUI() {
        avatarImageView.setImage(with: groupInfo.faceUrl,
                                 placeholder: UIImage(named: "icon_default_avatar"))
        nameLabel.text = groupInfo.groupName
        detailLabel.text = groupInfo.introduction
        
        pinBtn.isSelected = (conversation.isPinned != 0)
    }
    
    @IBAction func profileAction() {
        let groupID = groupInfo.groupID
        checkPermissions()
            .subscribe(onSuccess: { [weak self] member in
                GroupProfileVC.show(param: groupID) { any in
                    self?.groupInfo = (any as! GroupInfo)
                }
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func memberListAction() {
        GroupMemberVC.show(param: groupInfo.groupID) { [weak self] any in
            let members = any as! [GroupMembersInfo]
            self?.members = members
        }
    }
    
    private func checkPermissions(_ roles: [Int32] = [], tips: String = "") -> Single<GroupMembersInfo> {
        let groupID = conversation.groupID
        let uid = OpenIMiOSSDK.shared().getLoginUid()
        return Single<GroupMembersInfo>.create { single in
            OpenIMiOSSDK.shared().getGroupMembersInfo(groupID!, uidList: [uid]) { members in
                DispatchQueue.main.async {
                    if let member = members.first {
                        if roles.isEmpty || roles.contains(member.role) {
                            single(.success(member))
                        }else{
                            MessageModule.showMessage(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: tips]))
                        }
                    }else{
                        MessageModule.showMessage(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "You're not in the group."]))
                    }
                }
            } onError: { code, msg in
                //MessageModule.showMessage(NSError(domain: "", code: 0, userInfo: nil))
                single(.failure(NSError(domain: "", code: 0, userInfo: nil)));
            }
            
            return Disposables.create {  }

        }
//        return rxRequest(showLoading: true, action: { OIMManager.getGroupMembersInfo(gid: groupID,
//                                                                                uids: [uid],
//                                                                                callback: $0) })
//            .flatMap({ members -> Single<OIMGroupMember> in
//                if let member = members.first {
//                    if roles.isEmpty || roles.contains(member.role) {
//                        return .just(member)
//                    }
//                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: tips])
//                }
//                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "You're not in the group."])
//            })
//            .do(onError: { error in
//                MessageModule.showMessage(error)
//            })
    }
    
    
    @IBAction func announcementAction() {
        let groupID = conversation.groupID
        checkPermissions([1, 2], tips: "You're not an administrator.")
            .flatMap({ _ -> Single<GroupInfo> in
//                return rxRequest(showLoading: true, action: { OIMManager.getGroupsInfo(gids: [groupID],
//                                                                                         callback: $0) })
//                    .map { array -> OIMGroupInfo in
//                        return array[0]
//                    }
                return Single<GroupInfo>.create { single in
                    OpenIMiOSSDK.shared().getGroupsInfo([groupID!]) { array in
                        single(.success(array[0]))
                    } onError: { code, msg in
                        
                    }
                    
                    return Disposables.create()

                }
            })
            .subscribe(onSuccess: { [weak self] groupInfo in
                UIAlertController.show(title: "Modify group announcement?",
                                       message: nil,
                                       text: groupInfo.introduction,
                                       placeholder: "")
                { text in
                    guard let self = self else { return }
//                    let param = OIMGroupInfoParam(groupInfo: groupInfo,
//                                                  notification: text)
//                    rxRequest(showLoading: true, action: { OIMManager.setGroupInfo(param, callback: $0) })
//                        .subscribe(onSuccess: {
//                            MessageModule.showMessage("Modify the announcement successfully.")
//                        })
//                        .disposed(by: self.disposeBag)
                    OpenIMiOSSDK.shared().setGroupInfo(groupInfo.groupID!, groupName: groupInfo.groupName!, notification: text, introduction: groupInfo.introduction!, faceUrl: groupInfo.faceUrl!) { msg in
                        DispatchQueue.main.async {
                            MessageModule.showMessage("Modify the announcement successfully.")
                        }
                    } onError: { code, msg in
                        
                    }

                }
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func transferAction() {
        let groupID = conversation.groupID
        checkPermissions([1], tips: "You are not the owner of the group.")
            .subscribe(onSuccess: { _ in
                SelectGroupMemberVC.show(op: .transferOwner, groupID: groupID!)
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func changeNicknameAction() {
        let groupID = conversation.groupID
        checkPermissions(tips: "You're not in the group.")
            .subscribe(onSuccess: { [weak self] member in
                UIAlertController.show(title: "Modify group nicknames?",
                                       message: nil,
                                       text: member.nickName,
                                       placeholder: "")
                { text in
                    guard let self = self else { return }
                    
                }
            })
            .disposed(by: disposeBag)
            
    }
    
    @IBAction func clearHistoryAction() {
        UIAlertController.show(title: LocalizedString("Clear the chat history?"),
                               message: nil,
                               buttons: [LocalizedString("Yes")],
                               cancel: LocalizedString("No"))
        { (index) in
            if index == 1 {
//                OIMManager.deleteConversation(self.conversation.conversationID) { result in
//                    if case .success = result {
//                        NavigationModule.shared.pop(popCount: 2)
//                    }
//                }
                OpenIMiOSSDK.shared().deleteConversation(self.conversation.conversationID!) { msg in
                    DispatchQueue.main.async {
                        NavigationModule.shared.pop(popCount: 2)
                    }
                } onError: { code, msg in
                    
                }

            }
        }
    }
    
    @IBOutlet var muteBtn: SwitchButton!
    @IBAction func muteNotificationAction(_ sender: UIButton) {
        
    }
    
    @IBOutlet var pinBtn: SwitchButton!
    @IBAction func topAction(_ sender: UIButton) {
        let isPinned = !sender.isSelected
//        OIMManager.pinConversation(conversation.conversationID, isPinned: isPinned) { result in
//            sender.isSelected = isPinned
//        }
        OpenIMiOSSDK.shared().pinConversation(conversation.conversationID!, isPinned: isPinned) { msg in
            DispatchQueue.main.async {
                sender.isSelected = isPinned
            }
        } onError: { code, msg in
            
        }

    }
    
    @IBAction func leaveAction() {
        let groupID = groupInfo.groupID
        checkPermissions([2, 0], tips: "The group owner cannot quit the group.")
            .flatMap{ _ -> Single<Void> in
//                return rxRequest(showLoading: true, action: { OIMManager.quitGroup(gid: groupID, callback: $0) })
                return Single<Void>.create { single in
                    OpenIMiOSSDK.shared().quitGroup(groupID!) { msg in
                        single(.success(()))
                    } onError: { code, msg in
                    }

                    return Disposables.create()
                }
            }
            .subscribe(onSuccess: {
                DispatchQueue.main.async {
                    NavigationModule.shared.pop(popCount: 2)
                }
            })
            .disposed(by: self.disposeBag)
    }
}
