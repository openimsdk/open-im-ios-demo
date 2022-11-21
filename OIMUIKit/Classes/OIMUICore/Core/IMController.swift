
import Foundation
import IQKeyboardManagerSwift
import OpenIMSDK
import RxCocoa
import RxSwift
import SVProgressHUD
import UIKit

public class IMController: NSObject {
    public static let addFriendPrefix = "io.openim.app/addFriend/"
    public static let joinGroupPrefix = "io.openim.app/joinGroup/"
    public static let shared: IMController = .init()
    private(set) var imManager: OpenIMSDK.OIMManager!
    /// 好友申请列表新增
    let friendApplicationChangedSubject: PublishSubject<FriendApplication> = .init()
    /// 组申请信息更新
    let groupApplicationChangedSubject: PublishSubject<GroupApplicationInfo> = .init()
    public let contactUnreadSubject: PublishSubject<Int> = .init()

    let conversationChangedSubject: BehaviorSubject<[ConversationInfo]> = .init(value: [])
    let friendInfoChangedSubject: BehaviorSubject<UserInfo?> = .init(value: nil)

    let syncServerStartSubject: PublishSubject<Void> = PublishSubject()
    let syncServerEndSubject: PublishSubject<Void> = PublishSubject()
    let newConversationSubject: BehaviorSubject<[ConversationInfo]> = .init(value: [])
    public let totalUnreadSubject: BehaviorSubject<Int> = .init(value: 0)
    let newMsgReceivedSubject: PublishSubject<MessageInfo> = .init()
    let c2cReadReceiptReceived: BehaviorSubject<[ReceiptInfo]> = .init(value: [])
    let groupReadReceiptReceived: BehaviorSubject<[ReceiptInfo]> = .init(value: [])
    let msgRevokeReceived: PublishSubject<String> = .init()
    public let currentUserRelay: BehaviorRelay<UserInfo?> = .init(value: nil)

    private(set) var uid: String = ""

    public func setup(apiAdrr: String, wsAddr: String, os: String) {
        let manager = OpenIMSDK.OIMManager()

        manager.initSDK(withApiAdrr: apiAdrr, wsAddr: wsAddr, dataDir: nil, logLevel: 6, objectStorage: os, onConnecting: {
            print("onConnecting")
        }, onConnectFailure: { (errCode: Int, errMsg: String?) in
            print("onConnectFailed code:\(errCode), msg:\(String(describing: errMsg))")
        }, onConnectSuccess: {
            print("onConnectSuccess")
        }, onKickedOffline: {
            print("onKickedOffline")
        }, onUserTokenExpired: {
            print("onUserTokenExpired")
        })
        Self.shared.imManager = manager
        // Set listener
        OpenIMSDK.OIMManager.callbacker.addFriendListener(listener: self)
        OpenIMSDK.OIMManager.callbacker.addGroupListener(listener: self)
        OpenIMSDK.OIMManager.callbacker.addConversationListener(listener: self)
        OpenIMSDK.OIMManager.callbacker.addAdvancedMsgListener(listener: self)

        SVProgressHUD.setDefaultStyle(SVProgressHUDStyle.dark)
        SVProgressHUD.setMaximumDismissTimeInterval(1)

        UINavigationBar.appearance().isTranslucent = true
        UINavigationBar.appearance().isOpaque = true

        if #available(iOS 13.0, *) {
            let app = UINavigationBarAppearance()
            app.configureWithOpaqueBackground()
            app.titleTextAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18),
                NSAttributedString.Key.foregroundColor: StandardUI.color_333333,
            ]
            app.backgroundColor = UIColor.white
            app.shadowColor = .clear
            UINavigationBar.appearance().scrollEdgeAppearance = app
            UINavigationBar.appearance().standardAppearance = app
        }

        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.disabledDistanceHandlingClasses = [
            MessageListViewController.self,
        ]
        IQKeyboardManager.shared.disabledToolbarClasses = [
            MessageListViewController.self,
        ]
        IQKeyboardManager.shared.disabledTouchResignedClasses = [
            SearchResultViewController.self,
            SearchFriendViewController.self,
            SearchGroupViewController.self,
        ]
    }

    public func login(uid: String, token: String, onSuccess: @escaping (String?) -> Void, onFail: @escaping (Int, String?) -> Void) {
        Self.shared.imManager.login(uid, token: token) { [weak self] (resp: String?) in
            self?.uid = uid
            let event = EventLoginSucceed()
            JNNotificationCenter.shared.post(event)
            onSuccess(resp)
        } onFailure: { (code: Int, msg: String?) in
            onFail(code, msg)
        }
    }

    struct NetError: Error {
        let code: Int
        let message: String?
    }

    typealias MessagesCallBack = ([MessageInfo]) -> Void
}

// MARK: - 对外协议

public protocol ContactsDataSource: AnyObject {
    func setFrequentUsers(_ users: [OIMUserInfo])
    func getFrequentUsers() -> [OIMUserInfo]
}

// MARK: - 联系人方法

extension IMController {
    /// 根据id查找群
    /// - Parameter ids: 群id
    /// - Returns: 第一个群的id
    func getGroupListBy(id: String) -> Observable<String?> {
        return Observable<String?>.create { observer in
            Self.shared.imManager.getGroupsInfo([id], onSuccess: { (groups: [OIMGroupInfo]?) in
                observer.onNext(groups?.first?.groupID)
                observer.onCompleted()
            }, onFailure: { (code: Int, msg: String?) in
                observer.onError(NetError(code: code, message: msg))
            })

            return Disposables.create()
        }
    }

    func getJoinedGroupList(completion: @escaping ([GroupInfo]) -> Void) {
        Self.shared.imManager.getJoinedGroupListWith { (groups: [OIMGroupInfo]?) in
            guard let groups = groups else {
                completion([])
                return
            }

            let joined: [GroupInfo] = groups.compactMap { $0.toGroupInfo() }
            completion(joined)
        } onFailure: { code, msg in
            print("拉取我的群组错误,code:\(code), msg: \(msg)")
        }
    }

    /// 根据id查找用户
    /// - Parameter ids: 用户id
    /// - Returns: 第一个用户id
    func getFriendsBy(id: String) -> Observable<FullUserInfo?> {
        return Observable<FullUserInfo?>.create { observer in
            Self.shared.imManager.getUsersInfo([id]) { (users: [OIMFullUserInfo]?) in
                observer.onNext(users?.first?.toFullUserInfo())
                observer.onCompleted()
            } onFailure: { (code: Int, msg: String?) in
                observer.onError(NetError(code: code, message: msg))
            }
            return Disposables.create()
        }
    }

    /// 获取好友申请列表
    /// - Parameter completion: 申请数组
    func getFriendApplicationList(completion: @escaping ([FriendApplication]) -> Void) {
        Self.shared.imManager.getFriendApplicationListWith { (applications: [OIMFriendApplication]?) in
            let arr = applications ?? []
            let ret = arr.compactMap { $0.toFriendApplication() }
            completion(ret)
        }
    }

