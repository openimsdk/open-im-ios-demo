
import OUICore
import RxSwift
import RxRelay

class UserDetailViewModel {
    let userId: String
    let groupId: String?
    let groupInfo: GroupInfo?
    
    let userInfoRelay: BehaviorRelay<FullUserInfo?> = .init(value: nil)
    var memberInfoRelay: BehaviorRelay<GroupMemberInfo?> = .init(value: nil)
    var showSetAdmin: Bool = false
    var showJoinSource: Bool = false
    var showMute: Bool = false
    var userDetailFor = UserDetailFor.groupMemberInfo

    private let _disposeBag = DisposeBag()
    init(userId: String, groupId: String?, groupInfo: GroupInfo? = nil, userDetailFor: UserDetailFor) {
        self.userId = userId
        self.groupId = groupId
        self.groupInfo = groupInfo
        self.userDetailFor = userDetailFor
        
        IMController.shared.friendInfoChangedSubject.subscribe { [weak self] (friendInfo: FriendInfo?) in
            guard let sself = self else { return }
            guard friendInfo?.userID == sself.userId else { return }
            let user = sself.userInfoRelay.value?.friendInfo
            user?.nickname = friendInfo?.nickname
            if let gender = friendInfo?.gender {
                user?.gender = gender
            }
            user?.phoneNumber = friendInfo?.phoneNumber
            if let birth = friendInfo?.birth {
                user?.birth = birth
            }
            user?.email = friendInfo?.email
            user?.remark = friendInfo?.remark
            let fullUser = self?.userInfoRelay.value
            fullUser?.friendInfo = user
            self?.userInfoRelay.accept(fullUser)
        }.disposed(by: _disposeBag)
    }

    func getUserOrMemberInfo() {

        let group = DispatchGroup()
        
        var userInfo: FullUserInfo?
        var memberInfo: GroupMemberInfo?

        group.enter()
        IMController.shared.getUserInfo(uids: [userId]) { users in
            userInfo = users.first
            group.leave()
        }
        
        if let groupId = groupId, !groupId.isEmpty, userDetailFor == .groupMemberInfo {
            group.enter()
            // 如果群聊点击的是自己
            var isSelf = IMController.shared.uid == userId
            IMController.shared.getGroupMembersInfo(groupId: groupId,
                                                    uids: isSelf ? [userId] : [IMController.shared.uid, userId]) { [weak self] (members: [GroupMemberInfo]) in
                guard let mine = members.first(where: { $0.userID == IMController.shared.uid}), let sself = self else {
                    group.leave()
                    return
                }
                memberInfo = members.first(where: { $0.userID == sself.userId})
                
                if !isSelf {
                    if mine.roleLevel == .owner {
                        sself.showMute = true
                        sself.showSetAdmin = true
                        sself.showJoinSource = true
                    } else if mine.roleLevel == .admin {
                        sself.showMute = true
                        sself.showJoinSource = true
                    }
                    
                    IMController.shared.getUserInfo(uids: [memberInfo!.inviterUserID!]) { users in
                        memberInfo!.inviterUserName = users.first?.showName
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            self?.memberInfoRelay.accept(memberInfo)
            self?.userInfoRelay.accept(userInfo)
        }
    }

    func createSingleChat(onComplete: @escaping (ConversationInfo) -> Void) {
        IMController.shared.getConversation(sessionType: .c2c, sourceId: userId) { [weak self] (conversation: ConversationInfo?) in
            guard let conversation else { return }

            onComplete(conversation)
        }
    }

    func addFriend(onSuccess: @escaping CallBack.StringOptionalReturnVoid, onFailure: @escaping CallBack.ErrorOptionalReturnVoid) {
        let reqMsg = "\(IMController.shared.currentUserRelay.value!.nickname!)请求添加你为好友"
        IMController.shared.addFriend(uid: userId, reqMsg: reqMsg, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    func toggleSetAdmin(toAdmin: Bool, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        IMController.shared.setGroupMemberRoleLevel(groupId: groupId!, userID: userId, roleLevel: toAdmin ? .admin : .member, onSuccess: onSuccess)
    }
    
    func setMutedSeconds(seconds: Int, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        guard let groupId = groupId else {
            return
        }

        IMController.shared.changeGroupMemberMute(groupID: groupId, userID: userId, seconds: seconds) { [weak self] r in
            
            guard let sself = self else { return }
            var info = sself.memberInfoRelay.value!
            info.muteEndTime = NSDate().timeIntervalSince1970 + Double(seconds)
            sself.memberInfoRelay.accept(info)
            
            onSuccess(r)
        }
    }
    deinit {
        #if DEBUG
            print("dealloc \(type(of: self))")
        #endif
    }
}
