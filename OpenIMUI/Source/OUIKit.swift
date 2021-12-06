//
//  OUIKit.swift
//  OpenIMUI
//
//  Created by Snow on 2021/6/15.
//

import Foundation
import OpenIMSDKiOS

enum NullError: Error{
    case null
}

public protocol OUIKitMessageDelegate: AnyObject {
    func showMessage(_ text: String)
    func showError(_ error: Error)
    func showError(_ text: String)
}

public class OUIKit: NSObject {
    public static let shared = OUIKit()
    private override init() {
        super.init()
    }
    
    public weak var messageDelegate: OUIKitMessageDelegate?
    
    public func initSDK() {
//        OIMManager.initSDK()
//        OIMManager.setConversationListener(self)
//        OIMManager.setFriendListener(self)
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        OpenIMiOSSDK.shared().initSDK(IOS, ipApi: "http://47.112.160.66:10000", ipWs: "ws://47.112.160.66:17778", dbPath: documentsPath+"/") {
            
        } onConnectFailed: { errCode, errMsg in
            
        } onConnectSuccess: {
            
        } onKickedOffline: {
            
        } onUserTokenExpired: {
            
        } onSelfInfoUpdated: { userInfo in
            
        }

    }
    
    private var users: [String: UserInfo] = [:]
    
    internal func update(user: UserInfo) {
        self.users[user.uid!] = user
    }
    
    private var requestUids: Set<String> = []
    
    public func hasUser(_ uid: String) -> Bool {
        return users[uid] != nil
    }
    
    @discardableResult
    public func getUser(_ uid: String, isForce: Bool = false, callback: ((UserInfo?) -> Void)? = nil) -> UserInfo? {
        let user = users[uid]
        if !isForce, let user = users[uid] {
            return user
        }
        
        if isForce || !requestUids.contains(uid) {
            requestUids.insert(uid)
            
            OpenIMiOSSDK.shared().getUsersInfo([uid], onSuccess: { result in
                self.requestUids.remove(uid)
                let user = result.first
                if(user == nil) {
                    callback?(nil)
                    return;
                }
                self.users[(user as AnyObject).uid] = user
                callback?(user as? UserInfo)
            }, onError: { code, msg in
                callback?(nil)
            })
        }
        return user
    }
    
    public func getUsers(_ uids: [String], callback: ((Result<[UserInfo], Error>) -> Void)? = nil ) {
        OpenIMiOSSDK.shared().getUsersInfo(uids) { result in
            result.forEach { user in
                self.users[(user as AnyObject).uid] = user as? UserInfo
            }
            let res:[UserInfo] = result as! [UserInfo];
            callback?(.success(res))
        } onError: { code, errMsg in
            callback?(.failure(NullError.null))
        }

//        OIMManager.getUsers(uids: uids) { result in
//            if case let .success(array) = result {
//                array.forEach { user in
//                    self.users[user.uid] = user
//                }
//            }
//            callback?(result)
//        }
    }
    
    func post(name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable : Any]? = nil) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: object, userInfo: userInfo)
        }
    }
}