    /// 接受好友申请
    /// - Parameters:
    ///   - uid: 指定好友ID
    ///   - handleMsg: 处理理由
    ///   - completion: 响应消息
    func acceptFriendApplication(uid: String, handleMsg: String, completion: @escaping (String?) -> Void) {
        Self.shared.imManager.acceptFriendApplication(uid, handleMsg: handleMsg) { (resp: String?) in
            completion(resp)
        }
    }

    func getGroupApplicationList(completion: @escaping ([GroupApplicationInfo]) -> Void) {
        Self.shared.imManager.getGroupApplicationListWith { (applications: [OIMGroupApplicationInfo]?) in
            let arr = applications ?? []
            let ret = arr.compactMap { $0.toGroupApplicationInfo() }
            completion(ret)
        }
    }

    func getFriendList(completion: @escaping ([UserInfo]) -> Void) {
        Self.shared.imManager.getFriendListWith { (friends: [OIMFullUserInfo]?) in
            let arr = friends ?? []
            let ret = arr.compactMap { $0.toUserInfo() }
            completion(ret)
        }
    }

    func getGroupMemberList(groupId: String, filter: GroupMemberRole = .undefine, offset: Int, count: Int, onSuccess: @escaping CallBack.GroupMembersReturnVoid) {
        Self.shared.imManager.getGroupMemberList(groupId, filter: OIMGroupMemberRole(rawValue: filter.rawValue) ?? OIMGroupMemberRole.member, offset: offset, count: count) { (memberInfos: [OIMGroupMemberInfo]?) in
            let members: [GroupMemberInfo] = memberInfos?.compactMap { $0.toGroupMemberInfo() } ?? []
            onSuccess(members)
        }
    }

    func getGroupMembersInfo(groupId: String, uids: [String], onSuccess: @escaping CallBack.GroupMembersReturnVoid) {
        Self.shared.imManager.getGroupMembersInfo(groupId, uids: uids) { (groupMembers: [OIMGroupMemberInfo]?) in
            let members: [GroupMemberInfo] = groupMembers?.compactMap { $0.toGroupMemberInfo() } ?? []
            onSuccess(members)
        } onFailure: { code, msg in
            print("获取组成员信息失败:\(code),\(msg)")
        }
    }

    func getGroupInfo(groupIds: [String], onSuccess: @escaping CallBack.GroupInfosReturnVoid) {
        Self.shared.imManager.getGroupsInfo(groupIds) { (groupInfos: [OIMGroupInfo]?) in
            let groups: [GroupInfo] = groupInfos?.compactMap { $0.toGroupInfo() } ?? []
            onSuccess(groups)
        } onFailure: { code, msg in
            print("获取组信息失败:\(code), \(msg)")
        }
    }

    func setGroupInfo(group: GroupInfo, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.setGroupInfo(group.groupID, groupInfo: group.toOIMGroupBaseInfo(), onSuccess: onSuccess) { code, msg in
            print("更新群信息失败：\(code), \(msg)")
        }
    }

    func setGroupMemberNicknameOf(userid: String, inGroupId: String, with name: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.setGroupMemberNickname(inGroupId, userID: userid, groupNickname: name, onSuccess: onSuccess) { code, msg in
            print("设置群成员昵称失败：\(code), \(msg)")
        }
    }

    func dismissGroup(id: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.dismissGroup(id, onSuccess: onSuccess) { code, msg in
            print("解散群聊失败:\(code), \(msg)")
        }
    }

    func quitGroup(id: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.quitGroup(id, onSuccess: onSuccess) { code, msg in
            print("退出群聊失败:\(code), \(msg)")
        }
    }

    func joinGroup(id: String, reqMsg: String?, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.joinGroup(id, reqMsg: reqMsg, onSuccess: onSuccess) { code, msg in
            print("加入群聊失败:\(code), \(msg)")
        }
    }

    func inviteUsersToGroup(groupId: String, uids: [String], onSuccess: @escaping CallBack.VoidReturnVoid) {
        Self.shared.imManager.inviteUser(toGroup: groupId, reason: "", uids: uids) { (_: [OIMSimpleResultInfo]?) in
            onSuccess()
        } onFailure: { code, msg in
            print("邀请好友加入失败：\(code), \(msg)")
        }
    }

    func addFriend(uid: String, reqMsg: String?, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.addFriend(uid, reqMessage: reqMsg, onSuccess: onSuccess)
    }
}

// MARK: - 消息方法

extension IMController {
    func getAllConversationList(completion: @escaping ([ConversationInfo]) -> Void) {
        Self.shared.imManager.getAllConversationListWith { (conversations: [OIMConversationInfo]?) in
            let arr = conversations ?? []
            let ret = arr.compactMap { $0.toConversationInfo() }
            completion(ret)
        }
    }

    /// 删除指定会话（本地删除）
    func deleteConversationFromLocalStorage(conversationId: String, completion: ((String?) -> Void)?) {
        Self.shared.imManager.deleteConversation(fromLocalStorage: conversationId, onSuccess: completion)
    }

    /// 删除指定会话（服务器和本地均删除）
    func deleteConversation(conversationId: String, completion: ((String?) -> Void)?) {
        Self.shared.imManager.deleteConversation(conversationId, onSuccess: completion)
    }

    func getTotalUnreadMsgCount(completion: ((Int) -> Void)?) {
        Self.shared.imManager.getTotalUnreadMsgCountWith(onSuccess: completion, onFailure: nil)
    }

    func getConversationRecvMessageOpt(conversationIds: [String], completion: (([ConversationNotDisturbInfo]?) -> Void)?) {
        Self.shared.imManager.getConversationRecvMessageOpt(conversationIds) { (conversationInfos: [OIMConversationNotDisturbInfo]?) in
            let arr = conversationInfos?.compactMap { $0.toConversationNotDisturbInfo() }
            completion?(arr)
        }
    }

    func setConversationRecvMessageOpt(conversationIds: [String], status: ReceiveMessageOpt, completion: ((String?) -> Void)?) {
        let opt: OIMReceiveMessageOpt
        switch status {
        case .receive:
            opt = .receive
        case .notReceive:
            opt = .notReceive
        case .notNotify:
            opt = .notNotify
        }

        Self.shared.imManager.setConversationRecvMessageOpt(conversationIds, status: opt, onSuccess: completion) { code, msg in
            print("修改免打扰状态失败:\(code), \(msg)")
        }
    }

    func pinConversation(id: String, isPinned: Bool, completion: ((String?) -> Void)?) {
        Self.shared.imManager.pinConversation(id, isPinned: !isPinned, onSuccess: completion) { code, msg in
            print("pin conversation failed: \(code), \(msg)")
        }
    }

    func getHistoryMessageList(userId: String?, groupId: String?, startCliendMsgId: String?, count: Int, completion: @escaping MessagesCallBack) {
        Self.shared.imManager.getHistoryMessageList(withUserId: userId, groupID: groupId, startClientMsgID: startCliendMsgId, count: count) { (messages: [OIMMessageInfo]?) in
            let arr = messages?.compactMap { $0.toMessageInfo() } ?? []
            completion(arr)
        }
    }

