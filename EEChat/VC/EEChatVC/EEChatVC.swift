//
//  EEChatVC.swift
//  Alamofire
//
//  Created by Snow on 2021/6/11.
//

import Foundation
import OpenIMSDKiOS
import OpenIMUI

class EEChatVC: IMConversationViewController {
    
    class func show(uid: String = "", groupID: String = "", popCount: Int = 0) {
//        let type: OIMConversationType = uid != "" ? .c2c : .group
//        _ = rxRequest(showLoading: true, action: { OIMManager.getConversation(type: type,
//                                                                              id: uid != "" ? uid : groupID,
//                                                                              callback: $0) })
//            .subscribe(onSuccess: { conversation in
//                let vc = EEChatVC(conversation: conversation)
//                NavigationModule.shared.push(vc, popCount: popCount, animated: true)
//            })
        OpenIMiOSSDK.shared().getOneConversation(uid != "" ? uid : groupID, session: uid != "" ? 1 : 2) { conversation in
            DispatchQueue.main.async {
                let vc = EEChatVC(conversation: conversation)
                NavigationModule.shared.push(vc, popCount: popCount, animated: true)
            }
        } onError: { code, msg in
            
        }

    }
    
    class func show(conversation: ConversationInfo) {
        let vc = EEChatVC.init(conversation: conversation)
        NavigationModule.shared.push(vc)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "chat_icon_more")?
                                                                .withRenderingMode(.alwaysOriginal),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(friendSettingAction))
        
        inputVC.moreView.frame.size.height = 120
        title = conversation.showName
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        menuWindow.hide()
    }
    
    private var menuWindow = MenuWindow()
    
    override func messageViewController(_ messageViewController: IMMessageViewController, showMenuForItemAt cell: MessageCollectionViewCell, message: MessageType) {
        guard let cell = cell as? MessageContentCell else {
            return
        }
        
        var items: [MenuItem] = []
        if case let ContentType.text(text) = message.content {
            let copyItem = MenuItem(title: LocalizedString("Copy"),
                                    image: UIImage(named: "chat_popup_icon_copy"))
            {
                UIPasteboard.general.string = text
                MessageModule.showMessage(LocalizedString("Copied"))
            }
            items = [copyItem]
        }
        
        let deleteItem = MenuItem(title: LocalizedString("Delete"),
                                  image: UIImage(named: "chat_popup_icon_delete"))
        {
            UIAlertController.show(title: LocalizedString("Delete?"),
                                   message: nil,
                                   buttons: [LocalizedString("Yes")],
                                   cancel: LocalizedString("No"))
            { (index) in
                if index == 0 {
                    return
                }
                
//                OIMManager.deleteMessageFromLocalStorage([message.innerMessage], callback: { result in
//
//                })
                OpenIMiOSSDK.shared().deleteMessage(fromLocalStorage: message.innerMessage) { msg in
                    
                } onError: { code, msg in
                    
                }

                self.remove(message)
            }
        }
        
        let forwardItem = MenuItem(title: LocalizedString("Forward"),
                                   image: UIImage(named: "chat_popup_icon_forward"))
        {
            LocalSearchUserVC.show(param: message)
        }
        
        items.append(contentsOf: [deleteItem])
        menuWindow.show(targetView: cell.messageContainerView, items: items)
    }
    
    override func inputViewController(_ inputViewController: IMInputViewController, didInputAt completionHandler: @escaping (String, String) -> Void) {
        guard !conversation.groupID!.isEmpty else {
            return
        }
        SelectGroupMemberVC.show(op: .at, groupID: conversation.groupID!) { any in
            let member = any as! GroupMembersInfo
            completionHandler(member.nickName!, member.userId!)
        }
    }
    
    // MARK: - Action
    
    @objc
    func friendSettingAction() {
        if conversation.userID != "" {
            FriendSettingVC.show(param: conversation)
        } else {
            GroupSettingVC.show(param: conversation)
        }
    }

}
