//


//




import Foundation
import OpenIMSDK
import RxSwift
import SVProgressHUD

public class IMController: NSObject {
    public static let shared: IMController = IMController()
    private(set) var imManager: OpenIMSDK.OIMManager!
    
    let friendApplicationChangedSubject: PublishSubject<FriendApplication> = .init()
    
    let groupApplicationChangedSubject: PublishSubject<GroupApplicationInfo> = .init()
    
    let conversationChangedSubject: BehaviorSubject<[ConversationInfo]> = .init(value: [])
    let friendInfoChangedSubject: BehaviorSubject<UserInfo?> = .init(value: nil)
    
    let syncServerStartSubject: PublishSubject<Void> = PublishSubject.init()
    let syncServerEndSubject: PublishSubject<Void> = PublishSubject.init()
    let newConversationSubject: BehaviorSubject<[ConversationInfo]> = .init(value: [])
    let totalUnreadSubject: BehaviorSubject<Int> = .init(value: 0)
    let newMsgReceivedSubject: PublishSubject<MessageInfo> = .init()
    let c2cReadReceiptReceived: BehaviorSubject<[ReceiptInfo]> = .init(value: [])
    let groupReadReceiptReceived: BehaviorSubject<[ReceiptInfo]> = .init(value: [])
    let msgRevokeReceived: PublishSubject<String> = .init()
    