    func send(message: MessageInfo, to conversation: ConversationInfo, onComplete: @escaping CallBack.MessageReturnVoid) {
        let mMessage = message.toOIMMessageInfo()
        send(message: mMessage, to: conversation, onComplete: onComplete)
    }

    private func send(message: OIMMessageInfo, to conversation: ConversationInfo, onComplete: @escaping CallBack.MessageReturnVoid) {
        let model = message.toMessageInfo()
        model.isRead = false
        if let uid = conversation.userID, uid.isEmpty == false {
            Self.shared.imManager.sendMessage(message, recvID: uid, groupID: nil, offlinePushInfo: nil) { (newMessage: OIMMessageInfo?) in
                if let respMessage = newMessage {
                    onComplete(respMessage.toMessageInfo())
                } else {
                    model.status = .sendSuccess
                    onComplete(model)
                }
            } onProgress: { (progress: Int) in
                print("sending message progress: \(progress)")
            } onFailure: { (_: Int, msg: String?) in
                print("send message error:", msg)
                model.status = .sendFailure
                onComplete(model)
            }
        }

        if let gid = conversation.groupID, gid.isEmpty == false {
            Self.shared.imManager.sendMessage(message, recvID: nil, groupID: gid, offlinePushInfo: nil) { (newMessage: OIMMessageInfo?) in
                if let respMessage = newMessage {
                    onComplete(respMessage.toMessageInfo())
                } else {
                    model.status = .sendSuccess
                    onComplete(model)
                }
            } onProgress: { (progress: Int) in
                print("sending message progress: \(progress)")
            } onFailure: { (_: Int, msg: String?) in
                print("send message error:", msg)
                model.status = .sendFailure
                onComplete(model)
            }
        }
    }

    func sendTextMessage(text: String, quoteMessage: MessageInfo?, to conversation: ConversationInfo, sending: CallBack.MessageReturnVoid, onComplete: @escaping CallBack.MessageReturnVoid) {
        let message: OIMMessageInfo
        if let quoteMessage = quoteMessage {
            let quote = quoteMessage.toOIMMessageInfo()
            message = OIMMessageInfo.createQuoteMessage(text, message: quote)
        } else {
            message = OIMMessageInfo.createTextMessage(text)
        }
        message.status = .sending
        sending(message.toMessageInfo())
        send(message: message, to: conversation, onComplete: onComplete)
    }

    func sendImageMessage(image: UIImage, to conversation: ConversationInfo, sending: CallBack.MessageReturnVoid, onComplete: @escaping CallBack.MessageReturnVoid) {
        let result: FileHelper.FileWriteResult = FileHelper.shared.saveImage(image: image)
        if result.isSuccess {
            let message = OIMMessageInfo.createImageMessage(result.relativeFilePath)
            message.status = .sending
            sending(message.toMessageInfo())
            send(message: message, to: conversation, onComplete: onComplete)
        }
    }

    func sendVideoMessage(videoPath: URL, duration: Int, snapshotPath: String, to conversation: ConversationInfo, sending: CallBack.MessageReturnVoid, onComplete: @escaping CallBack.MessageReturnVoid) {
        let result: FileHelper.FileWriteResult = FileHelper.shared.saveVideoFrom(videoPath: videoPath.path)
        if result.isSuccess {
            let message = OIMMessageInfo.createVideoMessage(result.relativeFilePath, videoType: "mp4", duration: duration, snapshotPath: snapshotPath)
            message.status = .sending
            sending(message.toMessageInfo())
            send(message: message, to: conversation, onComplete: onComplete)
        }
    }

    func sendAudioMessage(audioPath: String, duration: Int, to conversation: ConversationInfo, sending: CallBack.MessageReturnVoid, onComplete: @escaping CallBack.MessageReturnVoid) {
        let result: FileHelper.FileWriteResult = FileHelper.shared.saveAudioFrom(audioPath: audioPath)
        if result.isSuccess {
            let message = OIMMessageInfo.createSoundMessage(result.relativeFilePath, duration: duration)
            message.status = .sending
            sending(message.toMessageInfo())
            send(message: message, to: conversation, onComplete: onComplete)
        }
    }

    func sendCardMessage(card: BusinessCard, to conversation: ConversationInfo, sending: CallBack.MessageReturnVoid, onComplete: @escaping CallBack.MessageReturnVoid) {
        let json = JsonTool.toJson(fromObject: card)
        let message = OIMMessageInfo.createCardMessage(json)
        message.status = .sending
        sending(message.toMessageInfo())
        send(message: message, to: conversation, onComplete: onComplete)
    }

    func revokeMessage(_ message: MessageInfo, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        let oMessage = message.toOIMMessageInfo()
        Self.shared.imManager.revokeMessage(oMessage, onSuccess: onSuccess) { code, msg in
            print("消息撤回失败:\(code), msg:\(msg)")
        }
    }

    func deleteMessage(_ message: MessageInfo, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        let oMessage = message.toOIMMessageInfo()
        Self.shared.imManager.deleteMessage(oMessage, onSuccess: onSuccess, onFailure: { code, msg in
            print("消息删除失败:\(code), msg:\(msg)")
        })
    }

    func markC2CMessageReaded(userId: String, msgIdList: [String]) {
        Self.shared.imManager.markC2CMessage(asRead: userId, msgIDList: msgIdList, onSuccess: nil)
    }

    func markGroupMessageReaded(groupId: String, msgIdList: [String]) {
        Self.shared.imManager.markGroupMessage(asRead: groupId, msgIDList: msgIdList, onSuccess: nil)
    }

    func createGroupConversation(users: [UserInfo], onSuccess: @escaping CallBack.GroupInfoOptionalReturnVoid) {
        var members: [OIMGroupMemberInfo] = []
        let users = users.filter { (user: UserInfo) in
            user.userID != IMController.shared.uid
        }
        for user in users {
            let memberInfo = OIMGroupMemberInfo()
            memberInfo.userID = user.userID
            memberInfo.roleLevel = .member
            members.append(memberInfo)
        }

        let me = OIMGroupMemberInfo()
        me.userID = uid
        me.faceURL = currentUserRelay.value?.faceURL
        me.nickname = currentUserRelay.value?.nickname
        me.roleLevel = .super
        members.append(me)

        let createInfo = OIMGroupCreateInfo()
        createInfo.groupName = me.nickname?.append(string: "创建的群聊".innerLocalized())
        // 1是单聊，2是群聊，等待SDK更新为枚举类型
        createInfo.groupType = .working
        Self.shared.imManager.createGroup(createInfo, memberList: members) { (groupInfo: OIMGroupInfo?) in
            print("创建群聊成功")
            onSuccess(groupInfo?.toGroupInfo())
        }
    }

    func clearC2CHistoryMessages(userId: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.clearC2CHistoryMessage(userId, onSuccess: onSuccess) { code, msg in
            print("清空C2C聊天记录失败:\(code), \(msg)")
        }
    }

