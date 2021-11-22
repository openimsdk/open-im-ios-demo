//
//  SessionListVC.swift
//  EEChat
//
//  Created by Snow on 2021/5/18.
//

import UIKit
import RxSwift
import RxCocoa
import OpenIMSDKiOS
import OpenIMUI
import Foundation

class SessionListVC: BaseViewController {
    
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindAction()
     
        updateConversation()
    }
    
    private var array: [ConversationInfo] = []
    
    private func bindAction() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SessionListCell.eec.nib(), forCellReuseIdentifier: "cell")
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateConversation),
                                               name: NSNotification.Name("OUIKit.onNewConversationNotification"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateConversation),
                                               name: NSNotification.Name("OUIKit.onConversationChangedNotification"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateConversation),
                                               name: NSNotification.Name("OUIKit.onFriendProfileChangedNotification"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateConversation),
                                               name: NSNotification.Name("OUIKit.onGroupInfoChangedNotification"),
                                               object: nil)
    }
    
    private func config(array: [ConversationInfo]) {
        self.array = array.sorted { lhs, rhs in
            func timestamp(_ model: ConversationInfo) -> TimeInterval {
                if let text = NSAttributedString.from(base64Encoded: model.draftText!)?.string, !text.isEmpty {
                    return TimeInterval(model.draftTimestamp)
                }
//                if let message = model.latestMsg?.toUIMessage() {
//                    return message.sendTime
//                }
                return TimeInterval(model.draftTimestamp)
            }
            return timestamp(lhs) > timestamp(rhs)
        }
        self.tableView.reloadData()
    }
    
    @objc
    func onFriendProfileChanged() {
        tableView.reloadData()
    }
    
    @objc
    func updateConversation() {
//        OIMManager.getConversationList { [weak self] result in
//            guard let self = self else { return }
//            if case let .success(array) = result {
//                self.config(array: array)
//            }
//        }
        OpenIMiOSSDK.shared().getAllConversationList { [weak self] array in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.config(array: array)
            }
        } on: { code, msg in
            
        }

    }

}

extension SessionListVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let model = array[indexPath.row]
        let isPinned = model.isPinned
        let title = (isPinned != 0) ? "取消置顶" : "置顶"
        let top = UIContextualAction(style: .normal, title: title)
        { (action, view, completionHandler) in
            let isPinned = (isPinned == 0)
//
//            OIMManager.pinConversation(model.conversationID, isPinned: isPinned) { result in
//                self.tableView.performBatchUpdates {
//                    var newRow: Int = {
//                        if isPinned {
//                            return 0
//                        }
//                        return self.array.firstIndex { !$0.isPinned } ?? self.array.count - 1
//                    }()
//                    model.isPinned = isPinned
//                    if indexPath.row < newRow {
//                        newRow -= 1
//                    }
//
//                    self.array.remove(at: indexPath.row)
//                    self.array.insert(model, at: newRow)
//                    self.tableView.moveRow(at: indexPath, to: IndexPath(row: newRow, section: 0))
//                }
//            }
            OpenIMiOSSDK.shared().pinConversation(model.conversationID!, isPinned: isPinned) { msg in
                DispatchQueue.main.async {
                    self.tableView.performBatchUpdates {
                        var newRow: Int = {
                            if isPinned {
                                return 0
                            }
                            return self.array.firstIndex { ($0.isPinned == 0) } ?? self.array.count - 1
                        }()
                        model.isPinned = isPinned ? 1 : 0
                        if indexPath.row < newRow {
                            newRow -= 1
                        }

                        self.array.remove(at: indexPath.row)
                        self.array.insert(model, at: newRow)
                        self.tableView.moveRow(at: indexPath, to: IndexPath(row: newRow, section: 0))
                    }
                }
            } onError: { code, msg in
                
            }

        }
        top.backgroundColor = UIColor.eec.rgb(0x1B72EC)

        let delete = UIContextualAction(style: .destructive, title: "删除")
        { (action, view, completionHandler) in
//            OIMManager.deleteConversation(model.conversationID) { result in
//                self.tableView.performBatchUpdates {
//                    self.array.remove(at: indexPath.row)
//                    self.tableView.deleteRows(at: [indexPath], with: .fade)
//                }
//            }
            OpenIMiOSSDK.shared().deleteConversation(model.conversationID!) { result in
                DispatchQueue.main.async {
                    self.tableView.performBatchUpdates {
                        self.array.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath], with: .fade)
                    }
                }
            } onError: { code, msg in
                
            }

        }
        delete.backgroundColor = UIColor.eec.rgb(0x7CBAFF)

        if model.unreadCount == 0 {
            return UISwipeActionsConfiguration(actions: [delete, top])
        }

        let read = UIContextualAction(style: .destructive, title: "标为已读")
        { (action, view, completionHandler) in
//            OIMManager.markMessageHasRead(uid: model.userID, gid: model.groupID) { _ in
//                model.unreadCount = 0
//                self.tableView.reloadRows(at: [indexPath], with: .none)
//            }
            OpenIMiOSSDK.shared().markGroupMessageHasRead(model.groupID!) { msg in
                DispatchQueue.main.async {
                    model.unreadCount = 0
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
            } onError: { code, msg in
                
            }

        }
        read.backgroundColor = UIColor.eec.rgb(0xFFD576)

        return UISwipeActionsConfiguration(actions: [read, delete, top])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = array[indexPath.row]
        EEChatVC.show(conversation: model)
        OpenIMiOSSDK.shared().markSingleMessageHasRead(model.userID ?? "") { msg in
            
        } onError: { code, msg in
            
        }

        OpenIMiOSSDK.shared().markGroupMessageHasRead(model.groupID ?? "") { msg in
            
        } onError: { code, msg in
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateConversation()
    }
    
}

extension SessionListVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SessionListCell
        cell.model = array[indexPath.row]
        return cell
    }
}
