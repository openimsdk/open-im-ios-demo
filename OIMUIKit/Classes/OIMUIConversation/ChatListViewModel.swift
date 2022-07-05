
import Foundation
import RxRelay
import RxSwift

class ChatListViewModel {
    let conversationsRelay: BehaviorRelay<[ConversationInfo]> = .init(value: [])
    let loginUserPublish: PublishSubject<UserInfo?> = .init()

    private func getSelfInfo(onSuccess: @escaping CallBack.UserInfoOptionalReturnVoid) {
        IMController.shared.getSelfInfo(onSuccess: onSuccess)
    }

    func getSelfInfo() {
        IMController.shared.getSelfInfo { [weak self] (userInfo: UserInfo?) in
            self?.loginUserPublish.onNext(userInfo)
        }
    }

    func getAllConversations() {
        IMController.shared.getAllConversationList { [weak self] (conversations: [ConversationInfo]) in
            guard let sself = self else { return }
            sself.sortConversations(conversations)
        }
    }

    func setConversation(id: String, status: ReceiveMessageOpt) {
        IMController.shared.setConversationRecvMessageOpt(conversationIds: [id], status: status, completion: nil)
    }

    func pinConversation(id: String, isPinned: Bool, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        IMController.shared.pinConversation(id: id, isPinned: isPinned) { [weak self] (resp: String?) in
            self?.getAllConversations()
            onSuccess(resp)
        }
    }

    /// 删除指定会话（本地删除）
    func deleteConversationFromLocalStorage(conversationId: String, completion: ((String?) -> Void)?) {
        IMController.shared.deleteConversationFromLocalStorage(conversationId: conversationId) { [weak self] (resp: String?) in
            self?.getAllConversations()
            completion?(resp)
        }
    }

    init() {
        IMController.shared.newConversationSubject.subscribe(onNext: { [weak self] (conversations: [ConversationInfo]) in
            guard let sself = self else { return }
            var origin = sself.conversationsRelay.value
            origin.append(contentsOf: conversations)
            self?.sortConversations(origin)
        }).disposed(by: _disposeBag)

        IMController.shared.conversationChangedSubject.subscribe(onNext: { [weak self] (conversations: [ConversationInfo]) in
            guard let sself = self else { return }
            let changedIds: [String] = conversations.compactMap { $0.conversationID }
            var origin = sself.conversationsRelay.value
            var ret = origin.filter { (chat: ConversationInfo) -> Bool in
                !changedIds.contains(chat.conversationID)
            }
            ret.append(contentsOf: conversations)
            self?.sortConversations(ret)
        })

        JNNotificationCenter.shared.observeEvent { [weak self] (_: EventLoginSucceed) in
            self?.getAllConversations()
            self?.getSelfInfo(onSuccess: { (userInfo: UserInfo?) in
                self?.loginUserPublish.onNext(userInfo)
            })
        }.disposed(by: _disposeBag)

        JNNotificationCenter.shared.observeEvent { [weak self] (_: EventRecordClear) in
            self?.getAllConversations()
        }
    }

    private func sortConversations(_ conversations: [ConversationInfo]) {
        var sorted = conversations.sorted { (lhs: ConversationInfo, rhs: ConversationInfo) in
            lhs.latestMsgSendTime > rhs.latestMsgSendTime
        }
        var pinned: [ConversationInfo] = []
        var normal: [ConversationInfo] = []
        for conversation in sorted {
            if conversation.isPinned {
                pinned.append(conversation)
            } else {
                normal.append(conversation)
            }
        }
        pinned.append(contentsOf: normal)
        conversationsRelay.accept(pinned)
    }

    private let _disposeBag = DisposeBag()
}