    func clearGroupHistoryMessages(groupId: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.clearGroupHistoryMessage(groupId, onSuccess: onSuccess) { code, msg in
            print("清空群聊天记录失败:\(code), \(msg)")
        }
    }

    public func uploadFile(fullPath: String, onProgress: @escaping CallBack.ProgressReturnVoid, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.uploadFile(withFullPath: fullPath, onProgress: onProgress, onSuccess: onSuccess) { code, msg in
            print("上传文件失败:\(code), \(msg)")
        }
    }

    func searchRecord(param: SearchParam, onSuccess: @escaping CallBack.SearchResultInfoOptionalReturnVoid) {
        Self.shared.imManager.searchLocalMessages(param.toOIMSearchParam()) { (result: OIMSearchResultInfo?) in
            onSuccess(result?.toSearchResultInfo())
        }
    }
}

// MARK: - 会话方法

extension IMController {
    func getConversation(sessionType: ConversationType, sourceId: String, onSuccess: @escaping CallBack.ConversationInfoOptionalReturnVoid) {
        let conversationType = OIMConversationType(rawValue: sessionType.rawValue) ?? OIMConversationType.undefine
        Self.shared.imManager.getOneConversation(withSessionType: conversationType, sourceID: sourceId) { (conversation: OIMConversationInfo?) in
            onSuccess(conversation?.toConversationInfo())
        } onFailure: { code, msg in
            print("创建会话失败:\(code), .msg:\(msg)")
        }
    }
}

// MARK: - User方法

extension IMController {
    /// 获取当前登录用户信息
    public func getSelfInfo(onSuccess: @escaping CallBack.UserInfoOptionalReturnVoid) {
        Self.shared.imManager.getSelfInfoWith { [weak self] (userInfo: OIMUserInfo?) in
            let user = userInfo?.toUserInfo()
            self?.currentUserRelay.accept(user)
            onSuccess(user)
        } onFailure: { code, msg in
            print("拉取登录用户信息失败:\(code), msg:\(msg)")
        }
    }

    func getUserInfo(uids: [String], onSuccess: @escaping CallBack.FullUserInfosReturnVoid) {
        Self.shared.imManager.getUsersInfo(uids) { (userInfos: [OIMFullUserInfo]?) in
            let users = userInfos?.compactMap { $0.toFullUserInfo() } ?? []
            onSuccess(users)
        }
    }

    func setSelfInfo(userInfo: UserInfo, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.setSelfInfo(userInfo.toOIMUserInfo(), onSuccess: onSuccess) { code, msg in
            print("更新个人信息失败:\(code), \(msg)")
        }
    }

    public func logout(onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.logoutWith(onSuccess: onSuccess) { code, msg in
            print("退出登录失败:\(code), \(msg)")
        }
    }
}

// MARK: - Listener

extension IMController: OIMFriendshipListener {
    @objc public func onFriendApplicationAdded(_ application: FriendApplication) {
        friendApplicationChangedSubject.onNext(application)
    }
}

// MARK: OIMGroupListener

extension IMController: OIMGroupListener {
    public func onGroupApplicationAdded(_ groupApplication: GroupApplicationInfo) {
        groupApplicationChangedSubject.onNext(groupApplication)
    }
}

// MARK: OIMConversationListener

extension IMController: OIMConversationListener {
    public func onConversationChanged(_ conversations: [OIMConversationInfo]) {
        let conversations: [ConversationInfo] = conversations.compactMap {
            $0.toConversationInfo()
        }
        conversationChangedSubject.onNext(conversations)
    }

    public func onSyncServerStart() {
        syncServerStartSubject.onNext(())
    }

    public func onSyncServerFinish() {
        syncServerEndSubject.onNext(())
    }

    public func onNewConversation(_ conversations: [OIMConversationInfo]) {
        let arr = conversations.compactMap { $0.toConversationInfo() }
        newConversationSubject.onNext(arr)
    }

    public func onTotalUnreadMessageCountChanged(_ totalUnreadCount: Int) {
        totalUnreadSubject.onNext(totalUnreadCount)
    }
}

// MARK: OIMAdvancedMsgListener

extension IMController: OIMAdvancedMsgListener {
    public func onRecvNewMessage(_ msg: OIMMessageInfo) {
        newMsgReceivedSubject.onNext(msg.toMessageInfo())
    }

    public func onRecvC2CReadReceipt(_ receiptList: [OIMReceiptInfo]) {
        c2cReadReceiptReceived.onNext(receiptList.compactMap { $0.toReceiptInfo() })
    }

    public func onRecvGroupReadReceipt(_ groupMsgReceiptList: [OIMReceiptInfo]) {
        groupReadReceiptReceived.onNext(groupMsgReceiptList.compactMap { $0.toReceiptInfo() })
    }

    public func onRecvMessageRevoked(_ msgID: String) {
        msgRevokeReceived.onNext(msgID)
    }
}

// MARK: - Models

// MARK: 主要模型

public class UserInfo: Encodable {
    public var userID: String = ""
    public var nickname: String?
    public var faceURL: String?
    public var gender: Gender?
    public var phoneNumber: String?
    public var birth: Int?
    var email: String?
    var createTime: Int = 0
    var ex: String?
}

public class FriendApplication: NSObject {
    var fromUserID: String = ""
    var fromNickname: String?
    var fromFaceURL: String?
    var toUserID: String = ""
    var toNickname: String?
    var toFaceURL: String?
    var handleResult: ApplicationStatus = .normal
    var reqMsg: String?
    var handlerUserID: String?
    var handleMsg: String?
    var handleTime: Int?
}

public class GroupApplicationInfo {
    var groupID: String = ""
    var groupName: String?
    var groupFaceURL: String?
    var creatorUserID: String = ""
    var ownerUserID: String = ""
    var memberCount: Int = 0
    var userID: String?
    var nickname: String?
    var userFaceURL: String?
    var reqMsg: String?
    var reqTime: Int?
    var handleUserID: String?
    var handledMsg: String?
    var handledTime: Int?
    var handleResult: ApplicationStatus = .normal
}

/// 申请状态
public enum ApplicationStatus: Int {
    /// 已拒绝
    case decline = -1
    /// 等待处理
    case normal = 0
    /// 已同意
    case accept = 1
}

/// 消息接收选项
public enum ReceiveMessageOpt: Int {
    /// 在线正常接收消息，离线时会使用 APNs
    case receive = 0
    /// 不会接收到消息，离线不会有推送通知
    case notReceive = 1
    /// 在线正常接收消息，离线不会有推送通知
    case notNotify = 2
}

public class ConversationInfo {
    let conversationID: String
    var userID: String?
    var groupID: String?
    var showName: String?
    var faceURL: String?
    var recvMsgOpt: ReceiveMessageOpt = .receive
    var unreadCount: Int = 0
    var conversationType: ConversationType = .c2c
    var latestMsgSendTime: Int = 0
    var draftText: String?
    var draftTextTime: Int = 0
    var isPinned: Bool = false
    var latestMsg: MessageInfo?
    var ex: String?
    init(conversationID: String) {
        self.conversationID = conversationID
    }
}

