
import Foundation
import IQKeyboardManagerSwift
import OpenIMSDK
import RxCocoa
import RxSwift
import UIKit
import AudioToolbox

// -1 链接失败 0 链接中 1 链接成功 2 同步开始 3 同步结束 4 同步错误
public enum ConnectionStatus: Int {
    case connectFailure = 0
    case connecting = 1
    case connected = 2
    case syncStart = 3
    case syncComplete = 4
    case syncFailure = 5
    case kickedOffline = 6
    
    public var title: String {
        switch self {
        case .connectFailure:
            return "连接失败"
        case .connecting:
            return "连接中".innerLocalized()
        case .connected:
            return "连接成功".innerLocalized()
        case .syncStart:
            return "同步开始".innerLocalized()
        case .syncComplete:
            return "同步完成".innerLocalized()
        case .syncFailure:
            return "同步失败".innerLocalized()
        case .kickedOffline:
            return "账号在其它设备登录".innerLocalized()
        }
    }
}

public enum SDKError: Int {
    case blockedByFriend = 600 // 被对方拉黑
    case deletedByFriend = 601 // 被对方删除
    case refuseToAddFriends = 10007 // 该用户已设置不可添加
}

public enum CustomMessageType: Int {
    case call = 901 // 音视频
    case customEmoji = 902 // emoji
    case tagMessage = 903 // 标签消息
    case moments = 904 // 朋友圈
    case meeting = 905 // 会议
    case blockedByFriend = 910 // 被拉黑
    case deletedByFriend = 911 // 被删除
}

public class IMController: NSObject {
    public static let addFriendPrefix = "io.openim.app/addFriend/"
    public static let joinGroupPrefix = "io.openim.app/joinGroup/"
    public static let shared: IMController = .init()
    private(set) var imManager: OpenIMSDK.OIMManager!
    /// 好友申请列表新增
    public let friendApplicationChangedSubject: PublishSubject<FriendApplication> = .init()
    /// 组申请信息更新
    public let groupApplicationChangedSubject: PublishSubject<GroupApplicationInfo> = .init()
    public let groupInfoChangedSubject: PublishSubject<GroupInfo> = .init()
    public let contactUnreadSubject: PublishSubject<Int> = .init()
    
    public let conversationChangedSubject: BehaviorSubject<[ConversationInfo]> = .init(value: [])
    public let friendInfoChangedSubject: BehaviorSubject<FriendInfo?> = .init(value: nil)
    
    public let onBlackAddedSubject: BehaviorSubject<BlackInfo?> = .init(value: nil)
    public let onBlackDeletedSubject: BehaviorSubject<BlackInfo?> = .init(value: nil)
    
    public let newConversationSubject: BehaviorSubject<[ConversationInfo]> = .init(value: [])
    public let totalUnreadSubject: BehaviorSubject<Int> = .init(value: 0)
    public let newMsgReceivedSubject: PublishSubject<MessageInfo> = .init()
    public let c2cReadReceiptReceived: BehaviorSubject<[ReceiptInfo]> = .init(value: [])
    public let groupReadReceiptReceived: BehaviorSubject<[ReceiptInfo]> = .init(value: [])
    public let groupMemberInfoChange: BehaviorSubject<GroupMemberInfo?> = .init(value: nil)
    public let joinedGroupAdded: BehaviorSubject<GroupInfo?> = .init(value: nil)
    public let joinedGroupDeleted: BehaviorSubject<GroupInfo?> = .init(value: nil)
    public let msgRevokeReceived: PublishSubject<MessageRevoked> = .init()
    public let currentUserRelay: BehaviorRelay<UserInfo?> = .init(value: nil)
    public let momentsReceivedSubject: PublishSubject<String?> = .init()
    public let meetingStreamChange: PublishSubject<MeetingStreamEvent> = .init()
    public let organizationUpdated: PublishSubject<String?> = .init()
    // 连接状态
    public let connectionRelay: BehaviorRelay<ConnectionStatus> = .init(value: .connecting)
    
    public var uid: String = ""
    public var token: String = ""
    // 查询在线状态等使用
    public var sdkAPIAdrr = ""
    // 业务层查询组织架构等使用
    public var businessServer = ""
    public var businessToken: String?
    // 上次响铃时间
    private var remindTimeStamp: Double = NSDate().timeIntervalSince1970
    // 开启响铃
    public var enableRing = true
    // 开启震动
    public var enableVibration = true
    
    // 设置业务服务器的参数
    public func setup(businessServer: String, businessToken: String?) {
        self.businessServer = businessServer
        self.businessToken = businessToken
    }
    
    public func setup(sdkAPIAdrr: String, sdkWSAddr: String, sdkOS: String, onKickedOffline: (() -> Void)? = nil) {
        self.sdkAPIAdrr = sdkAPIAdrr
        let manager = OIMManager.manager
        
        var config = OIMInitConfig()
        config.apiAddr = sdkAPIAdrr
        config.wsAddr = sdkWSAddr
        config.objectStorage = sdkOS
        config.logLevel = 3
        
        manager.initSDK(with: config) { [weak self] in
            self?.connectionRelay.accept(.connecting)
        } onConnectFailure: { [weak self] code, msg in
            print("onConnectFailed code:\(code), msg:\(String(describing: msg))")
            self?.connectionRelay.accept(.connectFailure)
        } onConnectSuccess: {[weak self] in
            print("onConnectSuccess")
            self?.connectionRelay.accept(.connected)
        } onKickedOffline: {[weak self] in
            print("onKickedOffline")
            onKickedOffline?()
            self?.connectionRelay.accept(.kickedOffline)
        } onUserTokenExpired: {
            print("onUserTokenExpired")
        }
        
        Self.shared.imManager = manager
        // Set listener
        OpenIMSDK.OIMManager.callbacker.addFriendListener(listener: self)
        OpenIMSDK.OIMManager.callbacker.addGroupListener(listener: self)
        OpenIMSDK.OIMManager.callbacker.addConversationListener(listener: self)
        OpenIMSDK.OIMManager.callbacker.addAdvancedMsgListener(listener: self)
        
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
        //        IQKeyboardManager.shared.disabledDistanceHandlingClasses = [
        //            MessageListViewController.self,
        //        ]
        //        IQKeyboardManager.shared.disabledToolbarClasses = [
        //            MessageListViewController.self,
        //        ]
        //        IQKeyboardManager.shared.disabledTouchResignedClasses = [
        //            SearchResultViewController.self,
        //            SearchFriendViewController.self,
        //            SearchGroupViewController.self,
        //        ]
    }
    