    private(set) var uid: String = ""
    private(set) var user: UserInfo?
    public func setup(apiAdrr: String, wsAddr: String) {
        let manager = OpenIMSDK.OIMManager.init()
  
        manager.initSDK(withApiAdrr: apiAdrr, wsAddr: wsAddr, dataDir: nil, logLevel: 6, objectStorage: "minio", onConnecting: {
            
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
        
        OpenIMSDK.OIMManager.callbacker.addFriendListener(listener: self)
        OpenIMSDK.OIMManager.callbacker.addGroupListener(listener: self)
        OpenIMSDK.OIMManager.callbacker.addConversationListener(listener: self)
        OpenIMSDK.OIMManager.callbacker.addAdvancedMsgListener(listener: self)
        
        SVProgressHUD.setDefaultStyle(SVProgressHUDStyle.dark)
        SVProgressHUD.setMaximumDismissTimeInterval(1)
    }
    
    public func login(uid: String, token: String, onSuccess: @escaping (String?) -> Void, onFail: @escaping (Int, String?) -> Void) {
        Self.shared.imManager.login(uid, token: token) { [weak self] (resp: String?) in
            self?.uid = uid
            let event = EventLoginSucceed.init()
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
    
    typealias MessagesCallBack = (([MessageInfo]) -> Void)
}

extension IMController {
    
    
    
    func getGroupListBy(id: String) -> Observable<String?> {
        return Observable<String?>.create { observer in
            Self.shared.imManager.getGroupsInfo([id], onSuccess: { (groups: [OIMGroupInfo]?) in
                observer.onNext(groups?.first?.groupID)
                observer.onCompleted()
            }, onFailure: { (code: Int, msg: String?) in
                observer.onError(NetError.init(code: code, message: msg))
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

            let joined: [GroupInfo] = groups.compactMap{$0.toGroupInfo()}
            completion(joined)
        } onFailure: { (code, msg) in
            print("拉取我的群组错误,code:\(code), msg: \(msg)")
        }
    }
    
    
    
    
    func getFriendsBy(id: String) -> Observable<FullUserInfo?> {
        return Observable<FullUserInfo?>.create { observer in
            Self.shared.imManager.getUsersInfo([id]) { (users: [OIMFullUserInfo]?) in
                observer.onNext(users?.first?.toFullUserInfo())
                observer.onCompleted()
            } onFailure: { (code: Int, msg: String?) in
                observer.onError(NetError.init(code: code, message: msg))
            }
            return Disposables.create()
        }
    }
    
    
    
    func getFriendApplicationList(completion: @escaping ([FriendApplication]) -> Void) {
        Self.shared.imManager.getFriendApplicationListWith { (applications: [OIMFriendApplication]?) in
            let arr = applications ?? []
            let ret = arr.compactMap {$0.toFriendApplication()}
            completion(ret)
        }
    }
    
    
    
    
    
    
    func acceptFriendApplication(uid: String, handleMsg: String, completion: @escaping (String?) -> Void) {
        Self.shared.imManager.acceptFriendApplication(uid, handleMsg: handleMsg) { (resp: String?) in
            completion(resp)
        }
    }
    
    func getGroupApplicationList(completion: @escaping ([GroupApplicationInfo]) -> Void) {
        Self.shared.imManager.getGroupApplicationListWith { (applications: [OIMGroupApplicationInfo]?) in
            let arr = applications ?? []
            let ret = arr.compactMap {$0.toGroupApplicationInfo()}
            completion(ret)
        }
    }
    
    func getFriendList(completion: @escaping ([UserInfo]) -> Void) {
        Self.shared.imManager.getFriendListWith { (friends: [OIMFullUserInfo]?) in
            let arr = friends ?? []
            let ret = arr.compactMap {$0.toUserInfo()}
            completion(ret)
        }
    }
    
    func getGroupMemberList(groupId: String, filter: GroupMemberRole = .undefine, offset: Int, count: Int, onSuccess: @escaping CallBack.GroupMembersReturnVoid) {
        Self.shared.imManager.getGroupMemberList(groupId, filter: filter.rawValue, offset: offset, count: count) { (memberInfos: [OIMGroupMemberInfo]?) in
            let members: [GroupMemberInfo] = memberInfos?.compactMap {$0.toGroupMemberInfo()} ?? []
            onSuccess(members)
        }
    }
}

extension IMController {
    func getAllConversationList(completion: @escaping ([ConversationInfo]) -> Void) {
        Self.shared.imManager.getAllConversationListWith { (conversations: [OIMConversationInfo]?) in
            let arr = conversations ?? []
            let ret = arr.compactMap {$0.toConversationInfo()}
            completion(ret)
        }
    }
    
    func deleteConversationFromLocalStorage(conversationId: String, completion: ((String?) -> Void)?) {
        Self.shared.imManager.deleteConversation(fromLocalStorage: conversationId, onSuccess: completion)
    }
    
    func deleteConversation(conversationId: String, completion: ((String?) -> Void)?) {
        Self.shared.imManager.deleteConversation(conversationId, onSuccess: completion)
    }
    func getTotalUnreadMsgCount(completion: ((Int) -> Void)?) {
        Self.shared.imManager.getTotalUnreadMsgCountWith(onSuccess: completion, onFailure: nil)
    }
    func getConversationRecvMessageOpt(conversationIds: [String], completion: (([ConversationNotDisturbInfo]?) -> Void)?) {
        Self.shared.imManager.getConversationRecvMessageOpt(conversationIds) { (conversationInfos: [OIMConversationNotDisturbInfo]?) in
            let arr = conversationInfos?.compactMap{$0.toConversationNotDisturbInfo()}
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
            let arr = messages?.compactMap{$0.toMessageInfo()} ?? []
            completion(arr)
        }
    }
    
    func send(message: MessageInfo, to conversation: ConversationInfo, onComplete: @escaping CallBack.MessageReturnVoid) {
        let mMessage = message.toOIMMessageInfo()
        self.send(message: mMessage, to: conversation, onComplete: onComplete)
    }
    
    private func send(message: OIMMessageInfo, to conversation: ConversationInfo, onComplete: @escaping CallBack.MessageReturnVoid) {
        let model = message.toMessageInfo()
        model.isRead = false
        if let uid = conversation.userID, uid.isEmpty == false {
            Self.shared.imManager.sendMessage(message, recvID: uid, groupID: nil, offlinePushInfo: nil, onSuccess: { (resp: String?) in
                if let json = resp, let respMessage = OIMMessageInfo.mj_object(withKeyValues: json) {
                    onComplete(respMessage.toMessageInfo())
                } else {
                    model.status = .sendSuccess
                    onComplete(model)
                }
            }, onProgress: nil, onFailure: { (code: Int, msg: String?) in
                print("send message error:", msg)
                model.status = .sendFailure
                onComplete(model)
            })
        }
        
        if let gid = conversation.groupID, gid.isEmpty == false {
            Self.shared.imManager.sendMessage(message, recvID: nil, groupID: gid, offlinePushInfo: nil, onSuccess: { (resp: String?) in
                if let json = resp, let respMessage = OIMMessageInfo.mj_object(withKeyValues: json) {
                    onComplete(respMessage.toMessageInfo())
                } else {
                    model.status = .sendSuccess
                    onComplete(model)
                }
            }, onProgress: nil, onFailure: { (code: Int, msg: String?) in
                print("send message error:", msg)
                model.status = .sendFailure
                onComplete(model)
            })
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
            let message = OIMMessageInfo.createImageMessage(result.filePath)
            message.status = .sending
            sending(message.toMessageInfo())
            send(message: message, to: conversation, onComplete: onComplete)
        }
    }
    
    func sendVideoMessage(videoPath: URL, duration: Int, snapshotPath: String, to conversation: ConversationInfo, sending: CallBack.MessageReturnVoid, onComplete: @escaping CallBack.MessageReturnVoid) {
        let result: FileHelper.FileWriteResult = FileHelper.shared.saveVideoFrom(videoPath: videoPath.path)
        if result.isSuccess {
            let message = OIMMessageInfo.createVideoMessage(result.filePath, videoType: "mp4", duration: duration, snapshotPath: snapshotPath)
            message.status = .sending
            sending(message.toMessageInfo())
            send(message: message, to: conversation, onComplete: onComplete)
        }
    }
    
    func sendAudioMessage(audioPath: String, duration: Int, to conversation: ConversationInfo, sending: CallBack.MessageReturnVoid, onComplete: @escaping CallBack.MessageReturnVoid) {
        let result: FileHelper.FileWriteResult = FileHelper.shared.saveAudioFrom(audioPath: audioPath)
        if result.isSuccess {
            let message = OIMMessageInfo.createSoundMessage(result.filePath, duration: duration)
            message.status = .sending
            sending(message.toMessageInfo())
            send(message: message, to: conversation, onComplete: onComplete)
        }
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
    
    func createConversation(users: [UserInfo], onSuccess: @escaping CallBack.GroupInfoOptionalReturnVoid) {
        var members: [OIMGroupMemberInfo] = []
        for user in users {
            let memberInfo = OIMGroupMemberInfo.init()
            memberInfo.userID = user.userID
            memberInfo.roleLevel = .member
            members.append(memberInfo)
        }
        
        let me = OIMGroupMemberInfo.init()
        me.userID = self.uid
        me.faceURL = self.user?.faceURL
        me.nickname = self.user?.nickname
        me.roleLevel = .super
        members.append(me)
        
        let createInfo = OIMGroupCreateInfo.init()
        createInfo.groupName = me.nickname?.append(string: "创建的群聊")
        
        createInfo.groupType = users.count > 1 ? 2 : 1
        Self.shared.imManager.createGroup(createInfo, memberList: members) { (groupInfo: OIMGroupInfo?) in
            print("创建群聊成功")
            onSuccess(groupInfo?.toGroupInfo())
        }
    }
}


extension IMController {
    func getConversation(sessionType: ConversationType, sourceId: String, onSuccess: @escaping CallBack.ConversationInfoOptionalReturnVoid) {
        let conversationType = OIMConversationType.init(rawValue: sessionType.rawValue) ?? OIMConversationType.undefine
        Self.shared.imManager.getOneConversation(withSessionType: conversationType, sourceID: sourceId) { (conversation: OIMConversationInfo?) in
            onSuccess(conversation?.toConversationInfo())
        } onFailure: { code, msg in
            print("创建会话失败:\(code), .msg:\(msg)")
        }
    }
}


extension IMController {
    
    func getSelfInfo(onSuccess: @escaping CallBack.UserInfoOptionalReturnVoid) {
        Self.shared.imManager.getSelfInfoWith { [weak self] (userInfo: OIMUserInfo?) in
            let user = userInfo?.toUserInfo()
            self?.user = user
            onSuccess(user)
        } onFailure: { code, msg in
            print("拉取登录用户信息失败:\(code), msg:\(msg)")
        }
    }
    
    func getUserInfo(uids: [String], onSuccess: @escaping CallBack.FullUserInfosReturnVoid) {
        Self.shared.imManager.getUsersInfo(uids) { (userInfos: [OIMFullUserInfo]?) in
            let users = userInfos?.compactMap{$0.toFullUserInfo()} ?? []
            onSuccess(users)
        }
    }
}


extension IMController: OIMFriendshipListener {
    public func onFriendApplicationAdded(_ application: FriendApplication) {
        friendApplicationChangedSubject.onNext(application)
    }
}

extension IMController: OIMGroupListener {
    public func onGroupApplicationAdded(_ groupApplication: GroupApplicationInfo) {
        groupApplicationChangedSubject.onNext(groupApplication)
    }
}

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
        let arr = conversations.compactMap{$0.toConversationInfo()}
        newConversationSubject.onNext(arr)
    }
    
    public func onTotalUnreadMessageCountChanged(_ totalUnreadCount: Int) {
        totalUnreadSubject.onNext(totalUnreadCount)
    }
}


extension IMController: OIMAdvancedMsgListener {
    public func onRecvNewMessage(_ msg: OIMMessageInfo) {
        newMsgReceivedSubject.onNext(msg.toMessageInfo())
    }
    
    public func onRecvC2CReadReceipt(_ receiptList: [OIMReceiptInfo]) {
        c2cReadReceiptReceived.onNext(receiptList.compactMap{$0.toReceiptInfo()})
    }
    
    public func onRecvGroupReadReceipt(_ groupMsgReceiptList: [OIMReceiptInfo]) {
        groupReadReceiptReceived.onNext(groupMsgReceiptList.compactMap{$0.toReceiptInfo()})
    }
    
    public func onRecvMessageRevoked(_ msgID: String) {
        msgRevokeReceived.onNext(msgID)
    }
}



public class UserInfo {
    var userID: String = ""
    var nickname: String?
    var faceURL: String?
}

public class FriendApplication {
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


public enum ApplicationStatus: Int {
    
    case decline = -1
    
    case normal = 0
    
    case accept = 1
}

public enum ReceiveMessageOpt: Int {
    
    case receive = 0
    
    case notReceive = 1
    
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
    
    var seq: Int = 0
    var isRead: Bool = false
    var status: MessageStatus = .undefine
    var attachedInfo: String?
    var ex: String?
    var offlinePushInfo: OfflinePushInfo = OfflinePushInfo()
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
        if contentType == .text {
            return content
        }
        return contentType.abstruct
    }
    
    
}

public class GroupMemberBaseInfo: Encodable {
    var userID: String?
    var roleLevel: GroupMemberRole = .undefine
}

public enum GroupMemberRole: Int, Encodable {
    case undefine = 0
    case member = 1
    
    case `super` = 2
    case admin = 3
}

public class GroupMemberInfo: GroupMemberBaseInfo {
    var groupID: String?
    var nickname: String?
    var faceURL: String?
    var joinTime: Int = 0
    var joinSource: Int = 0
    var operatorUserID: String?
    var ex: String?
}

public enum MessageContentType: Int, Encodable {
    case unknown = -1
    
    case text = 101
    case image
    case audio
    case video
    case file
    
    case at
    
    case merge
    
    case card
    case location
    case custom
    
    case revokeReciept
    
    case C2CReciept
    
    case typing
    case quote
    
    case face
    
    
    case friendAppApproved = 1201
    case friendAppRejected
    case friendApplication
    case friendAdded
    case friendDeleted
    
    case friendRemarkSet
    case blackAdded
    case blackDeleted
    
    case conversationOptChange = 1300
    case userInfoUpdated = 1303
    
    case conversationNotification = 1307
    
    case conversationNotNotification
    case groupCreated = 1501
    
    case groupInfoSet
    case joinGroupApplication
    case memberQuit
    case groupAppAccepted
    case groupAppRejected
    
    case groupOwnerTransferred
    case memberKicked
    case memberInvited
    case memberEnter
    
    case dismissGroup
    
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

public enum MessageStatus: Int, Encodable {
    case undefine = 0
    case sending
    case sendSuccess
    case sendFailure
    case deleted
    case revoke
}

public enum MessageLevel: Int, Encodable {
    case undefine = -1
    case user = 100
    case system = 200
}

public enum ConversationType: Int, Encodable {
    
    case undefine
    
    case c2c
    
    case group
}

public class GroupBaseInfo: Encodable {
    var groupName: String?
    var introduction: String?
    var faceURL: String?
}

public class GroupInfo: GroupBaseInfo {
    var groupID: String = ""
    var ownerUserID: String?
    var createTime:Int = 0
    var memberCount: Int = 0
    var creatorUserID: String?
}

public class ConversationNotDisturbInfo {
    let conversationId: String
    var result: ReceiveMessageOpt = .receive
    init(conversationId: String) {
        self.conversationId = conversationId
    }
}

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

public class OfflinePushInfo: Encodable {
    var title: String?
    var desc: String?
    var iOSPushSound: String?
    var iOSBadgeCount: Bool = false
    var operatorUserID: String?
    var ex: String?
}

public class PictureElem: Encodable {
    
    var sourcePath: String?
    
    var sourcePicture: PictureInfo?
    
    var bigPicture: PictureInfo?
    
    var snapshotPicture: PictureInfo?
}

public class PictureInfo: Encodable {
    var uuID: String?
    var type: String?
    var size: Int = 0
    var width: CGFloat = 0
    var height: CGFloat = 0
    
    var url: String?
}

public class SoundElem: Encodable {
    var uuID: String?
    
    var soundPath: String?
    
    var sourceUrl: String?
    var dataSize: Int = 0
    var duration: Int = 0
}

public class VideoElem: Encodable {
    var videoUUID: String?
    var videoPath: String?
    var videoUrl: String?
    var videoType: String?
    var videoSize: Int = 0
    var duration: Int = 0
    
    var snapshotPath: String?
    
    var snapshotUUID: String?
    var snapshotSize: Int = 0
    
    var snapshotUrl: String?
    var snapshotWidth: CGFloat = 0
    var snapshotHeight: CGFloat = 0
}

public class FileElem: Encodable {
    var filePath: String?
    var uuID: String?
    
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

struct BusinessCard: Decodable {
    let faceURL: String?
    let nickname: String?
    let userID: String
}

class ReceiptInfo {
    var userID: String?
    var groupID: String?
    
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
}

class PublicUserInfo {
    var userID: String?
    var nickname: String?
    var faceURL: String?
}

class FriendInfo: PublicUserInfo {
    var ownerUserID: String?
    var remark: String?
}

class BlackInfo: PublicUserInfo {
    var operatorUserID: String?
    var createTime: Int = 0
}


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
        let type = OIMMessageContentType.init(rawValue: self.rawValue) ?? OIMMessageContentType.text
        return type
    }
}
extension OIMGroupInfo {
    func toGroupInfo() -> GroupInfo {
        let item = GroupInfo()
        item.groupID = self.groupID ?? ""
        item.faceURL = self.faceURL
        item.createTime = self.createTime
        item.creatorUserID = self.creatorUserID
        item.memberCount = self.memberCount
        item.ownerUserID = self.ownerUserID
        item.introduction = self.introduction
        item.groupName = self.groupName
        return item
    }
}

extension OIMUserInfo {
    func toUserInfo() -> UserInfo {
        let item = UserInfo.init()
        item.faceURL = self.faceURL
        item.nickname = self.nickname
        item.userID = self.userID ?? ""
        return item
    }
}

extension OIMGroupApplicationInfo {
    func toGroupApplicationInfo() -> GroupApplicationInfo {
        let item = GroupApplicationInfo()
        item.groupID = self.groupID ?? ""
        item.groupName = self.groupName
        item.groupFaceURL = self.groupFaceURL
        item.creatorUserID = self.creatorUserID ?? ""
        item.ownerUserID = self.ownerUserID ?? ""
        item.memberCount = self.memberCount
        item.userID = self.userID
        item.nickname = self.nickname
        item.userFaceURL = self.userFaceURL
        item.reqMsg = self.reqMsg
        item.reqTime = self.reqTime
        item.handleUserID = self.handleUserID
        item.handledMsg = self.handledMsg
        item.handledTime = self.handledTime
        item.handleResult = ApplicationStatus.init(rawValue: self.handleResult.rawValue) ?? .normal
        return item
    }
}

extension OIMFriendApplication {
    func toFriendApplication() -> FriendApplication {
        let item = FriendApplication()
        item.fromUserID = self.fromUserID ?? ""
        item.fromNickname = self.fromNickname
        item.fromFaceURL = self.fromFaceURL
        item.toUserID = self.toUserID ?? ""
        item.toNickname = self.toNickname
        item.toFaceURL = self.toFaceURL
        item.handleResult = ApplicationStatus.init(rawValue: self.handleResult.rawValue) ?? .normal
        
        item.reqMsg = self.ex
        item.handlerUserID = self.handlerUserID
        item.handleMsg = self.handleMsg
        item.handleTime = self.handleTime
        return item
    }
}

extension OIMFullUserInfo {
    func toUserInfo() -> UserInfo {
        let item = UserInfo.init()
        item.faceURL = self.faceURL
        
        item.nickname = self.showName
        item.userID = self.userID ?? ""
        return item
    }
}

extension OIMConversationInfo {
    func toConversationInfo() -> ConversationInfo {
        let item = ConversationInfo.init(conversationID: self.conversationID ?? "")
        item.userID = self.userID
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
        item.offlinePushInfo = offlinePushInfo.toOfflinePushInfo()
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
        let item = MessageContentType.init(rawValue: self.rawValue) ?? MessageContentType.unknown
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
        item.multiMessage = multiMessage?.compactMap{$0.toMessageInfo()}
        return item
    }
}

extension OIMAtElem {
    func toAtElem() -> AtElem {
        let item = AtElem()
        item.text = text
        item.atUserList = atUserList
        item.atUsersInfo = atUsersInfo?.compactMap{$0.toAtInfo()}
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
        item.description = self.description
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
                                    kickedUserList: kickedUserList?.compactMap{$0.toGroupMemberInfo()},
                                    invitedUserList: invitedUserList?.compactMap{$0.toGroupMemberInfo()})
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
        item.joinSource = joinSource
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
        let item = ConversationNotDisturbInfo.init(conversationId: conversationID ?? "")
        item.result = result.toReceiveMessageOpt()
        return item
    }
}

extension OIMReceiptInfo {
    func toReceiptInfo() -> ReceiptInfo {
        let item = ReceiptInfo()
        item.userID = self.userID
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
        return item
    }
}

extension OIMBlackInfo {
    func toBlackInfo() -> BlackInfo {
        let item = BlackInfo()
        item.operatorUserID = operatorUserID
        item.createTime = createTime
        item.userID = userID
        item.faceURL = faceURL
        item.nickname = nickname
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
        return item
    }
}

extension OIMPublicUserInfo {
    func toPublicUserInfo() -> PublicUserInfo {
        let item = PublicUserInfo()
        item.userID = userID
        item.nickname = nickname
        item.faceURL = faceURL
        return item
    }
}
