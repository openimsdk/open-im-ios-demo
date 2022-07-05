
import Foundation
import RxRelay

class SingleChatSettingViewModel {
    private(set) var conversation: ConversationInfo

    let membesRelay: BehaviorRelay<[UserInfo]> = .init(value: [])
    let noDisturbRelay: BehaviorRelay<Bool> = .init(value: false)
    let setTopContactRelay: BehaviorRelay<Bool> = .init(value: false)

    init(conversation: ConversationInfo) {
        self.conversation = conversation
    }

    private func publishConversationInfo() {
        noDisturbRelay.accept(conversation.recvMsgOpt == .notNotify)
        setTopContactRelay.accept(conversation.isPinned)
    }

    func getConversationInfo() {
        guard let userId = conversation.userID else { return }

        IMController.shared.getConversation(sessionType: conversation.conversationType, sourceId: userId) { [weak self] (chat: ConversationInfo?) in
            if let chat = chat {
                self?.conversation = chat
                self?.publishConversationInfo()
            }
        }

        IMController.shared.getUserInfo(uids: [userId]) { [weak self] (userInfos: [FullUserInfo]) in
            if let user = userInfos.first {
                let userInfo = UserInfo()
                userInfo.userID = user.userID ?? ""
                userInfo.faceURL = user.faceURL
                userInfo.nickname = user.showName
                // the fake user will be shown as an add btn
                let fakeUser = UserInfo()
                fakeUser.isButton = true
                self?.membesRelay.accept([userInfo, fakeUser])
            }
        }
    }

    func clearRecord(completion: @escaping CallBack.StringOptionalReturnVoid) {
        guard let uid = conversation.userID else { return }
        IMController.shared.clearC2CHistoryMessages(userId: uid) { [weak self] resp in
            guard let sself = self else { return }
            let event = EventRecordClear(conversationId: sself.conversation.conversationID)
            JNNotificationCenter.shared.post(event)
            completion(resp)
        }
    }

    func toggleTopContacts() {
        IMController.shared.pinConversation(id: conversation.conversationID, isPinned: setTopContactRelay.value, completion: { [weak self] _ in
            guard let sself = self else { return }
            sself.setTopContactRelay.accept(!sself.setTopContactRelay.value)
        })
    }

    func toggleNoDisturb() {
        let receiveOpt: ReceiveMessageOpt = !noDisturbRelay.value == true ? .notNotify : .receive
        IMController.shared.setConversationRecvMessageOpt(conversationIds: [conversation.conversationID], status: receiveOpt, completion: { [weak self] _ in
            guard let sself = self else { return }
            self?.noDisturbRelay.accept(!sself.noDisturbRelay.value)
        })
    }
}

var UserInfoExtensionKey: String?
extension UserInfo {
    var isButton: Bool {
        set {
            objc_setAssociatedObject(self, &UserInfoExtensionKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }

        get {
            let value: Bool = objc_getAssociatedObject(self, &UserInfoExtensionKey) as? Bool ?? false
            return value
        }
    }
}