public class MessageInfo: Encodable {
    var clientMsgID: String?
    var serverMsgID: String?
    var createTime: TimeInterval = 0
    var sendTime: TimeInterval = 0
    var sessionType: ConversationType = .c2c
    var sendID: String?
    var recvID: String?
    var handleMsg: String?
    var msgFrom: MessageLevel = .user
    var contentType: MessageContentType = .unknown
    var platformID: Int = 0
    var senderNickname: String?
    var senderFaceUrl: String?
    var groupID: String?
    var content: String?
    /// 消息唯一序列号
    var seq: Int = 0
    var isRead: Bool = false
    var status: MessageStatus = .undefine
    var attachedInfo: String?
    var ex: String?
    var offlinePushInfo: OfflinePushInfo = .init()
    var pictureElem: PictureElem?
    var soundElem: SoundElem?
    var videoElem: VideoElem?
    var fileElem: FileElem?
    var mergeElem: MergeElem?
    var atElem: AtElem?
    var locationElem: LocationElem?
    var quoteElem: QuoteElem?
    var customElem: CustomElem?
    var notificationElem: NotificationElem?
    var faceElem: FaceElem?
    var attachedInfoElem: AttachedInfoElem?
    var isPlaying = false

    func getAbstruct() -> String? {
        switch contentType {
        case .text:
            return content
        case .quote:
            return quoteElem?.text
        default:
            return contentType.abstruct
        }
    }
}

public class GroupMemberBaseInfo: Encodable {
    var userID: String?
    var roleLevel: GroupMemberRole = .undefine
}

public enum GroupMemberRole: Int, Encodable {
    case undefine = 0
    case member = 1
    /// 群主
    case `super` = 2
    case admin = 3
}

public class GroupMemberInfo: GroupMemberBaseInfo {
    var groupID: String?
    var nickname: String?
    var faceURL: String?
    var joinTime: Int = 0
    var joinSource: JoinSource = .search
    var operatorUserID: String?
    var ex: String?

    var isSelf: Bool {
        return userID == IMController.shared.uid
    }
}

public enum MessageContentType: Int, Codable {
    case unknown = -1

    // MARK: 消息类型

    case text = 101
    case image
    case audio
    case video
    case file
    /// @消息
    case at
    /// 合并消息
    case merge
    /// 名片消息
    case card
    case location
    case custom
    /// 撤回消息回执
    case revokeReciept
    /// C2C单聊已读回执
    case C2CReciept
    /// 正在输入状态
    case typing
    case quote
    /// 动图消息
    case face

    // MARK: 通知类型

    case friendAppApproved = 1201
    case friendAppRejected
    case friendApplication
    case friendAdded
    case friendDeleted
    /// 设置好友备注通知
    case friendRemarkSet
    case blackAdded
    case blackDeleted
    /// 会话免打扰设置通知
    case conversationOptChange = 1300
    case userInfoUpdated = 1303
    /// 会话通知
    case conversationNotification = 1307
    /// 会话不通知
    case conversationNotNotification
    case groupCreated = 1501
    /// 更新群信息通知
    case groupInfoSet
    case joinGroupApplication
    case memberQuit
    case groupAppAccepted
    case groupAppRejected
    /// 群主更换通知
    case groupOwnerTransferred
    case memberKicked
    case memberInvited
    case memberEnter
    /// 解散群通知
    case dismissGroup
    /// 阅后即焚
    case privateMessage

    var abstruct: String? {
        switch self {
        case .image:
            return "[图片]"
        case .audio:
            return "[语音]"
        case .video:
            return "[视频]"
        case .file:
            return "[文件]"
        case .card:
            return "[名片]"
        case .location:
            return "[定位]"
        case .face:
            return "[自定义表情]"
        default:
            return nil
        }
    }
}

public enum MessageStatus: Int, Codable {
    case undefine = 0
    case sending
    case sendSuccess
    case sendFailure
    case deleted
    case revoke
}

public enum MessageLevel: Int, Codable {
    case undefine = -1
    case user = 100
    case system = 200
}

public enum ConversationType: Int, Codable {
    /// 未定义
    case undefine
    /// 单聊
    case c2c
    /// 群聊
    case group
    /// 大群
    case superGroup
    /// 通知
    case notification
}

public enum GroupType: Int, Codable {
    case normal = 0
    case `super` = 1
    case working = 2
}

public enum JoinSource: Int, Codable {
    case invited = 2 /// 通过邀请
    case search = 3 /// 通过搜索
    case QRCode = 4 /// 通过二维码
}

public class GroupBaseInfo: Encodable {
    var groupName: String?
    var introduction: String?
    var notification: String?
    var faceURL: String?
}

public class GroupInfo: GroupBaseInfo {
    var groupID: String = ""
    var ownerUserID: String?
    var createTime: Int = 0
    var memberCount: Int = 0
    var creatorUserID: String?
    var groupType: GroupType = .working

    var isSelf: Bool {
        return creatorUserID == IMController.shared.uid
    }
}

public class ConversationNotDisturbInfo {
    let conversationId: String
    var result: ReceiveMessageOpt = .receive
    init(conversationId: String) {
        self.conversationId = conversationId
    }
}

// MARK: 次要模型

public class FaceElem: Encodable {
    var index: Int = 0
    var data: String?
}

public class AttachedInfoElem: Encodable {
    var groupHasReadInfo: GroupHasReadInfo?
}

public class GroupHasReadInfo: Encodable {
    var hasReadUserIDList: [String]?
    var hasReadCount: Int = 0
}

public class NotificationElem: Encodable {
    var detail: String?
    var defaultTips: String?
    private(set) var opUser: GroupMemberInfo?
    private(set) var quitUser: GroupMemberInfo?
    private(set) var entrantUser: GroupMemberInfo?
    /// 群改变新群主的信息
    private(set) var groupNewOwner: GroupMemberInfo?
    private(set) var group: GroupInfo?
    private(set) var kickedUserList: [GroupMemberInfo]?
    private(set) var invitedUserList: [GroupMemberInfo]?
    init(opUser: GroupMemberInfo?, quitUser: GroupMemberInfo?, entrantUser: GroupMemberInfo?, groupNewOwner: GroupMemberInfo?, group: GroupInfo?, kickedUserList: [GroupMemberInfo]?, invitedUserList: [GroupMemberInfo]?) {
        self.opUser = opUser
        self.quitUser = quitUser
        self.entrantUser = entrantUser
        self.groupNewOwner = groupNewOwner
        self.group = group
        self.kickedUserList = kickedUserList
        self.invitedUserList = invitedUserList
    }
}

public class OfflinePushInfo: Codable {
    var title: String?
    var desc: String?
    var iOSPushSound: String?
    var iOSBadgeCount: Bool = false
    var operatorUserID: String?
    var ex: String?
}

