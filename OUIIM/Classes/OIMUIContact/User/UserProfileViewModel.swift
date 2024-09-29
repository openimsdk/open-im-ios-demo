
import OUICore
import RxSwift
import RxRelay

class UserProfileViewModel {
    let userId: String
    let groupId: String?
    
    let userInfoRelay: BehaviorRelay<UserInfo?> = .init(value: nil)
    let memberInfoRelay: PublishSubject<GroupMemberInfo?> = .init()
    let isInBlackListRelay: PublishSubject<Bool> = .init()
    
    init(userId: String, groupId: String?) {
        self.userId = userId
        self.groupId = groupId
    }
    
    func getUserOrMemberInfo() {
        if let groupId = groupId, groupId.isEmpty == false {
            IMController.shared.getGroupMembersInfo(groupId: groupId, uids: [userId]) { [weak self] (members: [GroupMemberInfo]) in
                self?.memberInfoRelay.onNext(members.first)
            }
        }
        
        if let handler = OIMApi.queryUsersInfoWithCompletionHandler {
            handler([userId], { [weak self] users in
                if let u = users.first {
                    self?.userInfoRelay.accept(u)
                }
            })
        } else {
            IMController.shared.getUserInfo(uids: [userId]) { [weak self] users in
                var user: UserInfo!
                
                if let u = users.first {
                    user = UserInfo(userID: u.userID!,
                                    nickname: u.nickname,
                                    faceURL: u.faceURL)
                    self?.userInfoRelay.accept(user)
                }
            }
        }
        
        IMController.shared.getBlackList {[weak self] blackUsers in
            if blackUsers.contains(where: { info in
                info.userID == self?.userId
            }) {
                self?.isInBlackListRelay.onNext(true)
            }
        }
    }
    
    func addFriend(onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        let reqMsg = "\(IMController.shared.currentUserRelay.value!.nickname)请求添加你为好友"
        IMController.shared.addFriend(uid: userId, reqMsg: reqMsg, onSuccess: onSuccess)
    }
    
    func saveRemark(remark: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid)  {
        IMController.shared.setFriend(uid: userId, remark: remark, onSuccess: onSuccess)
    }
    
    func sendCard(cardUser: UserInfo, to recvID: String, conversationType: ConversationType = .c2c) {
        let card = CardElem(userID: cardUser.userID, nickname: cardUser.nickname!, faceURL: cardUser.faceURL)
        
        IMController.shared.sendCardMessage(card: card,
                                            to: recvID,
                                            conversationType: conversationType,
                                            sending: { [weak self] (model: MessageInfo) in
            //            self?.addMessage(model)
        }, onComplete: { [weak self] (model: MessageInfo) in
            //            self?.updateMessage(model)
        })
    }
    
    func blockUser(blocked: Bool, onSuccess: @escaping CallBack.StringOptionalReturnVoid){
        IMController.shared.blockUser(uid: userId, blocked: blocked, onSuccess: onSuccess)
    }
    
    func deleteFriend(onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        IMController.shared.deleteFriend(uid: userId) { [weak self] res in
            guard let `self` = self else { return }
            IMController.shared.getConversation(sessionType: .c2c, sourceId: userId) { conv in
                guard let conv else { return }
                IMController.shared.deleteConversation(conversationID: conv.conversationID) { r in
                    onSuccess(res)
                }
            }
        }
    }
    
    deinit {
#if DEBUG
        print("dealloc \(type(of: self))")
#endif
    }
}
