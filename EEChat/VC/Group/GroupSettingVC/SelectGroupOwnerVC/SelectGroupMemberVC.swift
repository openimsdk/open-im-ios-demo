//
//  SelectGroupMemberVC.swift
//  EEChat
//
//  Created by Snow on 2021/7/8.
//

import UIKit
import RxCocoa
import OpenIMSDKiOS

class SelectGroupMemberVC: BaseViewController {
    
    enum Operation {
        case transferOwner
        case removeMember
        case at
    }
    
    static func show(op: Operation, groupID: String, callback: BaseViewController.Callback? = nil) {
//        _ = rxRequest(showLoading: true, action: { OIMManager.getGroupMemberList(gid: groupID,
//                                                                                   filter: .all,
//                                                                                   next: 0,
//                                                                                   callback: $0) })
//            .subscribe(onSuccess: { result in
//                super.show(param: (op, result), callback: callback)
//            })
        OpenIMiOSSDK.shared().getGroupMemberList(groupID, filter: 0, next: 0) { result in
            DispatchQueue.main.async {
                super.show(param: (op, result), callback: callback)
            }
        } onError: { code, msg in
            
        }

    }

    @IBOutlet var tableView: UITableView!
    
    private var op: Operation!
    private var result: GroupMembersList?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(param is (Operation, GroupMembersList))
        (op, result) = param as! (Operation, GroupMembersList)
        
        bindAction()
        if op == .at {
            title = "Please select an at member"
        }
    }
    
    private lazy var relay = BehaviorRelay(value: result!.data)
    
    private func bindAction() {
        tableView.register(LaunchGroupChatCell.eec.nib(), forCellReuseIdentifier: "cell")
        
//        relay
//            .bind(to: tableView.rx.items(cellIdentifier: "cell", cellType: LaunchGroupChatCell.self)) { _, element, cell in
//                cell.model = element
//            }
//            .disposed(by: disposeBag)
        
        tableView.delegate = self
        tableView.rx.modelSelected(GroupMembersInfo.self)
            .subscribe(onNext: { [unowned self] member in
                switch self.op! {
                case .transferOwner:
                    self.transferOwner(member: member)
                case .removeMember:
                    break
                case .at:
                    self.callback?(member)
                    NavigationModule.shared.pop()
                }
            })
            .disposed(by: disposeBag)
        
        if op == .removeMember {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "done",
                                                                style: .plain,
                                                                target: self,
                                                                action: #selector(deleteMember))
            tableView.isEditing = true
            tableView.rx.modelDeselected(GroupMembersInfo.self)
                .subscribe(onNext: { [unowned self] member in
                    
                })
                .disposed(by: disposeBag)
        }
    
    }
    
    private func transferOwner(member: GroupMembersInfo) {
        let title = "Make sure to choose the new group leader of \(member.nickName), you will automatically give up the group leader identity."
        UIAlertController.show(title: title,
                               message: nil,
                               buttons: ["Yes"],
                               cancel: "No") { index in
            if index == 1 {
//                _ = rxRequest(showLoading: true, action: { OIMManager.transferGroupOwner(gid: member.groupID,
//                                                                                       uid: member.userId,
//                                                                                       callback: $0) })
//                    .subscribe(onSuccess: {
//                        MessageModule.showMessage("You successfully transferred the owner of the group!")
//                        NavigationModule.shared.pop()
//                    })
                OpenIMiOSSDK.shared().transferGroupOwner(member.groupID!, uid: member.userId!) { msg in
                    DispatchQueue.main.async {
                        MessageModule.showMessage("You successfully transferred the owner of the group!")
                        NavigationModule.shared.pop()
                    }
                } onError: { code, msg in
                    
                }

            }
        }
    }
    
    @objc
    private func deleteMember() {
        guard let members: [GroupMembersInfo] = tableView.indexPathsForSelectedRows?.map({ try! tableView.rx.model(at: $0) }),
              !members.isEmpty else {
            MessageModule.showMessage("Members to delete have not been selected.")
            return
        }
        
        let groupID = members[0].groupID
        let uids = members.map{ $0.userId }
        UIAlertController.show(title: "Are you sure you want to delete?",
                               message: nil,
                               buttons: ["Yes"],
                               cancel: "No")
        { [weak self] index in
            guard let self = self else { return }
            if index == 1 {
//                rxRequest(showLoading: true, action: { OIMManager.kickGroupMember(gid: groupID,
//                                                                                  reason: "",
//                                                                                  uids: uids,
//                                                                                  callback: $0) })
//                    .subscribe(onSuccess: {
//                        MessageModule.showMessage("Group member deleted successfully.")
//                        NavigationModule.shared.pop()
//                    })
//                    .disposed(by: self.disposeBag)
                OpenIMiOSSDK.shared().kickGroupMember(groupID!, reason: "", uidList: uids) { _ in
                    DispatchQueue.main.async {
                        MessageModule.showMessage("Group member deleted successfully.")
                        NavigationModule.shared.pop()
                    }
                } onError: { code, msg in
                    
                }

            }
        }
    }
    
}

extension SelectGroupMemberVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let member: GroupMembersInfo = try! tableView.rx.model(at: indexPath)
        switch op! {
        case .transferOwner:
            if member.role == 1 {
                MessageModule.showMessage("Can't transfer group to oneself.")
                return nil
            }
        case .removeMember:
            if member.userId == OpenIMiOSSDK.shared().getLoginUid() {
                MessageModule.showMessage("You can't delete yourself.")
                return nil
            }
            if member.role == 1 {
                MessageModule.showMessage("The group owner could not be removed.")
                return nil
            }
        case .at:
            if member.userId == OpenIMiOSSDK.shared().getLoginUid() {
                MessageModule.showMessage("Don't allow at yourself.")
                return nil
            }
        }
        return indexPath
    }
}