public class PictureElem: Codable {
    /// 本地资源地址
    var sourcePath: String?
    /// 本地图片详情
    var sourcePicture: PictureInfo?
    /// 大图详情
    var bigPicture: PictureInfo?
    /// 缩略图详情
    var snapshotPicture: PictureInfo?
}

public class PictureInfo: Codable {
    var uuID: String?
    var type: String?
    var size: Int = 0
    var width: CGFloat = 0
    var height: CGFloat = 0
    /// 图片oss地址
    var url: String?
}

public class SoundElem: Codable {
    var uuID: String?
    /// 本地资源地址
    var soundPath: String?
    /// oss地址
    var sourceUrl: String?
    var dataSize: Int = 0
    var duration: Int = 0
}

public class VideoElem: Codable {
    var videoUUID: String?
    var videoPath: String?
    var videoUrl: String?
    var videoType: String?
    var videoSize: Int = 0
    var duration: Int = 0
    /// 视频快照本地地址
    var snapshotPath: String?
    /// 视频快照唯一ID
    var snapshotUUID: String?
    var snapshotSize: Int = 0
    /// 视频快照oss地址
    var snapshotUrl: String?
    var snapshotWidth: CGFloat = 0
    var snapshotHeight: CGFloat = 0
}

public class FileElem: Encodable {
    var filePath: String?
    var uuID: String?
    /// oss地址
    var sourceUrl: String?
    var fileName: String?
    var fileSize: Int = 0
}

public class MergeElem: Encodable {
    var title: String?
    var abstractList: [String]?
    var multiMessage: [MessageInfo]?
}

public class AtElem: Encodable {
    var text: String?
    var atUserList: [String]?
    var atUsersInfo: [AtInfo]?
    var quoteMessage: QuoteElem?
    var isAtSelf: Bool = false
}

public class AtInfo: Encodable {
    var atUserID: String?
    var groupNickname: String?
}

public class LocationElem: Encodable {
    var desc: String?
    var longitude: Double = 0
    var latitude: Double = 0
}

public class QuoteElem: Encodable {
    var text: String?
    var quoteMessage: MessageInfo?
}

public class CustomElem: Encodable {
    var data: String?
    var ext: String?
    var description: String?
}

struct BusinessCard: Codable {
    let faceURL: String?
    let nickname: String?
    let userID: String
}

class ReceiptInfo {
    var userID: String?
    var groupID: String?
    /// 已读消息id
    var msgIDList: [String]?
    var readTime: Int = 0
    var msgFrom: MessageLevel = .user
    var contentType: MessageContentType = .C2CReciept
    var sessionType: ConversationType = .undefine
}

class FullUserInfo {
    var publicInfo: PublicUserInfo?
    var friendInfo: FriendInfo?
    var blackInfo: BlackInfo?

    var userID: String?
    var showName: String?
    var faceURL: String?
    var gender: Gender = .male
}

public enum Gender: Int, Encodable {
    case undefine = -1
    case male = 0
    case female = 1

    public var description: String {
        switch self {
        case .male:
            return "男".innerLocalized()
        case .female:
            return "女".innerLocalized()
        case .undefine:
            return "保密".innerLocalized()
        }
    }
}

public class PublicUserInfo {
    var userID: String?
    var nickname: String?
    var faceURL: String?
    var gender: Gender = .male
}

class FriendInfo: PublicUserInfo {
    var ownerUserID: String?
    var remark: String?
    var createTime: Int = 0
    var addSource: Int = 0
    var operatorUserID: String?
    var phoneNumber: String?
    var birth: Int = 0
    var email: String?
    var attachedInfo: String?
    var ex: String?
}

public class BlackInfo: PublicUserInfo {
    var operatorUserID: String?
    var createTime: Int = 0
    var addSource: Int = 0
    var attachedInfo: String?
    var ex: String?
}

class SearchParam {
    var conversationID: String = ""
    var keywordList: [String] = []
    var messageTypeList: [MessageContentType]?
    var searchTimePosition: Int = 0
    var searchTimePeriod: Int = 0
    var pageIndex: Int = 1
    var count: Int = 100
}

class SearchResultInfo {
    var totalCount: Int = 0
    var searchResultItems: [SearchResultItemInfo] = []
}

class SearchResultItemInfo {
    var conversationID: String = ""
    var messageCount: Int = 0
    var messageList: [MessageInfo] = []
}

// MARK: - 模型转换(From SDK)

extension MessageInfo {
    func toOIMMessageInfo() -> OIMMessageInfo {
        let json: String = JsonTool.toJson(fromObject: self)
        if let item = OIMMessageInfo.mj_object(withKeyValues: json) {
            return item
        }
        return OIMMessageInfo()
    }

    var isSelf: Bool {
        return sendID == IMController.shared.uid
    }
}

extension MessageContentType {
    func toOIMMessageContentType() -> OIMMessageContentType {
        let type = OIMMessageContentType(rawValue: rawValue) ?? OIMMessageContentType.text
        return type
    }
}

extension OIMGroupInfo {
    func toGroupInfo() -> GroupInfo {
        let item = GroupInfo()
        item.groupID = groupID ?? ""
        item.faceURL = faceURL
        item.createTime = createTime
        item.creatorUserID = creatorUserID
        item.memberCount = memberCount
        item.ownerUserID = ownerUserID
        item.introduction = introduction
        item.notification = notification
        item.groupName = groupName
        item.groupType = GroupType(rawValue: groupType.rawValue) ?? .working
        return item
    }
}

extension OIMUserInfo {
    func toUserInfo() -> UserInfo {
        let item = UserInfo()
        item.faceURL = faceURL
        item.nickname = nickname
        item.userID = userID ?? ""
        item.gender = Gender(rawValue: gender?.intValue ?? 0)
        item.phoneNumber = phoneNumber
        item.birth = birth?.intValue
        item.email = email
        item.createTime = createTime
        item.ex = ex
        return item
    }
}

extension OIMGroupApplicationInfo {
    func toGroupApplicationInfo() -> GroupApplicationInfo {
        let item = GroupApplicationInfo()
        item.groupID = groupID ?? ""
        item.groupName = groupName
        item.groupFaceURL = groupFaceURL
        item.creatorUserID = creatorUserID ?? ""
        item.ownerUserID = ownerUserID ?? ""
        item.memberCount = memberCount
        item.userID = userID
        item.nickname = nickname
        item.userFaceURL = userFaceURL
        item.reqMsg = reqMsg
        item.reqTime = reqTime
        item.handleUserID = handleUserID
        item.handledMsg = handledMsg
        item.handledTime = handledTime
        item.handleResult = ApplicationStatus(rawValue: handleResult.rawValue) ?? .normal
        return item
    }
}