//extension OUIKit: OIMConversationListener {
//    
//    public static let onConversationChangedNotification = NSNotification.Name("OUIKit.onConversationChangedNotification")
//    
//    public func onConversationChanged(_ conversations: [OIMConversation]) {
//        post(name: OUIKit.onConversationChangedNotification, object: conversations)
//    }
//    
//    public static let onNewConversationNotification = NSNotification.Name("OUIKit.onNewConversationNotification")
//    
//    public func onNewConversation(_ conversations: [OIMConversation]) {
//        post(name: OUIKit.onNewConversationNotification, object: conversations)
//    }
//    
//    public static let onSyncServerFailedNotification = NSNotification.Name("OUIKit.onSyncServerFailedNotification")
//    
//    public func onSyncServerFailed() {
//        post(name: OUIKit.onSyncServerFailedNotification, object: nil)
//    }
//    
//    public static let onSyncServerFinishNotification = NSNotification.Name("OUIKit.onSyncServerFinishNotification")
//    
//    public func onSyncServerFinish() {
//        post(name: OUIKit.onSyncServerFinishNotification, object: nil)
//    }
//    
//    public static let onSyncServerStartNotification = NSNotification.Name("OUIKit.onSyncServerStartNotification")
//    
//    public func onSyncServerStart() {
//        post(name: OUIKit.onSyncServerStartNotification, object: nil)
//    }
//    
//    public static let onTotalUnreadMessageCountChangedNotification = NSNotification.Name("OUIKit.onTotalUnreadMessageCountChangedNotification")
//    
//    public func onTotalUnreadMessageCountChanged(_ count: Int32) {
//        post(name: OUIKit.onTotalUnreadMessageCountChangedNotification, object: count)
//    }
//}
//
//extension OUIKit: OIMFriendshipListener {
//    
//    public static let onFriendApplicationListAddedNotification = NSNotification.Name("OUIKit.onFriendApplicationListAddedNotification")
//    
//    public func onFriendApplicationListAdded(_ user: OIMUser) {
//        self.update(user: user)
//        DispatchQueue.main.async {
//            NotificationCenter.default.post(name: OUIKit.onFriendApplicationListAddedNotification, object: user)
//        }
//        post(name: OUIKit.onFriendApplicationListAddedNotification, object: user)
//    }
//    
//    public static let onFriendApplicationListDeletedNotification = NSNotification.Name("OUIKit.onFriendApplicationListDeletedNotification")
//    
//    public func onFriendApplicationListDeleted(_ uid: String) {
//        post(name: OUIKit.onFriendApplicationListDeletedNotification, object: uid)
//    }
//    
//    public static let onFriendApplicationListReadNotification = NSNotification.Name("OUIKit.onFriendApplicationListReadNotification")
//    
//    public func onFriendApplicationListRead() {
//        post(name: OUIKit.onFriendApplicationListReadNotification, object: nil)
//    }
//    
//    public static let onFriendApplicationListRejectNotification = NSNotification.Name("OUIKit.onFriendApplicationListRejectNotification")
//    
//    public func onFriendApplicationListReject(_ uid: String) {
//        post(name: OUIKit.onFriendApplicationListReadNotification, object: uid)
//    }
//    
//    public static let onFriendApplicationListAcceptNotification = NSNotification.Name("OUIKit.onFriendApplicationListAcceptNotification")
//    
//    public func onFriendApplicationListAccept(_ user: OIMUser) {
//        post(name: OUIKit.onFriendApplicationListAcceptNotification, object: user)
//    }
//    
//    public static let onFriendListAddedNotification = NSNotification.Name("OUIKit.onFriendListAddedNotification")
//    
//    public func onFriendListAdded() {
//        post(name: OUIKit.onFriendListAddedNotification, object: nil)
//    }
//    
//    public static let onFriendListDeletedNotification = NSNotification.Name("OUIKit.onFriendListDeletedNotification")
//    
//    public func onFriendListDeleted(_ uid: String) {
//        post(name: OUIKit.onFriendListDeletedNotification, object: uid)
//    }
//    
//    public static let onBlackListAddedNotification = NSNotification.Name("OUIKit.onBlackListAddedNotification")
//    
//    public func onBlackListAdded(_ user: OIMUser) {
//        post(name: OUIKit.onBlackListAddedNotification, object: user)
//    }
//    
//    public static let onBlackListDeletedNotification = NSNotification.Name("OUIKit.onBlackListDeletedNotification")
//    
//    public func onBlackListDeleted(_ uid: String) {
//        post(name: OUIKit.onBlackListDeletedNotification, object: uid)
//    }
//    
//    public static let onFriendProfileChangedNotification = NSNotification.Name("OUIKit.onFriendProfileChangedNotification")
//    
//    public func onFriendProfileChanged(_ user: OIMUser) {
//        update(user: user)
//        post(name: OUIKit.onFriendProfileChangedNotification, object: user)
//    }
//    
//}
//
//extension OUIKit: OIMGroupListener {
//    
//    public static let onApplicationProcessedNotification = NSNotification.Name("OUIKit.onApplicationProcessedNotification")
//    
//    public func onApplicationProcessed(_ groupId: String, opUser: OIMGroupMember, agreeOrReject AgreeOrReject: Int32, opReason: String) {
//        post(name: OUIKit.onApplicationProcessedNotification, object: [
//            "groupId": groupId,
//            "opUser": opUser,
//            "opReason": opReason,
//        ])
//    }
//    
//    public static let onGroupCreatedNotification = NSNotification.Name("OUIKit.onGroupCreated")
//    
//    public func onGroupCreated(_ groupId: String) {
//        post(name: OUIKit.onGroupCreatedNotification, object: groupId)
//    }
//    
//    public static let onGroupInfoChangedNotification = NSNotification.Name("OUIKit.onGroupInfoChangedNotification")
//    
//    public func onGroupInfoChanged(_ groupId: String, groupInfo: OIMGroupInfo) {
//        post(name: OUIKit.onGroupInfoChangedNotification, object: groupInfo)
//    }
//    
//    public static let onMemberEnterNotification = NSNotification.Name("OUIKit.onMemberEnterNotification")
//    
//    public func onMemberEnter(_ groupId: String, memberList: [OIMGroupMember]) {
//        post(name: OUIKit.onMemberEnterNotification, object: memberList)
//    }
//    
//    public static let onMemberInvitedNotification = NSNotification.Name("OUIKit.onMemberInvitedNotification")
//    
//    public func onMemberInvited(_ groupId: String, opUser: OIMGroupMember, memberList: [OIMGroupMember]) {
//        post(name: OUIKit.onMemberInvitedNotification, object: [
//            "groupId": groupId,
//            "memberList": memberList,
//        ])
//    }
//    
//    public static let onMemberKickedNotification = NSNotification.Name("OUIKit.onMemberKickedNotification")
//    
//    public func onMemberKicked(_ groupId: String, opUser: OIMGroupMember, memberList: [OIMGroupMember]) {
//        post(name: OUIKit.onMemberKickedNotification, object: [
//            "groupId": groupId,
//            "opUser": opUser,
//            "memberList": memberList,
//        ])
//    }
//    
//    public static let onMemberLeaveNotification = NSNotification.Name("OUIKit.onMemberLeaveNotification")
//    
//    public func onMemberLeave(_ groupId: String, member: OIMGroupMember) {
//        post(name: OUIKit.onMemberLeaveNotification, object: [
//            "groupId": groupId,
//            "member": member,
//        ])
//    }
//    
//    public static let onReceiveJoinApplicationNotification = NSNotification.Name("OUIKit.onReceiveJoinApplicationNotification")
//    
//    public func onReceiveJoinApplication(_ groupId: String, member: OIMGroupMember, opReason: String) {
//        post(name: OUIKit.onMemberLeaveNotification, object: [
//            "groupId": groupId,
//            "opReason": opReason,
//        ])
//    }
//    
//}
