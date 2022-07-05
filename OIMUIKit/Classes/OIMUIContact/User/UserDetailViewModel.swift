
import Foundation
import RxSwift

class UserDetailViewModel {
    let userId: String
    let groupId: String?

    let userInfoRelay: PublishSubject<FullUserInfo?> = .init()
    let memberInfoRelay: PublishSubject<GroupMemberInfo?> = .init()

    init(userId: String, groupId: String?) {
        self.userId = userId
        self.groupId = groupId
    }

    func getUserOrMemberInfo() {
        if let groupId = groupId, groupId.isEmpty == false {
            IMController.shared.getGroupMembersInfo(groupId: groupId, uids: [userId]) { [weak self] (members: [GroupMemberInfo]) in
                self?.memberInfoRelay.onNext(members.first)
            }
        } else {
            IMController.shared.getUserInfo(uids: [userId]) { [weak self] (users: [FullUserInfo]) in
                self?.userInfoRelay.onNext(users.first)
            }
        }
    }

    func createSingleChat(onComplete: @escaping (MessageListViewModel) -> Void) {
        IMController.shared.getConversation(sessionType: .c2c, sourceId: userId) { [weak self] (conversation: ConversationInfo?) in
            guard let sself = self else { return }
            guard let conversation = conversation else {
                return
            }

            let model = MessageListViewModel(userId: sself.userId, conversation: conversation)
            onComplete(model)
        }
    }

    func addFriend(onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        let reqMsg = "默认的添加好友请求信息"
        IMController.shared.addFriend(uid: userId, reqMsg: reqMsg, onSuccess: onSuccess)
    }

    deinit {
        #if DEBUG
            print("dealloc \(type(of: self))")
        #endif
    }
}