extension OIMFriendApplication {
    func toFriendApplication() -> FriendApplication {
        let item = FriendApplication()
        item.fromUserID = fromUserID ?? ""
        item.fromNickname = fromNickname
        item.fromFaceURL = fromFaceURL
        item.toUserID = toUserID ?? ""
        item.toNickname = toNickname
        item.toFaceURL = toFaceURL
        item.handleResult = ApplicationStatus(rawValue: handleResult.rawValue) ?? .normal
        // 注意此处值类型的不对应
        item.reqMsg = ex
        item.handlerUserID = handlerUserID
        item.handleMsg = handleMsg
        item.handleTime = handleTime
        return item
    }
}

extension OIMFullUserInfo {
    func toUserInfo() -> UserInfo {
        let item = UserInfo()
        item.faceURL = faceURL
        // 注意此处值类型的不对应
        item.nickname = showName
        item.userID = userID ?? ""
        return item
    }
}

extension OIMConversationInfo {
    func toConversationInfo() -> ConversationInfo {
        let item = ConversationInfo(conversationID: conversationID ?? "")
        item.userID = userID
        item.groupID = groupID
        item.showName = showName
        item.faceURL = faceURL
        item.recvMsgOpt = recvMsgOpt.toReceiveMessageOpt()
        item.unreadCount = unreadCount
        item.conversationType = conversationType.toConversationType()
        item.latestMsgSendTime = latestMsgSendTime
        item.draftText = draftText
        item.draftTextTime = draftTextTime
        item.isPinned = isPinned
        item.latestMsg = latestMsg?.toMessageInfo()
        item.ex = ex
        return item
    }
}

extension OIMMessageInfo {
    func toMessageInfo() -> MessageInfo {
        let item = MessageInfo()
        item.clientMsgID = clientMsgID
        item.serverMsgID = serverMsgID
        item.createTime = createTime
        item.sendTime = sendTime
        item.sessionType = sessionType.toConversationType()
        item.sendID = sendID
        item.recvID = recvID
        item.handleMsg = handleMsg
        item.msgFrom = msgFrom.toMessageLevel()
        item.contentType = contentType.toMessageContentType()
        item.platformID = platformID
        item.senderNickname = senderNickname
        item.senderFaceUrl = senderFaceUrl
        item.groupID = groupID
        item.content = content
        item.seq = seq
        item.isRead = isRead
        item.status = status.toMessageStatus()
        item.attachedInfo = attachedInfo
        item.ex = ex
        item.offlinePushInfo = offlinePush.toOfflinePushInfo()
        item.pictureElem = pictureElem?.toPictureElem()
        item.soundElem = soundElem?.toSoundElem()
        item.videoElem = videoElem?.toVideoElem()
        item.fileElem = fileElem?.toFileElem()
        item.mergeElem = mergeElem?.toMergeElem()
        item.atElem = atElem?.toAtElem()
        item.locationElem = locationElem?.toLocationElem()
        item.quoteElem = quoteElem?.toQuoteElem()
        item.customElem = customElem?.toCustomElem()
        item.notificationElem = notificationElem?.toNotificationElem()
        item.faceElem = faceElem?.toFaceElem()
        item.attachedInfoElem = attachedInfoElem?.toAttachedInfoElem()
        return item
    }
}

extension OIMReceiveMessageOpt {
    func toReceiveMessageOpt() -> ReceiveMessageOpt {
        switch self {
        case .receive:
            return .receive
        case .notReceive:
            return .notReceive
        case .notNotify:
            return .notNotify
        }
    }
}

extension OIMConversationType {
    func toConversationType() -> ConversationType {
        switch self {
        case .undefine:
            return .undefine
        case .C2C:
            return .c2c
        case .group:
            return .group
        case .superGroup:
            return .superGroup
        case .notification:
            return .notification
        default:
            return .undefine
        }
    }
}

extension OIMMessageLevel {
    func toMessageLevel() -> MessageLevel {
        switch self {
        case .user:
            return .user
        case .system:
            return .system
        default:
            return .undefine
        }
    }
}

extension OIMMessageContentType {
    func toMessageContentType() -> MessageContentType {
        let item = MessageContentType(rawValue: rawValue) ?? MessageContentType.unknown
        return item
    }
}

extension OIMMessageStatus {
    func toMessageStatus() -> MessageStatus {
        switch self {
        case .undefine:
            return .undefine
        case .sending:
            return .sending
        case .sendSuccess:
            return .sendSuccess
        case .sendFailure:
            return .sendFailure
        case .deleted:
            return .deleted
        case .revoke:
            return .revoke
        @unknown
        default:
            return .undefine
        }
    }
}

extension OIMOfflinePushInfo {
    func toOfflinePushInfo() -> OfflinePushInfo {
        let item = OfflinePushInfo()
        item.title = title
        item.desc = desc
        item.iOSPushSound = iOSPushSound
        item.iOSBadgeCount = iOSBadgeCount
        item.operatorUserID = operatorUserID
        item.ex = ex
        return item
    }
}

extension OIMPictureElem {
    func toPictureElem() -> PictureElem {
        let item = PictureElem()
        item.sourcePath = sourcePath
        item.sourcePicture = sourcePicture?.toPictureInfo()
        item.bigPicture = bigPicture?.toPictureInfo()
        item.snapshotPicture = snapshotPicture?.toPictureInfo()
        return item
    }
}

extension OIMPictureInfo {
    func toPictureInfo() -> PictureInfo {
        let item = PictureInfo()
        item.uuID = uuID
        item.type = type
        item.size = size
        item.width = width
        item.height = height
        item.url = url
        return item
    }
}

extension OIMSoundElem {
    func toSoundElem() -> SoundElem {
        let item = SoundElem()
        item.uuID = uuID
        item.soundPath = soundPath
        item.sourceUrl = sourceUrl
        item.dataSize = dataSize
        item.duration = duration
        return item
    }
}

extension OIMVideoElem {
    func toVideoElem() -> VideoElem {
        let item = VideoElem()
        item.videoUUID = videoUUID
        item.videoPath = videoPath
        item.videoUrl = videoUrl
        item.videoType = videoType
        item.videoSize = videoSize
        item.duration = duration
        item.snapshotPath = snapshotPath
        item.snapshotUUID = snapshotUUID
        item.snapshotSize = snapshotSize
        item.snapshotUrl = snapshotUrl
        item.snapshotWidth = snapshotWidth
        item.snapshotHeight = snapshotHeight
        return item
    }
}

extension OIMFileElem {
    func toFileElem() -> FileElem {
        let item = FileElem()
        item.uuID = uuID
        item.filePath = filePath
        item.sourceUrl = sourceUrl
        item.fileName = fileName
        item.fileSize = fileSize
        return item
    }
}

extension OIMMergeElem {
    func toMergeElem() -> MergeElem {
        let item = MergeElem()
        item.title = title
        item.abstractList = abstractList
        item.multiMessage = multiMessage?.compactMap { $0.toMessageInfo() }
        return item
    }
}

extension OIMAtElem {
    func toAtElem() -> AtElem {
        let item = AtElem()
        item.text = text
        item.atUserList = atUserList
        item.atUsersInfo = atUsersInfo?.compactMap { $0.toAtInfo() }
        item.isAtSelf = isAtSelf
        return item
    }
}