    public func login(uid: String, token: String, onSuccess: @escaping (String?) -> Void, onFail: @escaping (Int, String?) -> Void) {
        Self.shared.imManager.login(uid, token: token) { [weak self] (resp: String?) in
            self?.uid = uid
            self?.token = token
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
    
    public typealias MessagesCallBack = ([MessageInfo]) -> Void
    public typealias SeqMessagesCallBack = (Int, [MessageInfo]) -> Void
    
    // 正在聊天的会话不响铃
    public var chatingConversationID: String = ""
    
    // 响铃或者震动
    func ringAndVibrate() {
        if NSDate().timeIntervalSince1970 - remindTimeStamp >= 1 { // 响铃间隔1秒钟
            // 如果当前会话有
            // 新消息铃声
            if enableRing {
                var theSoundID : SystemSoundID = 0
                let url = URL(fileURLWithPath: "/System/Library/Audio/UISounds/nano/sms-received1.caf")
                let urlRef = url as CFURL
                let err = AudioServicesCreateSystemSoundID(urlRef, &theSoundID)
                
                if err == kAudioServicesNoError {
                    AudioServicesPlaySystemSoundWithCompletion(theSoundID, {
                        AudioServicesDisposeSystemSoundID(theSoundID)
                    })
                }
            }
            // 新消息震动
            if enableVibration {
                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
            }
            remindTimeStamp = NSDate().timeIntervalSince1970
        }
    }
}

extension String {
    // 将clientMsgID转化成UUID
    var uuid: UUID? {
        var str = self
        
        let index1 = str.index(str.startIndex, offsetBy: 8)
        let index2 = str.index(str.startIndex, offsetBy: 13)
        let index3 = str.index(str.startIndex, offsetBy: 18)
        let index4 = str.index(str.startIndex, offsetBy: 23)
        
        str.insert("-", at: index1)
        str.insert("-", at: index2)
        str.insert("-", at: index3)
        str.insert("-", at: index4)
        
        let uuid = UUID(uuidString: str)
        return uuid
    }
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
    public func getGroupListBy(id: String) -> Observable<String?> {
        return Observable<String?>.create { observer in
            Self.shared.imManager.getSpecifiedGroupsInfo([id], onSuccess: { (groups: [OIMGroupInfo]?) in
                observer.onNext(groups?.first?.groupID)
                observer.onCompleted()
            }, onFailure: { (code: Int, msg: String?) in
                observer.onError(NetError(code: code, message: msg))
            })
            
            return Disposables.create()
        }
    }
    
    public func getJoinedGroupList(completion: @escaping ([GroupInfo]) -> Void) {
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
    public func getFriendsBy(id: String) -> Observable<FullUserInfo?> {
        return Observable<FullUserInfo?>.create { observer in
            Self.shared.imManager.getSpecifiedFriendsInfo([id]) { users in
                observer.onNext(users?.first?.toFullUserInfo())
                observer.onCompleted()
            } onFailure: { (code: Int, msg: String?) in
                observer.onError(NetError(code: code, message: msg))
            }
            return Disposables.create()
        }
    }
    
    public func getFriendsInfo(userIDs: [String], completion: @escaping CallBack.FullUserInfosReturnVoid) {
        Self.shared.imManager.getSpecifiedFriendsInfo(userIDs) { users in
            let r = users?.compactMap({ $0.toFullUserInfo() })
            completion(r ?? [])
        }
    }
    
    /// 获取好友申请列表
    /// - Parameter completion: 申请数组
    public func getFriendApplicationList(completion: @escaping ([FriendApplication]) -> Void) {
        Self.shared.imManager.getFriendApplicationListAsRecipientWith(onSuccess: { (applications: [OIMFriendApplication]?) in
            let arr = applications ?? []
            let ret = arr.compactMap { $0.toFriendApplication() }
            completion(ret)
        })
    }
    
    /// 接受好友申请
    /// - Parameters:
    ///   - uid: 指定好友ID
    ///   - handleMsg: 处理理由
    ///   - completion: 响应消息
    public func acceptFriendApplication(uid: String, handleMsg: String? = nil, completion: @escaping (String?) -> Void) {
        Self.shared.imManager.acceptFriendApplication(uid, handleMsg: handleMsg ?? "") { r in
            completion(nil)
        } onFailure: { code, msg in
            print("接受好友申请,code:\(code), msg: \(msg)")
            completion(msg)
        }
    }
    
    public func refuseFriendApplication(uid: String, handleMsg: String? = nil, completion: @escaping (String?) -> Void) {
        
        Self.shared.imManager.refuseFriendApplication(uid, handleMsg: handleMsg ?? "") { r in
            completion(nil)
        } onFailure: { code, msg in
            print("拒绝好友申请,code:\(code), msg: \(msg)")
            completion(msg)
        }
    }
    
    public func getGroupApplicationList(completion: @escaping ([GroupApplicationInfo]) -> Void) {
        Self.shared.imManager.getGroupApplicationListAsRecipientWith(onSuccess: { (applications: [OIMGroupApplicationInfo]?) in
            let arr = applications ?? []
            let ret = arr.compactMap { $0.toGroupApplicationInfo() }
            completion(ret)
        })
    }
    
    public func getFriendList(completion: @escaping ([FullUserInfo]) -> Void) {
        Self.shared.imManager.getFriendListWith(onSuccess: { friends in
            let arr = friends ?? []
            let ret = arr.compactMap { $0.toFullUserInfo() }
            completion(ret)
        })
    }
    
    public func acceptGroupApplication(groupID: String, fromUserId: String, handleMsg: String? = nil, completion: @escaping (String?) -> Void) {
        
        Self.shared.imManager.acceptGroupApplication(groupID, fromUserId: fromUserId, handleMsg: handleMsg ?? "") { r in
            completion(nil)
        } onFailure: { code, msg in
            print("接受群申请,code:\(code), msg: \(msg)")
            completion(msg)
        }
    }
    
    public func refuseGroupApplication(groupID: String, fromUserId: String, handleMsg: String? = nil, completion: @escaping (String?) -> Void) {
        Self.shared.imManager.refuseGroupApplication(groupID, fromUserId: fromUserId, handleMsg: handleMsg ?? "") { r in
            completion(nil)
        } onFailure: { code, msg in
            print("拒绝群申请,code:\(code), msg: \(msg)")
            completion(msg)
        }
    }
    
    public func getGroupMemberList(groupId: String, filter: GroupMemberFilter = .member, offset: Int, count: Int, onSuccess: @escaping CallBack.GroupMembersReturnVoid) {
        Self.shared.imManager.getGroupMemberList(groupId,
                                                 filter: OIMGroupMemberFilter(rawValue: filter.rawValue)!,
                                                 offset: offset,
                                                 count: count) { (memberInfos: [OIMGroupMemberInfo]?) in
            let members: [GroupMemberInfo] = memberInfos?.compactMap { $0.toGroupMemberInfo() } ?? []
            onSuccess(members)
        }
    }
    
    public func getGroupMembersInfo(groupId: String, uids: [String], onSuccess: @escaping CallBack.GroupMembersReturnVoid) {

        Self.shared.imManager.getSpecifiedGroupMembersInfo(groupId, usersID: uids) { (groupMembers: [OIMGroupMemberInfo]?) in
            let members: [GroupMemberInfo] = groupMembers?.compactMap { $0.toGroupMemberInfo() } ?? []
            onSuccess(members)
        } onFailure: { code, msg in
            print("获取组成员信息失败:\(code),\(msg)")
        }
    }
    
    public func getGroupInfo(groupIds: [String], onSuccess: @escaping CallBack.GroupInfosReturnVoid) {
        Self.shared.imManager.getSpecifiedGroupsInfo(groupIds) { (groupInfos: [OIMGroupInfo]?) in
            let groups: [GroupInfo] = groupInfos?.compactMap { $0.toGroupInfo() } ?? []
            onSuccess(groups)
        } onFailure: { code, msg in
            print("获取组信息失败:\(code), \(msg)")
        }
    }
    
    public func setGroupInfo(group: GroupInfo, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.setGroupInfo(group.toOIMGroupInfo(), onSuccess: onSuccess) { code, msg in
            print("更新群信息失败：\(code), \(msg)")
        }
    }
    
    public func setGroupVerification(groupId: String, type: GroupVerificationType, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.setGroupVerification(groupId, needVerification: OIMGroupVerificationType(rawValue: type.rawValue) ?? .allNeedVerification, onSuccess: onSuccess) { code, msg in
            print("更新群验证失败：\(code), \(msg)")
        }
    }
    
    public func setGroupMemberRoleLevel(groupId: String, userID: String, roleLevel: GroupMemberRole, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.setGroupMemberRoleLevel(groupId, userID: userID, roleLevel: OIMGroupMemberRole(rawValue: roleLevel.rawValue) ?? .member, onSuccess: onSuccess) { code, msg in
            print("设置身份失败：\(code), \(msg)")
        }
    }
    
    public func setGroupMemberNicknameOf(userid: String, inGroupId: String, with name: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.setGroupMemberNickname(inGroupId, userID: userid, groupNickname: name, onSuccess: onSuccess) { code, msg in
            print("设置群成员昵称失败：\(code), \(msg)")
        }
    }
    
    public func transferOwner(groupId: String, to userId: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.transferGroupOwner(groupId, newOwner: userId, onSuccess: onSuccess) { code, msg in
            print("转移拥有者失败：\(code), \(msg)")
        }
    }
    
    public func dismissGroup(id: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.dismissGroup(id, onSuccess: onSuccess) { code, msg in
            print("解散群聊失败:\(code), \(msg)")
        }
    }
    
    public func quitGroup(id: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.quitGroup(id, onSuccess: onSuccess) { code, msg in
            print("退出群聊失败:\(code), \(msg)")
        }
    }
    
    public func joinGroup(id: String, reqMsg: String?, joinSource: JoinSource = .search, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.joinGroup(id, reqMsg: reqMsg, joinSource: OIMJoinType(rawValue: Int32(joinSource.rawValue))!, onSuccess: onSuccess) { code, msg in
            print("加入群聊失败:\(code), \(msg)")
        }
    }
    
    public func inviteUsersToGroup(groupId: String, uids: [String], onSuccess: @escaping CallBack.VoidReturnVoid) {
        Self.shared.imManager.inviteUser(toGroup: groupId, reason: "", usersID: uids) { (_: [OIMSimpleResultInfo]?) in
            onSuccess()
        } onFailure: { code, msg in
            print("邀请好友加入失败：\(code), \(msg)")
        }
    }
    
    public func kickGroupMember(groupId: String, uids: [String], onSuccess: @escaping CallBack.VoidReturnVoid) {
        Self.shared.imManager.kickGroupMember(groupId, reason: "", usersID: uids) { r in
            onSuccess()
        } onFailure: { code, msg in
            print("邀请好友加入失败：\(code), \(msg)")
        }
    }
    
    public func addFriend(uid: String, reqMsg: String?, onSuccess: @escaping CallBack.StringOptionalReturnVoid, onFailure: CallBack.ErrorOptionalReturnVoid? = nil) {
        Self.shared.imManager.addFriend(uid, reqMessage: reqMsg, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    public func deleteFriend(uid: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.deleteFriend(uid, onSuccess: onSuccess)
    }
    
    public func blockUser(uid: String, blocked: Bool, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        if blocked {
            Self.shared.imManager.add(toBlackList: uid, onSuccess: onSuccess)
        } else {
            Self.shared.imManager.remove(fromBlackList: uid, onSuccess: onSuccess)
        }
    }
    
    public func getBlackList(onSuccess: @escaping CallBack.BlackListOptionalReturnVoid) {
        Self.shared.imManager.getBlackListWith { (blackUsers: [OIMBlackInfo]?) in
            let result = (blackUsers ?? []).compactMap { $0.toBlackInfo() }
            onSuccess(result)
        } onFailure: { code, msg in
            print("获取黑名单失败：\(code), \(msg)")
        }
    }
    
    public func removeFromBlackList(uid: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.remove(fromBlackList: uid, onSuccess: onSuccess) { code, msg in
            print("移除黑名单失败：\(code), \(msg)")
        }
    }
    
    public func setFriend(uid: String, remark: String?, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.setFriendRemark(uid, remark: remark, onSuccess: onSuccess) { code, msg in
            print("设置好友备注失败:\(code), \(msg)")
        }
    }
}

// MARK: - 消息方法

extension IMController {
    public func getAllConversationList(completion: @escaping ([ConversationInfo]) -> Void) {
        Self.shared.imManager.getAllConversationListWith { (conversations: [OIMConversationInfo]?) in
            let arr = conversations ?? []
            let ret = arr.compactMap { $0.toConversationInfo() }
            completion(ret)
        }
    }
    
    /// 删除指定会话（服务器和本地均删除）
    public func deleteConversation(conversationID: String, completion: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.deleteConversationAndDeleteAllMsg(conversationID, onSuccess: completion) { code, msg in
            print("清除指定会话失败:\(code) - \(msg)")
        }
    }
    
    public func getTotalUnreadMsgCount(completion: ((Int) -> Void)?) {
        Self.shared.imManager.getTotalUnreadMsgCountWith(onSuccess: completion, onFailure: nil)
    }
    
    public func getConversationRecvMessageOpt(conversationIds: [String], completion: (([ConversationNotDisturbInfo]?) -> Void)?) {
        Self.shared.imManager.getConversationRecvMessageOpt(conversationIds) { (conversationInfos: [OIMConversationNotDisturbInfo]?) in
            let arr = conversationInfos?.compactMap { $0.toConversationNotDisturbInfo() }
            completion?(arr)
        }
    }
    
    public func setConversationRecvMessageOpt(conversationID: String, status: ReceiveMessageOpt, completion: ((String?) -> Void)?) {
        let opt: OIMReceiveMessageOpt
        switch status {
        case .receive:
            opt = .receive
        case .notReceive:
            opt = .notReceive
        case .notNotify:
            opt = .notNotify
        }
        
        Self.shared.imManager.setConversationRecvMessageOpt(conversationID, status: opt, onSuccess: completion) { code, msg in
            print("修改免打扰状态失败:\(code), \(msg)")
        }
    }
    
    public func setGroupLookMemberInfo(id: String, rule: Int, completion: ((String?) -> Void)?) {
        Self.shared.imManager.setGroupLookMemberInfo(id, rule: Int32(rule), onSuccess: completion) { code, msg in
            print("pin conversation failed: \(code), \(msg)")
        }
    }
    
    public func setGroupApplyMemberFriend(id: String, rule: Int, completion: ((String?) -> Void)?) {
        Self.shared.imManager.setGroupApplyMemberFriend(id, rule: Int32(rule), onSuccess: completion) { code, msg in
            print("pin conversation failed: \(code), \(msg)")
        }
    }
    
    public func pinConversation(id: String, isPinned: Bool, completion: ((String?) -> Void)?) {
        Self.shared.imManager.pinConversation(id, isPinned: !isPinned, onSuccess: completion) { code, msg in
            print("pin conversation failed: \(code), \(msg)")
        }
    }
    
    public func changeGroupMute(groupID: String, isMute: Bool, completion: ((String?) -> Void)?) {
        Self.shared.imManager.changeGroupMute(groupID, isMute: isMute, onSuccess: completion) { code, msg in
            print("修改全体禁言状态失败:\(code), \(msg)")
        }
    }
    
    public func changeGroupMemberMute(groupID: String, userID: String, seconds: Int, completion: ((String?) -> Void)?) {
        Self.shared.imManager.changeGroupMemberMute(groupID, userID: userID, mutedSeconds: seconds, onSuccess: completion) { code, msg in
            print("修改禁言状态失败:\(code), \(msg)")
        }
    }
    
    public func getHistoryMessageList(conversationID: String,
                                      conversationType: ConversationType = .c2c,
                                      startCliendMsgId: String?,
                                      lastMinSeq: Int = 0,
                                      count: Int = 50,
                                      completion: @escaping SeqMessagesCallBack) {
        
        let opts = OIMGetAdvancedHistoryMessageListParam()
        opts.conversationID = conversationID
        opts.lastMinSeq = lastMinSeq
        opts.startClientMsgID = startCliendMsgId
        opts.count = count
        
        Self.shared.imManager.getAdvancedHistoryMessageList(opts) { msgListInfo in
            let arr = msgListInfo?.messageList.compactMap({ $0.toMessageInfo() }) ?? []
            completion(msgListInfo?.lastMinSeq ?? 0, arr)
        }
    }
    
    public func getHistoryMessageListReverse(conversationID: String,
                                             conversationType: ConversationType = .c2c,
                                             startCliendMsgId: String?,
                                             lastMinSeq: Int = 0,
                                             count: Int = 50,
                                             completion: @escaping SeqMessagesCallBack) {
        let opts = OIMGetAdvancedHistoryMessageListParam()
        opts.conversationID = conversationID
        opts.lastMinSeq = lastMinSeq
        opts.startClientMsgID = startCliendMsgId
        opts.count = count

        Self.shared.imManager.getAdvancedHistoryMessageListReverse(opts) { msgListInfo in
            let arr = msgListInfo?.messageList.compactMap({ $0.toMessageInfo() }) ?? []
            completion(msgListInfo?.lastMinSeq ?? 0, arr)
        } onFailure: { code, msg in
            print("getHistoryMessageListReverse error: \(code), \(msg)")
        }
    }
    
    public func sendMessage(message: MessageInfo, to recvID: String, conversationType: ConversationType = .c2c, onComplete: @escaping CallBack.MessageReturnVoid) {
        sendHelper(message: message.toOIMMessageInfo(), to: recvID, conversationType: conversationType, onComplete: onComplete)
    }
    
    private func sendHelper(message: OIMMessageInfo,
                            to recvID: String,
                            conversationType: ConversationType,
                            onComplete: @escaping CallBack.MessageReturnVoid) {
        var model = message.toMessageInfo()
        model.isRead = false
        if conversationType == .c2c {
            Self.shared.imManager.sendMessage(message, recvID: recvID, groupID: nil, offlinePushInfo: message.offlinePush) { (newMessage: OIMMessageInfo?) in
                if let respMessage = newMessage {
                    onComplete(respMessage.toMessageInfo())
                } else {
                    model.status = .sendSuccess
                    onComplete(model)
                }
            } onProgress: { (progress: Int) in
                print("sending message progress: \(progress)")
            } onFailure: { [weak self] (errCode: Int, msg: String?) in
                print("send message error:", msg)
                var customMessage: MessageInfo?
                
                if conversationType == .c2c {
                    if errCode == SDKError.blockedByFriend.rawValue {
                        customMessage = self?.createCustomMessage(customType: .blockedByFriend, data: [:])
                    } else if errCode == SDKError.deletedByFriend.rawValue {
                        customMessage = self?.createCustomMessage(customType: .deletedByFriend, data: [:])
                    }
                }
                model.status = .sendFailure
                onComplete(model)
                
                if customMessage != nil {
                    Self.shared.imManager.insertSingleMessage(toLocalStorage: customMessage!.toOIMMessageInfo(), recvID: recvID, sendID: model.sendID, onSuccess: nil, onFailure: nil)
                    customMessage?.recvID = recvID
                    print("type:\(customMessage?.customElem?.type)")
                    onComplete(customMessage!)
                }
            }
        }
        
        if conversationType == .group || conversationType == .superGroup {
            Self.shared.imManager.sendMessage(message, recvID: nil, groupID: recvID, offlinePushInfo: message.offlinePush) { (newMessage: OIMMessageInfo?) in
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
    
    private func sendOIMMessage(message: OIMMessageInfo,
                                to recvID: String,
                                conversationType: ConversationType,
                                onComplete: @escaping CallBack.MessageReturnVoid) {
        
        let model = message.toMessageInfo()
        
        if let desc = model.offlinePushInfo.desc, desc.isEmpty {
            let push = OfflinePushInfo()
            push.title = "你收到了一条消息"
            push.desc = "你收到了一条消息"
            message.offlinePush = push.toOIMOfflinePushInfo()
        }
        
        model.isRead = false
        sendHelper(message: message, to: recvID, conversationType: conversationType, onComplete: onComplete)
    }
    
    public func typingStatusUpdate(recvID: String, msgTips: String) {
        Self.shared.imManager.typingStatusUpdate(recvID, msgTip: msgTips, onSuccess: nil)
    }
    
    public func sendTextMessage(text: String,
                                quoteMessage: MessageInfo? = nil,
                                to recvID: String,
                                conversationType: ConversationType,
                                sending: CallBack.MessageReturnVoid,
                                onComplete: @escaping CallBack.MessageReturnVoid) {
        let message: OIMMessageInfo
        if let quoteMessage = quoteMessage {
            let quote = quoteMessage.toOIMMessageInfo()
            message = OIMMessageInfo.createQuoteMessage(text, message: quote)
        } else {
            message = OIMMessageInfo.createTextMessage(text)
        }
        message.status = .sending
        sending(message.toMessageInfo())
        sendOIMMessage(message: message, to: recvID, conversationType: conversationType, onComplete: onComplete)
    }
    
    public func createAtAllFlag(displayText: String) -> AtInfo {
        let all = OIMMessageInfo.create(atAllFlag: displayText)
        
        return all.toAtInfo()
    }
    
    public func sendAtTextMessage(text: String,
                                  atUsers: [AtInfo] = [],
                                  quoteMessage: MessageInfo? = nil,
                                  to recvID: String,
                                  conversationType: ConversationType,
                                  sending: CallBack.MessageReturnVoid,
                                  onComplete: @escaping CallBack.MessageReturnVoid) {
        
        var quote: OIMMessageInfo?
        
        if let quoteMessage {
            quote = quoteMessage.toOIMMessageInfo()
        }
        
        var message = OIMMessageInfo.createText(atMessage: text,
                                                atUsersID: atUsers.map({ $0.atUserID! }),
                                                atUsersInfo: atUsers.map({ info in
            let atUserInfo = OIMAtInfo()
            atUserInfo.atUserID = info.atUserID
            atUserInfo.groupNickname = info.groupNickname
            
            return atUserInfo
        }), message: quote)
        
        message.status = .sending
        sending(message.toMessageInfo())
        sendOIMMessage(message: message, to: recvID, conversationType: conversationType, onComplete: onComplete)
    }
    
    public func sendImageMessage(path: String,
                                 to recvID: String,
                                 conversationType: ConversationType,
                                 sending: CallBack.MessageReturnVoid,
                                 onComplete: @escaping CallBack.MessageReturnVoid) {
        
        let message = OIMMessageInfo.createImageMessage(path)
        message.status = .sending
        sending(message.toMessageInfo())
        sendOIMMessage(message: message, to: recvID, conversationType: conversationType, onComplete: onComplete)
    }
    
    public func sendVideoMessage(path: String,
                                 duration: Int,
                                 snapshotPath: String,
                                 to recvID: String,
                                 conversationType: ConversationType,
                                 sending: CallBack.MessageReturnVoid,
                                 onComplete: @escaping CallBack.MessageReturnVoid) {
        
        let message = OIMMessageInfo.createVideoMessage(path,
                                                        videoType: String(path.split(separator: ".").last!),
                                                        duration: duration,
                                                        snapshotPath: snapshotPath)
        message.status = .sending
        sending(message.toMessageInfo())
        sendOIMMessage(message: message, to: recvID, conversationType: conversationType, onComplete: onComplete)
    }
    
    public func sendAudioMessage(path: String,
                                 duration: Int,
                                 to recvID: String,
                                 conversationType: ConversationType,
                                 sending: CallBack.MessageReturnVoid,
                                 onComplete: @escaping CallBack.MessageReturnVoid) {
        let message = OIMMessageInfo.createSoundMessage(path, duration: duration)
        message.status = .sending
        sending(message.toMessageInfo())
        sendOIMMessage(message: message, to: recvID, conversationType: conversationType, onComplete: onComplete)
    }
    
    public func sendCardMessage(card: CardElem,
                                to recvID: String,
                                conversationType: ConversationType,
                                sending: CallBack.MessageReturnVoid,
                                onComplete: @escaping CallBack.MessageReturnVoid) {
        let message = OIMMessageInfo.createCardMessage(card.toOIMCardElem())
        message.status = .sending
        sending(message.toMessageInfo())
        sendOIMMessage(message: message, to: recvID, conversationType: conversationType, onComplete: onComplete)
    }
    
    public func sendLocation(latitude: Double,
                             longitude: Double,
                             desc: String,
                             to recvID: String,
                             conversationType: ConversationType,
                             sending: CallBack.MessageReturnVoid,
                             onComplete: @escaping CallBack.MessageReturnVoid) {
        let message = OIMMessageInfo.createLocationMessage(desc, latitude: latitude, longitude: longitude)
        message.status = .sending
        sending(message.toMessageInfo())
        sendOIMMessage(message: message, to: recvID, conversationType: conversationType, onComplete: onComplete)
    }
    
    
    public func sendFileMessage(filePath: String,
                                to recvID: String,
                                conversationType: ConversationType,
                                sending: CallBack.MessageReturnVoid,
                                onComplete: @escaping CallBack.MessageReturnVoid) {
        let message = OIMMessageInfo.createFileMessage(fromFullPath: filePath,
                                                       fileName: (filePath as NSString).lastPathComponent)
        message.status = .sending
        sending(message.toMessageInfo())
        sendOIMMessage(message: message, to: recvID, conversationType: conversationType, onComplete: onComplete)
    }
    
    public func sendMergeMessage(messages: [MessageInfo],
                                 title: String, // let title = conversationType != .c2c ? "群聊的聊天记录" : "\(conversation.showName!)与\(currentUserRelay.value!.nickname!)的聊天记录"
                                 to recvID: String,
                                 conversationType: ConversationType,
                                 sending: CallBack.MessageReturnVoid,
                                 onComplete: @escaping CallBack.MessageReturnVoid) {
        
        let summaryList = messages.map { ($0.senderNickname ?? "") + ":" +  MessageHelper.getSummary(by: $0) }
        
        let message = OIMMessageInfo.createMergeMessage(messages.map { $0.toOIMMessageInfo() }, title: title, summaryList: summaryList)
        
        message.status = .sending
        sending(message.toMessageInfo())
        sendOIMMessage(message: message, to: recvID, conversationType: conversationType, onComplete: onComplete)
    }
    
    public func revokeMessage(conversationID: String, clientMsgID: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.revokeMessage(conversationID, clientMsgID: clientMsgID, onSuccess: onSuccess) { code, msg in
            print("消息撤回失败:\(code), msg:\(msg)")
        }
    }
    
    public func deleteMessage(conversation: String, clientMsgID: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid, onFailure: @escaping CallBack.ErrorOptionalReturnVoid) {
        Self.shared.imManager.deleteMessage(conversation, clientMsgID: clientMsgID, onSuccess: onSuccess) { code, msg in
         print("消息删除失败:\(code), msg:\(msg)")
            onFailure(code, msg)
        }
    }
    
    public func createCustomMessage(customType: CustomMessageType, data: [String: Any]) -> MessageInfo {
        let dataStr = String.init(data: try! JSONSerialization.data(withJSONObject: ["customType": customType.rawValue,
                                                                                     "data": data]),
                                  encoding: .utf8)!
        return OIMMessageInfo.createCustomMessage(dataStr, extension: nil, description: nil).toMessageInfo()
    }
    
    public func markC2CMessageReaded(userId: String, msgIdList: [String], onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
//        Self.shared.imManager.markC2CMessage(asRead: userId, msgIDList: msgIdList, onSuccess: onSuccess) { code, msg in
//            print("标记消息已读失败:\(code), msg:\(msg)")
//        }
    }
    
    public func markGroupMessageReaded(groupId: String, msgIdList: [String]) {
//        Self.shared.imManager.markGroupMessage(asRead: groupId, msgIDList: msgIdList, onSuccess: nil)
    }
    
    public func markMessageAsReaded(byConID: String, msgIDList: [String], onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.markMessageAsRead(byMsgID: byConID, clientMsgIDs: msgIDList, onSuccess: onSuccess)
    }
    
    public func createGroupConversation(users: [UserInfo], groupType: GroupType = .normal, groupName: String = "", onSuccess: @escaping CallBack.GroupInfoOptionalReturnVoid) {
        
        let nickname = currentUserRelay.value?.nickname
        
        let groupInfo = OIMGroupBaseInfo()
        groupInfo.groupName = groupName.isEmpty ? nickname?.append(string: "创建的群聊".innerLocalized()) : groupName
        groupInfo.groupType = OIMGroupType(rawValue: groupType.rawValue) ?? .working
        
        let createInfo = OIMGroupCreateInfo()
        createInfo.memberUserIDs = users.compactMap({ $0.userID.isEmpty ? nil : $0.userID })
        createInfo.groupInfo = groupInfo
        
        Self.shared.imManager.createGroup(createInfo) { (groupInfo: OIMGroupInfo?) in
            print("创建群聊成功")
            onSuccess(groupInfo?.toGroupInfo())
        } onFailure: { code, msg in
            print("创建群聊成功录失败:\(code), \(msg)")
        }
    }
    
    public func clearC2CHistoryMessages(conversationID: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.clearConversationAndDeleteAllMsg(conversationID) { r in
            
        } onFailure: { code, msg in
            print("清空群聊天记录失败:\(code), \(msg)")
        }
    }
    
    public func clearGroupHistoryMessages(conversationID: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.clearConversationAndDeleteAllMsg(conversationID) { r in
            
        } onFailure: { code, msg in
            print("清空群聊天记录失败:\(code), \(msg)")
        }
    }
    
    public func deleteAllMsgFromLocalAndSvr(onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.deleteAllMsgFromLocalAndSvrWith(onSuccess: onSuccess) { code, msg in
            print("清空群聊天记录失败:\(code), \(msg)")
        }
    }
    
    public func uploadFile(fullPath: String, onProgress: @escaping CallBack.ProgressReturnVoid, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.uploadFile(fullPath,
                                         name: nil,
                                         cause: nil) { save, current, total in
            let p = CGFloat(current) / CGFloat(total)
            onProgress(p)
        } onCompletion: { c, u, t  in
            
        } onSuccess: { r in
            let dic = try! JSONSerialization.jsonObject(with: r!.data(using: .utf8)!, options: .allowFragments) as! [String: Any]
            
            onSuccess(dic["url"] as! String)
        } onFailure: { code, msg in
            print("上传文件失败:\(code), \(msg)")
        }
    }
    
    public func searchRecord(param: SearchParam, onSuccess: @escaping CallBack.SearchResultInfoOptionalReturnVoid) {
        Self.shared.imManager.searchLocalMessages(param.toOIMSearchParam()) { (result: OIMSearchResultInfo?) in
            onSuccess(result?.toSearchResultInfo())
        }
    }
    
    public func searchGroups(param: SearchGroupParam, onSuccess: @escaping CallBack.GroupInfosReturnVoid) {
        Self.shared.imManager.searchGroups(param.toOIMSearchGroupParam()) { result in
            
            let arr = result?.compactMap { $0.toGroupInfo() } ?? []
            onSuccess(arr)
        }
    }
    
    public func searchFriends(param: SearchUserParam, onSuccess: @escaping CallBack.SearchUsersInfoOptionalReturnVoid) {
        Self.shared.imManager.searchFriends(param.toOIMSearchUserParam()) { result in
            
            let arr = result?.compactMap { $0.toSearchFriendsInfo() } ?? []
            onSuccess(arr)
        }
    }
    
    public func insertCustomMessage(conversationType: ConversationType,
                                    msg: MessageInfo,
                                    recvID: String,
                                    onSuccess: @escaping CallBack.MessageReturnVoid) {
        
        if conversationType == .c2c {
            Self.shared.imManager.insertSingleMessage(toLocalStorage: msg.toOIMMessageInfo(),
                                                      recvID: recvID,
                                                      sendID: getLoginUserID(),
                                                      onSuccess: { message in
                onSuccess(message!.toMessageInfo())
            }) { code, msg in
                
                print("单聊插入本地失败:\(code), \(msg)")
            }
        } else {
            Self.shared.imManager.insertGroupMessage(toLocalStorage: msg.toOIMMessageInfo(),
                                                     groupID: recvID,
                                                     sendID: getLoginUserID(),
                                                     onSuccess: { message in
                onSuccess(message!.toMessageInfo())
            }) { code, msg in
                print("群聊插入本地失败:\(code), \(msg)")
            }
        }
    }
}

// MARK: - 会话方法

extension IMController {
    
    public func getConversation(sessionType: ConversationType = .undefine, sourceId: String = "", conversationID: String = "", onSuccess: @escaping CallBack.ConversationInfoOptionalReturnVoid) {
        
        if !conversationID.isEmpty {
            
            Self.shared.imManager.getMultipleConversation([conversationID]) { conversations in
                onSuccess(conversations?.first?.toConversationInfo())
            } onFailure: { code, msg in
                print("创建会话失败:\(code), .msg:\(msg)")
            }
            
        } else {
            
            let conversationType = OIMConversationType(rawValue: sessionType.rawValue) ?? OIMConversationType.undefine
            
            Self.shared.imManager.getOneConversation(withSessionType: conversationType, sourceID: sourceId) { (conversation: OIMConversationInfo?) in
                onSuccess(conversation?.toConversationInfo())
            } onFailure: { code, msg in
                print("创建会话失败:\(code), .msg:\(msg)")
            }
        }
    }
    
    
    public func setGlobalRecvMessageOpt(op: ReceiveMessageOpt, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        let opt = OIMReceiveMessageOpt(rawValue: op.rawValue) ?? OIMReceiveMessageOpt.receive
        Self.shared.imManager.setGlobalRecvMessageOpt(opt, onSuccess: onSuccess) { code, msg in
            print("设置全局免打扰失败:\(code), .msg:\(msg)")
        }
    }
    
    public func setOneConversationPrivateChat(conversationID: String, isPrivate: Bool, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        
        Self.shared.imManager.setConversationPrivateChat(conversationID, isPrivate: isPrivate, onSuccess: onSuccess) { code, msg in
            print("设置阅后即焚失败:\(code), .msg:\(msg)")
        }
    }
    
    public func setBurnDuration(conversationID: String, burnDuration: Int, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.setConversationBurnDuration(conversationID, duration: burnDuration, onSuccess: onSuccess)
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
    
    public func getUserInfo(uids: [String], onSuccess: @escaping CallBack.FullUserInfosReturnVoid) {
        Self.shared.imManager.getUsersInfo(uids) { userInfos in
            let users = userInfos?.compactMap { $0.toFullUserInfo() } ?? []
            onSuccess(users)
        }
    }
    
    public func setSelfInfo(userInfo: UserInfo, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.setSelfInfo(userInfo.toOIMUserInfo(), onSuccess: onSuccess) { code, msg in
            print("更新个人信息失败:\(code), \(msg)")
        }
    }
    
    public func logout(onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.logoutWith(onSuccess: onSuccess) { code, msg in
            print("退出登录失败:\(code), \(msg)")
        }
    }
    
    public func getLoginUserID() -> String {
        return imManager.getLoginUserID()
    }
}

// MARK: - Signaling方法

extension IMController {
    public func getRoomSignalingInfoByGroupID(groupID: String, onSuccess: @escaping CallBack.GroupSignalingInfoReturnVoid) {

    }
    
    public func signalingGetInvitation(by roomID : String, onSuccess: @escaping CallBack.SignalingInfoOptionalReturnVoid) {

    }
    
    public func signalingCreateMeeting(name: String, startTime: Double, duration: Double, onSuccess: @escaping CallBack.SignalingInfoOptionalReturnVoid, onFailure: CallBack.ErrorOptionalReturnVoid?) {

    }
    
    public func signalingJoinMeeting(meetingID: String, meetingName: String? = nil, participantNickname: String? = nil, onSuccess: @escaping CallBack.SignalingInfoOptionalReturnVoid, onFailure: @escaping CallBack.ErrorOptionalReturnVoid) {

    }
    
    public func signalingCloseMeeting(meetingID: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid, onFailure: @escaping CallBack.ErrorOptionalReturnVoid) {

    }
    
    public func signalingUpdateMeetingInfo(meetingID: String, param: [String: Any], onSuccess: @escaping CallBack.StringOptionalReturnVoid) {

    }
    
    /**
     会议室 管理员对指定的某一个入会人员设置禁言
     @param roomID 会议ID
     @param userID 目标的用户ID
     @param streamType video/audio
     @param mute YES：禁言
     @param muteAll video/audio 一起设置
     */
    public func signalingOperateStream(meetingID: String, userID: String, streamType: String? = nil, mute: Bool = true, muteAll: Bool = false, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {

    }
    
    public func signalingGetMeetings(onSuccess: @escaping CallBack.MeetingReturnVoid) {

    }
}

// MARK: - Moments方法
extension IMController {
    public func getWorkMomentsNotification(offset: Int = 0, count: Int = 10000, onSuccess: @escaping CallBack.MomentsNewMessageReturnVoid) {

    }
    
    public func getMomentsUnReadCountWith(onSuccess: @escaping CallBack.ProgressReturnVoid) {

    }
    
    public func clearWorkMomentsNotificationWith(onSuccess: @escaping CallBack.StringOptionalReturnVoid) {

    }
}

// MARK: - Listener

extension IMController: OIMFriendshipListener {
    @objc public func onFriendApplicationAdded(_ application: OIMFriendApplication) {
        friendApplicationChangedSubject.onNext(application.toFriendApplication())
    }
    
    @objc public func onFriendInfoChanged(_ info: OIMFriendInfo) {
        friendInfoChangedSubject.onNext(info.toFriendInfo())
    }
    
    public func onBlackAdded(_ info: OIMBlackInfo) {
        onBlackAddedSubject.onNext(info.toBlackInfo())
    }
    
    public func onBlackDeleted(_ info: OIMBlackInfo) {
        onBlackDeletedSubject.onNext(info.toBlackInfo())
    }
}

// MARK: OIMGroupListener

extension IMController: OIMGroupListener {
    public func onGroupApplicationAdded(_ groupApplication: OIMGroupApplicationInfo) {
        groupApplicationChangedSubject.onNext(groupApplication.toGroupApplicationInfo())
    }
    
    public func onGroupInfoChanged(_ changeInfo: OIMGroupInfo) {
        groupInfoChangedSubject.onNext(changeInfo.toGroupInfo())
    }
    
    public func onGroupMemberInfoChanged(_ changeInfo: OIMGroupMemberInfo) {
        groupMemberInfoChange.onNext(changeInfo.toGroupMemberInfo())
    }
    
    public func onJoinedGroupAdded(_ groupInfo: OIMGroupInfo) {
        joinedGroupAdded.onNext(groupInfo.toGroupInfo())
        
    }
    
    public func onJoinedGroupDeleted(_ groupInfo: OIMGroupInfo) {
        joinedGroupDeleted.onNext(groupInfo.toGroupInfo())
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
        connectionRelay.accept(.syncStart)
    }
    
    public func onSyncServerFinish() {
        connectionRelay.accept(.syncComplete)
    }
    
    public func onSyncServerFailed() {
        connectionRelay.accept(.syncFailure)
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
        if msg.contentType.rawValue < 1000,
           msg.contentType != .typing,
           msg.contentType != .revoke,
           msg.contentType != .hasReadReceipt,
           msg.contentType != .groupHasReadReceipt {
            Self.shared.imManager.getOneConversation(withSessionType: msg.sessionType,
                                                     sourceID: msg.sessionType == .C2C ? msg.sendID! : msg.groupID!,
                                                     onSuccess: { conversation in
                
                if conversation!.conversationID != self.chatingConversationID,
                   conversation!.unreadCount > 0,
                   conversation!.recvMsgOpt == .receive {
                    
                    self.ringAndVibrate()
                }
            })
        }
        newMsgReceivedSubject.onNext(msg.toMessageInfo())
    }
    
    public func onRecvC2CReadReceipt(_ receiptList: [OIMReceiptInfo]) {
        c2cReadReceiptReceived.onNext(receiptList.compactMap { $0.toReceiptInfo() })
    }
    
    public func onRecvGroupReadReceipt(_ groupMsgReceiptList: [OIMReceiptInfo]) {
        groupReadReceiptReceived.onNext(groupMsgReceiptList.compactMap { $0.toReceiptInfo() })
    }
    
    public func onRecvMessageRevoked(_ msgID: String) {
//        msgRevokeReceived.onNext(msgID)
    }
    
    // 启用新的撤回操作
    public func onNewRecvMessageRevoked(_ messageRevoked: OIMMessageRevokedInfo) {
        msgRevokeReceived.onNext(messageRevoked.toMessageRevoked())
    }
}

// MARK: - Models

// MARK: 主要模型

public class UserInfo: Codable {
    public var userID: String!
    public var nickname: String?
    public var faceURL: String?
    public var gender: Gender?
    public var phoneNumber: String?
    public var birth: Int?
    public var email: String?
    public var createTime: Int = 0
    public var landline: String? // 座机
    public var ex: String?
    public var globalRecvMsgOpt: ReceiveMessageOpt = .receive
    
    public init(userID: String,
                nickname: String? = nil,
                phoneNumber: String? = nil,
                email: String? = nil,
                faceURL: String? = nil,
                birth: Int? = nil,
                gender: Gender? = nil,
                landline: String? = nil) {
        self.userID = userID
        self.nickname = nickname
        self.phoneNumber = phoneNumber
        self.email = email
        self.faceURL = faceURL
        self.birth = birth
        self.gender = gender
        self.landline = landline
    }
    
    // 业务做选择逻辑
    public var isSelected: Bool = false
}

public class FriendApplication {
    public var fromUserID: String = ""
    public var fromNickname: String?
    public var fromFaceURL: String?
    public var toUserID: String = ""
    public var toNickname: String?
    public var toFaceURL: String?
    public var handleResult: ApplicationStatus = .normal
    public var reqMsg: String?
    public var handlerUserID: String?
    public var handleMsg: String?
    public var handleTime: Int?
}

public class GroupApplicationInfo {
    public var groupID: String = ""
    public var groupName: String?
    public var groupFaceURL: String?
    public var creatorUserID: String = ""
    public var ownerUserID: String = ""
    public var memberCount: Int = 0
    public var userID: String?
    public var nickname: String?
    public var userFaceURL: String?
    public var reqMsg: String?
    public var reqTime: Int?
    public var handleUserID: String?
    public var handledMsg: String?
    public var handledTime: Int?
    public var handleResult: ApplicationStatus = .normal
    public var joinSource: JoinSource = .search
    public var inviterUserID: String?
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
public enum ReceiveMessageOpt: Int, Codable {
    /// 在线正常接收消息，离线时会使用 APNs
    case receive = 0
    /// 不会接收到消息，离线不会有推送通知
    case notReceive = 1
    /// 在线正常接收消息，离线不会有推送通知
    case notNotify = 2
}

public class ConversationInfo {
    public let conversationID: String
    public var userID: String?
    public var groupID: String?
    public var showName: String?
    public var faceURL: String?
    public var recvMsgOpt: ReceiveMessageOpt = .receive
    public var unreadCount: Int = 0
    public var conversationType: ConversationType = .c2c
    public var latestMsgSendTime: Int = 0
    public var draftText: String?
    public var draftTextTime: Int = 0
    public var isPinned: Bool = false
    public var latestMsg: MessageInfo?
    public var ex: String?
    public var isPrivateChat: Bool = false
    public var burnDuration: Double = 30
    init(conversationID: String) {
        self.conversationID = conversationID
    }
}

open class MessageInfo: Encodable {
    public var clientMsgID: String = ""
    public var serverMsgID: String?
    public var createTime: TimeInterval = 0
    public var sendTime: TimeInterval = 0
    public var sessionType: ConversationType = .c2c
    public var sendID: String = ""
    public var recvID: String?
    public var handleMsg: String?
    public var msgFrom: MessageLevel = .user
    public var contentType: MessageContentType = .unknown
    public var platformID: Int = 0
    public var senderNickname: String?
    public var senderFaceUrl: String?
    public var groupID: String?
    public var content: String?
    /// 消息唯一序列号
    var seq: Int = 0
    public var isRead: Bool = false // 标记收到的消息，是否已经标记已读
    public var status: MessageStatus = .undefine
    public var attachedInfo: String?
    public var ex: String?
    public var offlinePushInfo: OfflinePushInfo = .init()
    public var textElem: TextElem?
    public var pictureElem: PictureElem?
    public var soundElem: SoundElem?
    public var videoElem: VideoElem?
    public var fileElem: FileElem?
    public var mergeElem: MergeElem?
    public var atTextElem: AtTextElem?
    public var locationElem: LocationElem?
    public var quoteElem: QuoteElem?
    public var customElem: CustomElem?
    public var notificationElem: NotificationElem?
    public var faceElem: FaceElem?
    public var attachedInfoElem: AttachedInfoElem?
    public var hasReadTime: Double = 0
    public var cardElem: CardElem?
    public var typingElem: TypingElem?

    // 客户端调用的
    public var isPlaying = false
    public var isSelected = false
    public var isAnchor = false // 搜索聊天记录的消息
    
    public func getAbstruct() -> String? {
        switch contentType {
        case .text:
            return content
        case .quote:
            return quoteElem?.text
        case .at:
            return atTextElem?.atText
        default:
            return contentType.abstruct
        }
    }
    
    public func isCalling() -> Bool {
        if let data = customElem?.data {
            let obj = try! JSONSerialization.jsonObject(with: data.data(using: .utf8)!) as! [String: Any]
            if let type = obj["customType"] as? Int, type == 901 {
                return true
            }
        }
        
        return false
    }
    
    public func isTyping() -> Bool {
        guard contentType == .typing else { return false }
        
        return typingElem?.msgTips == "yes"
    }
}

extension MessageInfo {
    public var revokedInfo: MessageRevoked {
        assert(contentType == .revoke)
        let detail = notificationElem?.detail ?? content
        return JsonTool.fromJson(detail!, toClass: MessageRevoked.self) ?? MessageRevoked()
    }
}

public class GroupMemberBaseInfo: Encodable {
    public var userID: String?
    public var roleLevel: GroupMemberRole = .member
}

public enum GroupMemberFilter: Int, Codable {
    case all = 0
    /// 群主
    case owner = 1
    case admin = 2
    case member = 3
    case adminAndMember = 4
    case superAndAdmin = 5
}

public enum GroupMemberRole: Int, Codable {
    case owner  = 100
    case admin  = 60
    case member = 20
}

public class GroupMemberInfo: GroupMemberBaseInfo {
    public var groupID: String?
    public var nickname: String?
    public var faceURL: String?
    public var joinTime: Int = 0
    public var joinSource: JoinSource = .search
    public var operatorUserID: String?
    public var inviterUserID: String?
    public var muteEndTime: Double = 0
    public var ex: String?
    
    public override init() {
    }
    
    // 非SDK提供
    public var inviterUserName: String?
}

extension GroupMemberInfo {
    public var isSelf: Bool {
        return userID == IMController.shared.uid
    }
    
    public var joinWay: String {
        switch joinSource {
        case .invited:
            return "\(inviterUserName ?? "")邀请加入"
        case .search:
            return "搜索加入"
        case .QRCode:
            return "扫描二维码加入"
        }
    }
    
    public var roleLevelString: String {
        switch roleLevel {
        case .admin:
            return "管理员"
        case .owner:
            return "创建者"
        default:
            return ""
        }
    }
    
    public var isOwnerOrAdmin: Bool {
        return roleLevel == .owner || roleLevel == .admin
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
    case custom = 110
    case typing = 113
    case quote = 114
    /// 动图消息
    case face = 115
    case advancedText = 117
    case reactionMessageModifier = 121
    case reactionMessageDeleter = 122

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
    /// oa通知
    case oaNotification = 1400
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
    /// 群成员被禁言
    case groupMemberMuted = 1512
    /// 群成员被取消禁言
    case groupMemberCancelMuted = 1513
    /// 群禁言
    case groupMuted = 1514
    /// 取消群禁言
    case groupCancelMuted = 1515
    
    case groupMemberInfoSet = 1516
    case groupAnnouncement = 1519
    case groupSetName = 1520
    /// 阅后即焚
    case privateMessage = 1701
    
    case revoke = 2101
    /// 单聊已读回执
    case hasReadReceipt = 2150
    /// 群聊消息回执
    case groupHasReadReceipt = 2155
    
    public var abstruct: String? {
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
        case .custom:
            return "[自定义消息]"
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

public enum GroupStatus: Int, Codable {
    case ok = 0
    case beBan = 1
    case dismissed = 2
    case muted = 3
}

public enum JoinSource: Int, Codable {
    case invited = 2 /// 通过邀请
    case search = 3 /// 通过搜索
    case QRCode = 4 /// 通过二维码
}

public enum GroupVerificationType: Int, Codable {
    case applyNeedVerificationInviteDirectly = 0 /// 申请需要同意 邀请直接进
    case allNeedVerification = 1 /// 所有人进群需要验证，除了群主管理员邀
    case directly = 2 /// 直接进群
    
}

public class GroupBaseInfo: Encodable {
    public var groupName: String?
    public var introduction: String?
    public var notification: String?
    public var faceURL: String?
}

public class GroupInfo: GroupBaseInfo {
    public var groupID: String = ""
    public var ownerUserID: String?
    public var createTime: Int = 0
    public var memberCount: Int = 0
    public var creatorUserID: String?
    public var groupType: GroupType = .working
    public var status: GroupStatus = .ok
    public var needVerification: GroupVerificationType = .applyNeedVerificationInviteDirectly
    public var lookMemberInfo: Int = 0
    public var applyMemberFriend: Int = 0
    
    public var isMine: Bool {
        return ownerUserID == IMController.shared.uid
    }
    
    public func needVerificationText() -> String {
        
        if (needVerification == .allNeedVerification) {
            return "需要发送验证信息".innerLocalized()
        } else if (needVerification == .directly) {
            return "允许任何人加群".innerLocalized()
        }
        return "群成员邀请无需验证".innerLocalized()
    }
}

public class ConversationNotDisturbInfo {
    public  let conversationId: String
    public var result: ReceiveMessageOpt = .receive
    init(conversationId: String) {
        self.conversationId = conversationId
    }
}

// MARK: 次要模型

public class FaceElem: Encodable {
    public var index: Int = 0
    public var data: String?
}

public class AttachedInfoElem: Encodable {
    public var groupHasReadInfo: GroupHasReadInfo?
    public var isPrivateChat: Bool = false
    public var burnDuration: Double = 30
    public var hasReadTime: Double = 0
}

public class GroupHasReadInfo: Encodable {
    public var hasReadUserIDList: [String]?
    public var hasReadCount: Int = 0
}

public class NotificationElem: Encodable {
    public var detail: String?

    private(set) var opUser: GroupMemberInfo?
    private(set) var quitUser: GroupMemberInfo?
    private(set) var entrantUser: GroupMemberInfo?
    /// 群改变新群主的信息
    private(set) var groupNewOwner: GroupMemberInfo?
    public private(set) var group: GroupInfo?
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
    public var detailObject: [String: Any] {
        guard let detail else {
            return [:]
        }
        
        if let obj = try? JSONSerialization.jsonObject(with: detail.data(using: .utf8)!) as? [String : Any] {
            return obj
        }
        
        return [:]
    }
}

public class OfflinePushInfo: Codable {
    public var title: String?
    public var desc: String?
    public var iOSPushSound: String?
    public var iOSBadgeCount: Bool = false
    public var operatorUserID: String?
    public var ex: String?
}

public class TextElem: Codable {
    public var content: String!
}

public class CardElem: Codable {
    public var userID: String!
    public var nickname: String!
    public var faceURL: String?
    public var ex: String?
    
    public init(userID: String, nickname: String, faceURL: String?) {
        self.userID = userID
        self.nickname = nickname
        self.faceURL = faceURL
    }
}

public class TypingElem: Codable {
    public var msgTips: String?
}

public class PictureElem: Codable {
    /// 本地资源地址
    public var sourcePath: String?
    /// 本地图片详情
    public var sourcePicture: PictureInfo?
    /// 大图详情
    public var bigPicture: PictureInfo?
    /// 缩略图详情
    public var snapshotPicture: PictureInfo?
}

public class PictureInfo: Codable {
    public var uuID: String?
    public var type: String?
    public var size: Int = 0
    public var width: CGFloat = 0
    public var height: CGFloat = 0
    /// 图片oss地址
    public var url: String?
}

public class SoundElem: Codable {
    public var uuID: String?
    /// 本地资源地址
    public var soundPath: String?
    /// oss地址
    public var sourceUrl: String?
    public var dataSize: Int = 0
    public var duration: Int = 0
}

public class VideoElem: Codable {
    public var videoUUID: String?
    public var videoPath: String?
    public var videoUrl: String?
    public var videoType: String?
    public var videoSize: Int = 0
    public var duration: Int = 0
    /// 视频快照本地地址
    public var snapshotPath: String?
    /// 视频快照唯一ID
    public var snapshotUUID: String?
    public var snapshotSize: Int = 0
    /// 视频快照oss地址
    public var snapshotUrl: String?
    public var snapshotWidth: CGFloat = 0
    public var snapshotHeight: CGFloat = 0
}

public class FileElem: Encodable {
    public var filePath: String?
    public var uuID: String?
    /// oss地址
    public var sourceUrl: String?
    public var fileName: String?
    public var fileSize: Int = 0
}

public class MergeElem: Encodable {
    public var title: String?
    public var abstractList: [String]?
    public var multiMessage: [MessageInfo]?
}

public class AtTextElem: Encodable {
    public var text: String?
    public var atUserList: [String]?
    public var atUsersInfo: [AtInfo]?
    public var quoteMessage: MessageInfo?
    public var isAtSelf: Bool = false
    
    public var atText: String {
        var temp = text!
        atUsersInfo?.forEach({ info in
            temp = temp.replacingOccurrences(of: "@\(info.atUserID!)",
                                             with: "@\(info.atUserID == IMController.shared.uid ? "我".innerLocalized() : info.groupNickname!)")
        })
        
        return temp
    }
    
    public var atAttributeString: NSAttributedString {
        var attrText = NSMutableAttributedString()
        // 将文本中的@人员替换下
        var texts = text!.split(separator: " ")
        
        guard let atUsersInfo else { return NSAttributedString() }
        texts.forEach({ text in
            let match = atUsersInfo.first { info in
                return "@\(info.atUserID!)" == String(text)
            }
            
            if match != nil {
                // 如有有@标识的人
                let atUserName = match!.atUserID == IMController.shared.uid ?
                "我".innerLocalized() : match!.groupNickname!
                
                attrText.append(NSMutableAttributedString(string: "@\(atUserName) ", attributes: [
                    NSAttributedString.Key.foregroundColor: match!.atUserID == IMController.shared.uid ? UIColor.systemBlue : UIColor.systemBlue]))
            } else {
                attrText.append(NSMutableAttributedString(string: String(" \(text)")))
            }
        })
        
        return attrText
    }
}

public class AtInfo: Encodable {
    public var atUserID: String?
    public var groupNickname: String?
    
    public init(atUserID: String, groupNickname: String) {
        self.atUserID = atUserID
        self.groupNickname = groupNickname
    }
}

public class LocationElem: Encodable {
    public var desc: String?
    public var longitude: Double = 0
    public var latitude: Double = 0
}

public class QuoteElem: Encodable {
    public var text: String?
    public var quoteMessage: MessageInfo?
}

public class CustomElem: Encodable {
    public var data: String?
    public var ext: String?
    public var description: String?
    
    public func value() -> [String: Any]? {
        if let data = data {
            let obj = try! JSONSerialization.jsonObject(with: data.data(using: .utf8)!) as! [String: Any]
            return obj["data"] as? [String: Any]
        }
        
        return nil
    }
    
    public var type: CustomMessageType? {
        if let data = data {
            let obj = try! JSONSerialization.jsonObject(with: data.data(using: .utf8)!) as! [String: Any]
            let t = obj["customType"] as! Int
            
            return CustomMessageType.init(rawValue: t)
        }
        
        return nil
    }
}

public struct BusinessCard: Codable {
    public let faceURL: String?
    public let nickname: String?
    public let userID: String
    public init(faceURL: String?, nickname: String?, userID: String) {
        self.faceURL = faceURL
        self.nickname = nickname
        self.userID = userID
    }
}

public class ReceiptInfo {
    public var userID: String?
    public var groupID: String?
    /// 已读消息id
    public var msgIDList: [String]?
    public var readTime: Int = 0
    public var msgFrom: MessageLevel = .user
    public var contentType: MessageContentType = .hasReadReceipt
    public var sessionType: ConversationType = .undefine
}

public class MessageRevoked: Codable {
    /*
     * 撤回者的id
     */
    public var revokerID: String?
    public var revokerNickname: String?
    
    /*
     * 撤回者的身份：例如：群主，群管理员
     */
    public var revokerRole: GroupMemberRole = .member
    public var clientMsgID: String?
    public var revokeTime: Double = 0
    public var sourceMessageSendTime: Double = 0
    public var sourceMessageSendID: String?
    public var sourceMessageSenderNickname: String?
    public var sessionType: ConversationType = .c2c
    
    public init(revokerID: String? = nil, revokerNickname: String? = nil, revokerRole: GroupMemberRole = .member, clientMsgID: String? = nil, revokeTime: Double = 0, sourceMessageSendTime: Double = 0, sourceMessageSendID: String? = nil, sourceMessageSenderNickname: String? = nil, sessionType: ConversationType = .c2c) {
        self.revokerID = revokerID
        self.revokerNickname = revokerNickname
        self.revokerRole = revokerRole
        self.clientMsgID = clientMsgID
        self.revokeTime = revokeTime
        self.sourceMessageSendID = sourceMessageSendID
        self.sourceMessageSenderNickname = sourceMessageSenderNickname
        self.sessionType = sessionType
    }
}

extension MessageRevoked {
    public var revokerIsSelf: Bool {
        return revokerID == IMController.shared.uid
    }
    
    public var sourceMessageSendIDIsSelf: Bool {
        return sourceMessageSendID == IMController.shared.uid
    }
}

public class FullUserInfo {
    public var publicInfo: PublicUserInfo?
    public var friendInfo: FriendInfo?
    public var blackInfo: BlackInfo?
    
    public var userID: String?
    public var showName: String?
    public var faceURL: String?
    public var gender: Gender = .male
}

public enum Gender: Int, Codable {
    case undefine = 0
    case male = 1
    case female = 2
    
    public var description: String {
        switch self {
        case .male:
            return "男".innerLocalized()
        case .female:
            return "女".innerLocalized()
        case .undefine:
            return "-".innerLocalized()
        }
    }
}

public enum Relationship: Int, Codable {
    case black = 0
    case friends = 1
}

public class PublicUserInfo: Encodable {
    public var userID: String?
    public var nickname: String?
    public var faceURL: String?
    public var gender: Gender = .male
}

public class FriendInfo: PublicUserInfo {
    public var ownerUserID: String?
    public var remark: String?
    public var createTime: Int = 0
    public var addSource: Int = 0
    public var operatorUserID: String?
    public var phoneNumber: String?
    public var birth: Int = 0
    public var email: String?
    public var attachedInfo: String?
    public var ex: String?
    
    public func toUserInfo() -> UserInfo? {
        let json = JsonTool.toJson(fromObject: self)
        let obj = JsonTool.fromJson(json, toClass: UserInfo.self)
        return obj
    }
}

public class BlackInfo: PublicUserInfo {
    public var operatorUserID: String?
    public var createTime: Int = 0
    public var addSource: Int = 0
    public var attachedInfo: String?
    public var ex: String?
}

public class SearchParam {
    public var conversationID: String = ""
    public var keywordList: [String] = []
    public var messageTypeList: [MessageContentType]?
    public var searchTimePosition: Int = 0
    public var searchTimePeriod: Int = 0
    public var pageIndex: Int = 1
    public var count: Int = 100
    public init() {
        
    }
}

public class SearchResultInfo {
    public var totalCount: Int = 0
    public var searchResultItems: [SearchResultItemInfo] = []
}

public class SearchResultItemInfo {
    public var conversationID: String = ""
    public var messageCount: Int = 0
    public var conversationType: ConversationType = .c2c
    public var showName: String = ""
    public var faceURL: String = ""
    public var messageList: [MessageInfo] = []
}

public class SearchGroupParam {
    public var keywordList: [String] = []
    public var isSearchGroupID: Bool = true
    public var isSearchGroupName: Bool = true
    public init() {
        
    }
}

public class SearchUserParam {
    public var keywordList: [String] = []
    public var isSearchUserID: Bool = true
    public var isSearchNickname: Bool = true
    public var isSearchRemark: Bool = true
    public init() {
        
    }
}

public class SearchUserInfo: FriendInfo {
    public var relationship: Relationship = .friends
}

public class InvitationResultInfo: Codable {
    public var token: String?
    public var liveURL: String?
    public var roomID: String?
}

public class MomentsNewMessageInfo: Codable {
    
    // 新消息的
    // 0为普通评论 1为被喜欢 2为AT提醒看的朋友圈
    public var notificationMsgType: Int = 0
    public var workMomentContent: String = ""
    public var replyUserName: String?
    public var replyUserID: String?
    
    public var workMomentID: String = ""
    public var content: String?
    public var contentID: String?
    public var userName: String = ""
    public var faceURL: String?
    public var createTime: Double = 0
    public var userID: String = ""
}


class MeetingInfoList: Codable {
    public var meetingInfoList: [MeetingInfo] = []
}

open class MeetingInfo: Codable {
    public var roomID: String?
    public var meetingID: String = ""
    public var meetingName: String = ""
    public var hostUserID: String?
    public var createTime: Double = 0
    public var startTime: Double = 0
    public var endTime: Double = 0
    public var participantCanUnmuteSelf: Bool? // 成员是否能开启音频
    public var participantCanEnableVideo: Bool? // 成员是否能开启视频
    public var onlyHostInviteUser: Bool? //仅主持人可邀请用户
    public var joinDisableVideo: Bool? //加入是否默认关视频
    public var isMuteAllMicrophone: Bool? // 是否全员禁用麦克风
    public var inviteeUserIDList: [String]? //邀请列表
    public var onlyHostShareScreen: Bool?  //仅主持人可共享屏幕
    public var joinDisableMicrophone: Bool?  //加入是否默认关麦克风
    public var isMuteAllVideo: Bool? // 是否全员禁用视频
    public var canScreenUserIDList: [String]? // 可共享屏幕的ID列表
    public var disableMicrophoneUserIDList: [String]? // 当前被禁言麦克风的id列表
    public var disableVideoUserIDList: [String]? // 当前禁用视频流的ID列表
    public var pinedUserIDList: [String]? // 置顶ID列表
    public var beWatchedUserIDList: [String]? // 正在被观看用户列表
    
    // 增加/删除相关ID
    public var addCanScreenUserIDList: [String]?
    public var reduceCanScreenUserIDList: [String]?
    public var addDisableMicrophoneUserIDList: [String]?
    public var reduceDisableMicrophoneUserIDList: [String]?
    public var addDisableVideoUserIDList: [String]?
    public var reduceDisableVideoUserIDList: [String]?
    public var addPinedUserIDList: [String]?
    public var reducePinedUserIDList: [String]?
    public var addBeWatchedUserIDList: [String]?
    public var reduceBeWatchedUserIDList: [String]?
    
    public var ex: String?
    
    public var hostUserName: String?
    
    public init() {
        
    }
}

public class MeetingStreamEvent: Codable {
    public var meetingID: String = ""
    public var streamType: String?
    public var mute: Bool = false
}


/// 部门信息
///
open class DepartmentInfo : Decodable {
    public var departmentID: String?
    public var faceURL: String?
    public var name: String?
    public var relatedGroupID: String?
    /// 上一级部门id
    public var parentID: String?
    public var order: Int?
    /// 部门类型
    public var departmentType: Int?
    public var createTime: Double?
    /// 子部门数量
    public var subDepartmentNum: Int?
    /// 成员数量
    public var memberNum: Int?
    public var ex: String?
    /// 附加信息
    public var attachedInfo: String?
}

/// 部门成员信息
///
public class DepartmentMemberInfo : Decodable {
    public var userID: String?
    public var nickname: String?
    public var englishName: String?
    public var faceURL: String?
    public var gender: Int?
    /// 手机号
    public var mobile: String?
    /// 座机
    public var telephone: String?
    public var birth: Int?
    public var email: String?
    /// 所在部门的id
    public var departmentID: String?
    /// 排序方式
    public var order: Int?
    /// 职位
    public var position: String?
    /// 是否是领导
    public var leader: Int?
    public var status: Int?
    public var createTime: Double?
    public var ex: String?
    /// 附加信息
    public var attachedInfo: String?
    /// 搜索时使用
    public var departmentName: String?
    /// 所在部门的所有上级部门
    public var parentDepartmentList: [DepartmentInfo]?
}

/// 用户所在的部门
///
public class UserInDepartmentInfo : Decodable {
    public var member: DepartmentMemberInfo?
    public var department: DepartmentInfo?
    public var companyName: String?
}

/// 部门下的子部门跟员工
///
public class DepartmentMemberAndSubInfo : Decodable {
    /// 一级子部门
    public var departmentList: [DepartmentInfo] = []
    /// 一级成员
    public var departmentMemberList: [DepartmentMemberInfo] = []
    /// 当前部门的所有上一级部门
    public var parentDepartmentList: [DepartmentInfo]?
}


// 查询组织架构使用
public class SearchOrganizationParam : Encodable {
    // 搜索关键词，目前仅支持一个关键词搜索，不能为空
    public var keyword: String = ""
    // 是否以关键词搜索UserID
    public var isSearchUserID: Bool = true
    // 是否以关键词搜索昵称，默认false
    public var isSearchUserName: Bool = false
    // 是否以英文搜索备注，默认false
    public var isSearchEnglishName: Bool = false
    // 是否以职位搜索备注，默认false
    public var isSearchPosition: Bool = false
    // 是否以移动号码搜索备注，默认false
    public var isSearchMobile: Bool = false
    // 是否以邮箱搜索备注，默认false
    public var isSearchEmail: Bool = false
    // 是否以电话号码搜索备注，默认false
    public var isSearchTelephone: Bool = false
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
    
    public var isOutgoing: Bool {
        return sendID == IMController.shared.uid
    }
}

extension OfflinePushInfo {
    func toOIMOfflinePushInfo() -> OIMOfflinePushInfo {
        let json: String = JsonTool.toJson(fromObject: self)
        if let item = OIMOfflinePushInfo.mj_object(withKeyValues: json) {
            return item
        }
        return OIMOfflinePushInfo()
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
        item.introduction = introduction
        item.notification = notification
        item.groupName = groupName
        item.groupType = GroupType(rawValue: groupType.rawValue) ?? .working
        item.status = GroupStatus(rawValue: status.rawValue) ?? .ok
        item.needVerification = GroupVerificationType(rawValue: needVerification.rawValue) ?? .applyNeedVerificationInviteDirectly
        item.lookMemberInfo = lookMemberInfo
        item.applyMemberFriend = applyMemberFriend
        
        return item
    }
}

extension OIMUserInfo {
    public func toUserInfo() -> UserInfo {
        let item = UserInfo(userID: userID!)
        item.faceURL = faceURL
        item.nickname = nickname
        item.createTime = createTime
        item.ex = ex
        item.globalRecvMsgOpt = ReceiveMessageOpt(rawValue: globalRecvMsgOpt.rawValue) ?? .receive
        
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
        item.joinSource = JoinSource(rawValue: Int(joinSource.rawValue)) ?? .search
        item.inviterUserID = inviterUserID
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
        item.reqMsg = reqMsg
        item.handlerUserID = handlerUserID
        item.handleMsg = handleMsg
        item.handleTime = handleTime
        return item
    }
}

extension OIMFullUserInfo {
    public func toUserInfo() -> UserInfo {
        let item = UserInfo(userID: userID)
        item.faceURL = faceURL
        // 注意此处值类型的不对应
        item.nickname = showName

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
        item.isPrivateChat = isPrivateChat
        item.burnDuration = burnDuration
        item.ex = ex
        return item
    }
}

extension OIMMessageInfo {
    public func toMessageInfo() -> MessageInfo {
        let item = MessageInfo()
        item.clientMsgID = clientMsgID ?? ""
        item.serverMsgID = serverMsgID
        item.createTime = createTime
        item.sendTime = sendTime
        item.sessionType = sessionType.toConversationType()
        item.sendID = sendID ?? ""
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
        item.hasReadTime = hasReadTime
        item.offlinePushInfo = offlinePush.toOfflinePushInfo()
        item.textElem = textElem?.toTextElem()
        item.pictureElem = pictureElem?.toPictureElem()
        item.soundElem = soundElem?.toSoundElem()
        item.videoElem = videoElem?.toVideoElem()
        item.fileElem = fileElem?.toFileElem()
        item.mergeElem = mergeElem?.toMergeElem()
        item.atTextElem = atTextElem?.toAtTextElem()
        item.locationElem = locationElem?.toLocationElem()
        item.quoteElem = quoteElem?.toQuoteElem()
        item.customElem = customElem?.toCustomElem()
        item.notificationElem = notificationElem?.toNotificationElem()
        item.faceElem = faceElem?.toFaceElem()
        item.attachedInfoElem = attachedInfoElem?.toAttachedInfoElem()
        item.hasReadTime = hasReadTime
        item.cardElem = cardElem?.toCardElem()
        item.typingElem = typingElem?.toTypingElem()
        
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

extension OIMTextElem {
    func toTextElem() -> TextElem {
        let item = TextElem()
        item.content = content
        
        return item
    }
}

extension OIMCardElem {
    func toCardElem() -> CardElem {
        let item = CardElem(userID: userID, nickname: nickname, faceURL: faceURL)
        item.ex = ex
        
        return item
    }
}

extension OIMTypingElem {
    func toTypingElem() -> TypingElem {
        let item = TypingElem()
        item.msgTips = msgTips
        
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

extension OIMAtTextElem {
    func toAtTextElem() -> AtTextElem {
        let item = AtTextElem()
        item.text = text
        item.atUserList = atUserList
        item.atUsersInfo = atUsersInfo?.compactMap { $0.toAtInfo() }
        item.isAtSelf = isAtSelf
        item.quoteMessage = quoteMessage?.toMessageInfo()
        
        return item
    }
}

extension OIMAtInfo {
    func toAtInfo() -> AtInfo {
        let item = AtInfo(atUserID: atUserID!, groupNickname: groupNickname!)

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
        item.isPrivateChat = isPrivateChat
        item.burnDuration = burnDuration
        item.hasReadTime = hasReadTime
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

        return item
    }
}

extension OIMGroupMemberInfo {
    public func toGroupMemberInfo() -> GroupMemberInfo {
                
        let item = GroupMemberInfo()
        item.userID = userID
        item.roleLevel = GroupMemberRole(rawValue: roleLevel.rawValue) ?? .member
        item.groupID = groupID
        item.nickname = nickname
        item.faceURL = faceURL
        item.joinTime = joinTime
        item.joinSource = JoinSource(rawValue: Int(joinSource.rawValue)) ?? .search
        item.operatorUserID = operatorUserID
        item.inviterUserID = inviterUserID
        item.muteEndTime = muteEndTime
        item.ex = ex
        return item
    }
}

extension OIMGroupMemberRole {
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

extension OIMSearchFriendsInfo {
    func toSearchFriendsInfo() -> SearchUserInfo {
        let item = SearchUserInfo()
        item.relationship = Relationship(rawValue: relationship.rawValue) ?? .friends
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
        item.conversationType = ConversationType(rawValue: conversationType.rawValue) ?? .c2c
        item.showName = showName
        item.faceURL = faceURL
        item.messageList = messageList.compactMap { $0.toMessageInfo() }
        return item
    }
}

extension OIMMessageRevokedInfo {
    func toMessageRevoked() -> MessageRevoked {
        let item = MessageRevoked()
        item.clientMsgID = clientMsgID
        item.revokeTime = revokeTime
        item.revokerID = revokerID
        item.revokerNickname = revokerNickname
        item.revokerRole = GroupMemberRole(rawValue: revokerRole.rawValue) ?? .member
        item.sessionType = ConversationType(rawValue: sessionType.rawValue) ?? .c2c
        item.sourceMessageSendID = sourceMessageSendID
        item.sourceMessageSendTime = sourceMessageSendTime
        item.sourceMessageSenderNickname = sourceMessageSenderNickname
        
        return item
    }
}

extension OIMInvitationResultInfo {
    func toInvitationResultInfo() -> InvitationResultInfo {
        let item = InvitationResultInfo()
        item.roomID = roomID
        item.liveURL = liveURL
        item.token = token
        
        return item
    }
}

extension OIMMeetingInfoList {
    func toMeetingInfoList() -> MeetingInfoList {
        let item = MeetingInfoList()
        
        
        return item
    }
}

extension OIMMeetingInfo {
    func toMeetingInfo() -> MeetingInfo {
        let item = MeetingInfo()
        item.meetingID = meetingID
        item.meetingName = meetingName
        item.startTime = startTime
        item.endTime = endTime
        item.createTime = createTime
        item.hostUserID = hostUserID
        item.inviteeUserIDList = inviteeUserIDList
        item.isMuteAllMicrophone = isMuteAllMicrophone
        item.joinDisableVideo = joinDisableVideo
        item.onlyHostInviteUser = onlyHostInviteUser
        item.participantCanEnableVideo = participantCanEnableVideo
        item.participantCanUnmuteSelf = participantCanUnmuteSelf
        return item
    }
}

extension OIMMeetingStreamEvent {
    func toMeetingStreamEvent() -> MeetingStreamEvent {
        let item = MeetingStreamEvent()
        item.meetingID = meetingID
        item.mute = mute
        item.streamType = streamType
        
        return item
    }
}

extension OIMDepartmentInfo {
    func toDepartmentInfo() -> DepartmentInfo {
        let json = self.mj_JSONString()
        let item = JsonTool.fromJson(json!, toClass: DepartmentInfo.self)
        return item ?? DepartmentInfo()
    }
}

extension OIMDepartmentMemberInfo {
    func toDepartmentMemberInfo() -> DepartmentMemberInfo {
        let json = self.mj_JSONString()
        let item = JsonTool.fromJson(json!, toClass: DepartmentMemberInfo.self)
        return item ?? DepartmentMemberInfo()
    }
}

extension OIMUserInDepartmentInfo {
    func toUserInDepartmentInfo() -> UserInDepartmentInfo {
        let json = self.mj_JSONString()
        let item = JsonTool.fromJson(json!, toClass: UserInDepartmentInfo.self)
        return item ?? UserInDepartmentInfo()
    }
}

extension OIMDepartmentMemberAndSubInfo {
    func toDepartmentMemberAndSubInfo() -> DepartmentMemberAndSubInfo {
        let json = self.mj_JSONString()
        let item = JsonTool.fromJson(json!, toClass: DepartmentMemberAndSubInfo.self)
        return item ?? DepartmentMemberAndSubInfo()
    }
}

// MARK: - 模型转换(From OIMUIKit)

extension UserInfo {
    public func toOIMUserInfo() -> OIMUserInfo {
        let json = JsonTool.toJson(fromObject: self)
        if let item = OIMUserInfo.mj_object(withKeyValues: json) {
            return item
        }
        return OIMUserInfo()
    }
}

extension GroupInfo {
    func toOIMGroupInfo() -> OIMGroupInfo {
        let item = OIMGroupInfo()
        item.groupID = groupID
        item.faceURL = faceURL
        item.groupName = groupName
        item.introduction = introduction
        item.notification = notification
        item.lookMemberInfo = lookMemberInfo
        item.applyMemberFriend = applyMemberFriend
        item.needVerification = OIMGroupVerificationType(rawValue: needVerification.rawValue)!
        item.groupType = OIMGroupType(rawValue: groupType.rawValue)!
        
        return item
    }
}

public extension SearchParam {
    public func toOIMSearchParam() -> OIMSearchParam {
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

public extension SearchUserParam {
    func toOIMSearchUserParam() -> OIMSearchFriendsParam {
        let item = OIMSearchFriendsParam()
        item.keywordList = keywordList
        item.isSearchRemark = isSearchRemark
        item.isSearchNickname = isSearchNickname
        item.isSearchUserID = isSearchUserID
        
        return item
    }
}

public extension SearchGroupParam {
    func toOIMSearchGroupParam() -> OIMSearchGroupParam {
        let item = OIMSearchGroupParam()
        item.keywordList = keywordList
        item.isSearchGroupID = isSearchGroupID
        item.isSearchGroupName = isSearchGroupName
        
        return item
    }
}

extension MessageRevoked {
    func toOIMMessageRevoked() -> OIMMessageRevokedInfo {
        let json: String = JsonTool.toJson(fromObject: self)
        if let item = OIMMessageRevokedInfo.mj_object(withKeyValues: json) {
            return item
        }
        return OIMMessageRevokedInfo()
    }
}

extension InvitationResultInfo {
    public func toOIMInvitationResultInfo() -> OIMInvitationResultInfo {
        let json: String = JsonTool.toJson(fromObject: self)
        if let item = OIMInvitationResultInfo.mj_object(withKeyValues: json) {
            return item
        }
        return OIMInvitationResultInfo()
    }
}

extension SearchOrganizationParam {
    func toOIMSearchOrganizationParam() -> OIMSearchOrganizationParam {
        let json: String = JsonTool.toJson(fromObject: self)
        if let item = OIMSearchOrganizationParam.mj_object(withKeyValues: json) {
            return item
        }
        return OIMSearchOrganizationParam()
    }
}

extension CardElem {
    func toOIMCardElem() -> OIMCardElem {
        let json: String = JsonTool.toJson(fromObject: self)
        if let item = OIMCardElem.mj_object(withKeyValues: json) {
            return item
        }
        return OIMCardElem()
    }
}