extension OIMAtInfo {
    func toAtInfo() -> AtInfo {
        let item = AtInfo()
        item.atUserID = atUserID
        item.groupNickname = groupNickname
        return item
    }
}

extension OIMLocationElem {
    func toLocationElem() -> LocationElem {
        let item = LocationElem()
        item.desc = desc
        item.longitude = longitude
        item.latitude = latitude
        return item
    }
}

extension OIMQuoteElem {
    func toQuoteElem() -> QuoteElem {
        let item = QuoteElem()
        item.text = text
        item.quoteMessage = quoteMessage?.toMessageInfo()
        return item
    }
}

extension OIMCustomElem {
    func toCustomElem() -> CustomElem {
        let item = CustomElem()
        item.data = data
        item.ext = self.extension
        item.description = description
        return item
    }
}

extension OIMFaceElem {
    func toFaceElem() -> FaceElem {
        let item = FaceElem()
        item.index = index
        item.data = data
        return item
    }
}

extension OIMAttachedInfoElem {
    func toAttachedInfoElem() -> AttachedInfoElem {
        let item = AttachedInfoElem()
        item.groupHasReadInfo = groupHasReadInfo?.toGroupHasReadInfo()
        return item
    }
}

extension OIMGroupHasReadInfo {
    func toGroupHasReadInfo() -> GroupHasReadInfo {
        let item = GroupHasReadInfo()
        item.hasReadCount = hasReadCount
        item.hasReadUserIDList = hasReadUserIDList
        return item
    }
}

extension OIMNotificationElem {
    func toNotificationElem() -> NotificationElem {
        let item = NotificationElem(opUser: opUser?.toGroupMemberInfo(),
                                    quitUser: quitUser?.toGroupMemberInfo(),
                                    entrantUser: entrantUser?.toGroupMemberInfo(),
                                    groupNewOwner: groupNewOwner?.toGroupMemberInfo(),
                                    group: group?.toGroupInfo(),
                                    kickedUserList: kickedUserList?.compactMap { $0.toGroupMemberInfo() },
                                    invitedUserList: invitedUserList?.compactMap { $0.toGroupMemberInfo() })
        item.detail = detail
        item.defaultTips = defaultTips
        return item
    }
}

extension OIMGroupMemberInfo {
    func toGroupMemberInfo() -> GroupMemberInfo {
        let item = GroupMemberInfo()
        item.userID = userID
        item.roleLevel = roleLevel.toGroupMemberRole()
        item.groupID = groupID
        item.nickname = nickname
        item.faceURL = faceURL
        item.joinTime = joinTime
        item.joinSource = JoinSource(rawValue: Int(joinSource.rawValue)) ?? .search
        item.operatorUserID = operatorUserID
        item.ex = ex
        return item
    }
}

extension OIMGroupMemberRole {
    func toGroupMemberRole() -> GroupMemberRole {
        switch self {
        case .undefine:
            return .undefine
        case .member:
            return .member
        case .super:
            return .super
        case .admin:
            return .admin
        }
    }
}

extension OIMConversationNotDisturbInfo {
    func toConversationNotDisturbInfo() -> ConversationNotDisturbInfo {
        let item = ConversationNotDisturbInfo(conversationId: conversationID ?? "")
        item.result = result.toReceiveMessageOpt()
        return item
    }
}

extension OIMReceiptInfo {
    func toReceiptInfo() -> ReceiptInfo {
        let item = ReceiptInfo()
        item.userID = userID
        item.groupID = groupID
        item.msgIDList = msgIDList
        item.readTime = readTime
        item.msgFrom = msgFrom.toMessageLevel()
        item.contentType = contentType.toMessageContentType()
        item.sessionType = sessionType.toConversationType()
        return item
    }
}

extension OIMFullUserInfo {
    func toFullUserInfo() -> FullUserInfo {
        let item = FullUserInfo()
        item.blackInfo = blackInfo?.toBlackInfo()
        item.friendInfo = friendInfo?.toFriendInfo()
        item.publicInfo = publicInfo?.toPublicUserInfo()
        item.userID = userID
        item.showName = showName
        item.faceURL = faceURL
        item.gender = Gender(rawValue: gender.rawValue) ?? .male
        return item
    }
}

extension OIMBlackInfo {
    func toBlackInfo() -> BlackInfo {
        let item = BlackInfo()
        item.operatorUserID = operatorUserID
        item.createTime = createTime
        item.addSource = addSource
        item.userID = userID
        item.faceURL = faceURL
        item.nickname = nickname
        item.attachedInfo = attachedInfo
        item.ex = ex
        return item
    }
}

extension OIMFriendInfo {
    func toFriendInfo() -> FriendInfo {
        let item = FriendInfo()
        item.nickname = nickname
        item.faceURL = faceURL
        item.userID = userID
        item.ownerUserID = ownerUserID
        item.remark = remark
        item.createTime = createTime
        item.addSource = addSource
        item.operatorUserID = operatorUserID
        item.phoneNumber = phoneNumber
        item.birth = birth
        item.email = email
        item.attachedInfo = attachedInfo
        item.ex = ex
        return item
    }
}

extension OIMPublicUserInfo {
    func toPublicUserInfo() -> PublicUserInfo {
        let item = PublicUserInfo()
        item.userID = userID
        item.nickname = nickname
        item.faceURL = faceURL
        item.gender = Gender(rawValue: gender.rawValue) ?? .male
        return item
    }
}

extension OIMSearchResultInfo {
    func toSearchResultInfo() -> SearchResultInfo {
        let item = SearchResultInfo()
        item.totalCount = totalCount
        item.searchResultItems = searchResultItems.compactMap { $0.toSearchResultItemInfo() }
        return item
    }
}

extension OIMSearchResultItemInfo {
    func toSearchResultItemInfo() -> SearchResultItemInfo {
        let item = SearchResultItemInfo()
        item.conversationID = conversationID
        item.messageCount = messageCount
        item.messageList = messageList.compactMap { $0.toMessageInfo() }
        return item
    }
}

// MARK: - 模型转换(From OIMUIKit)

extension UserInfo {
    func toOIMUserInfo() -> OIMUserInfo {
        let json = JsonTool.toJson(fromObject: self)
        if let item = OIMUserInfo.mj_object(withKeyValues: json) {
            return item
        }
        return OIMUserInfo()
    }
}

extension GroupBaseInfo {
    func toOIMGroupBaseInfo() -> OIMGroupBaseInfo {
        let item = OIMGroupBaseInfo()
        item.faceURL = faceURL
        item.groupName = groupName
        item.introduction = introduction
        return item
    }
}

extension SearchParam {
    func toOIMSearchParam() -> OIMSearchParam {
        let item = OIMSearchParam()
        item.conversationID = conversationID
        item.keywordList = keywordList
        item.messageTypeList = messageTypeList?.compactMap { $0.rawValue }
        item.searchTimePeriod = searchTimePeriod
        item.searchTimePosition = searchTimePosition
        item.pageIndex = pageIndex
        item.count = count
        return item
    }
}
