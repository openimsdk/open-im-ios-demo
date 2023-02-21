
import Foundation
import RxRelay
import RxSwift

class MessageListViewModel {
    let messagesRelay: BehaviorRelay<[MessageInfo]> = .init(value: [])

    let typingRelay: BehaviorRelay<Bool> = .init(value: false)

    let scrollsToBottom: PublishSubject<Void> = .init()

    let shouldHideSettingBtnSubject: PublishSubject<Bool> = .init()
    let onlyInputTextRelay: BehaviorRelay<Bool> = .init(value: false) // 仅仅支持文本

    let conversation: ConversationInfo
    // 机器人ID
    var robots: [String] = []

    var isRobot: Bool {
        if let userId = userId {
            return self.robots.contains(userId)
        }
        return false
    }

    private let _disposeBag = DisposeBag()

    private var userId: String?
    init(userId: String?, conversation: ConversationInfo) {
        self.userId = userId
        self.conversation = conversation
        addObservers()
        
        if let configHandler = OIMApi.queryConfigHandler {
            configHandler { [weak self] result in
                if let `self` = self,  result != nil, let robots = result["robots"] as? [String] {
                    self.robots = robots
                    self.onlyInputTextRelay.accept(self.isRobot)
                }
            }
        }
    }

    private var groupId: String?
    private let ignoreStateMessageTypes: [MessageContentType] = [.typing]
    init(groupId: String, conversation: ConversationInfo) {
        self.groupId = groupId
        self.conversation = conversation
        addObservers()
    }

    private func addObservers() {
        IMController.shared.newMsgReceivedSubject.subscribe(onNext: { [weak self] (message: MessageInfo) in
            guard let sself = self else { return }
            if let userId = sself.userId, userId == message.sendID {
                if sself.ignoreStateMessageTypes.contains(message.contentType) {
                    switch message.contentType {
                    case .typing:
                        let isTyping = message.content == "yes"
                        self?.typingRelay.accept(isTyping)
                    default:
                        break
                    }
                    return
                }
                sself.addMessage(message)
                sself.updateMessage(message)
                let msgIdList = [message.clientMsgID ?? ""]
                IMController.shared.markC2CMessageReaded(userId: userId, msgIdList: msgIdList)
                return
            }

            if let groupId = sself.groupId, groupId == message.groupID {
                sself.addMessage(message)
                sself.updateMessage(message)
                let msgIdList = [message.clientMsgID ?? ""]
                IMController.shared.markGroupMessageReaded(groupId: groupId, msgIdList: msgIdList)
            }
        }).disposed(by: _disposeBag)

        if userId != nil {
            IMController.shared.c2cReadReceiptReceived.subscribe(onNext: { [weak self] (receiptInfos: [ReceiptInfo]) in
                var msgIds: [String] = []
                for receiptInfo in receiptInfos {
                    let ids: [String] = receiptInfo.msgIDList?.compactMap { $0 } ?? []
                    msgIds.append(contentsOf: ids)
                }
                if !msgIds.isEmpty {
                    self?.markMessagesReaded(msgIds: msgIds)
                }
            }).disposed(by: _disposeBag)
        }

        if groupId != nil {
            IMController.shared.groupReadReceiptReceived.subscribe(onNext: { [weak self] (receiptInfos: [ReceiptInfo]) in
                var msgIds: [String] = []
                for receiptInfo in receiptInfos {
                    let ids: [String] = receiptInfo.msgIDList?.compactMap { $0 } ?? []
                    msgIds.append(contentsOf: ids)
                }
                if !msgIds.isEmpty {
                    self?.markMessagesReaded(msgIds: msgIds)
                }
            }).disposed(by: _disposeBag)
        }

        IMController.shared.msgRevokeReceived.subscribe(onNext: { [weak self] (messageId: String) in
            self?.removeMessage(messageId: messageId)
        }).disposed(by: _disposeBag)

        JNNotificationCenter.shared.observeEvent { [weak self] (event: EventRecordClear) in
            guard let sself = self else { return }
            if event.conversationId == sself.conversation.conversationID {
                self?.messagesRelay.accept([])
            }
        }

        JNNotificationCenter.shared.observeEvent { [weak self] (event: EventGroupDismissed) in
            guard let sself = self else { return }
            if event.conversationId == sself.conversation.conversationID {
                self?.shouldHideSettingBtnSubject.onNext(true)
            }
        }
    }

    func markAllMessageReaded() {
        if let userId = userId {
            IMController.shared.imManager.markC2CMessage(asRead: userId, msgIDList: []) { _ in
                print("标记单聊所有消息已读")
            }
            return
        }

        if let groupId = groupId {
            IMController.shared.imManager.markGroupMessage(asRead: groupId, msgIDList: []) { _ in
                print("标记群聊所有消息已读")
            }
        }
    }

    func loadMoreMessages(completion: (() -> Void)?) {
        let earlestMsg = messagesRelay.value.first
        if let userId = userId {
            getHistoryMessageList(userId: userId, groupId: nil, startCliendMsgId: earlestMsg?.clientMsgID, completion: completion)
            return
        }

        if let groupId = groupId {
            getHistoryMessageList(userId: nil, groupId: groupId, startCliendMsgId: earlestMsg?.clientMsgID, completion: completion)
        }
    }

    func sendText(text: String, quoteMessage: MessageInfo?) {
        if !canContinueAskRobot() {
            return
        }

        IMController.shared.sendTextMessage(text: text, quoteMessage: quoteMessage, to: conversation, sending: { [weak self] (model: MessageInfo) in
            self?.addMessage(model)
        }) { [weak self] (model: MessageInfo) in
            self?.updateMessage(model)
        }
    }

    func sendImage(image: UIImage) {
        IMController.shared.sendImageMessage(image: image, to: conversation, sending: { [weak self] (model: MessageInfo) in
            self?.addMessage(model)
        }) { [weak self] (model: MessageInfo) in
            self?.updateMessage(model)
        }
    }

    func sendVideo(path: URL, thumbnailPath: String, duration: Int) {
        IMController.shared.sendVideoMessage(videoPath: path, duration: duration, snapshotPath: thumbnailPath, to: conversation, sending: { [weak self] (model: MessageInfo) in
            self?.addMessage(model)
        }) { [weak self] (model: MessageInfo) in
            self?.updateMessage(model)
        }
    }

    func sendAudio(path: String, duration: Int) {
        IMController.shared.sendAudioMessage(audioPath: path, duration: duration, to: conversation, sending: { [weak self] (model: MessageInfo) in
            self?.addMessage(model)
        }) { [weak self] (model: MessageInfo) in
            self?.updateMessage(model)
        }
    }

    func sendCard(user: UserInfo) {
        let card = BusinessCard(faceURL: user.faceURL, nickname: user.nickname, userID: user.userID)
        IMController.shared.sendCardMessage(card: card, to: conversation) { [weak self] (model: MessageInfo) in
            self?.addMessage(model)
        } onComplete: { [weak self] (model: MessageInfo) in
            self?.updateMessage(model)
        }
    }

    func resend(message: MessageInfo) {
        message.status = .sending
        updateMessage(message)
        IMController.shared.send(message: message, to: conversation) { [weak self] (model: MessageInfo) in
            self?.updateMessage(model)
        }
    }

    func revoke(message: MessageInfo) {
        IMController.shared.revokeMessage(message, onSuccess: { [weak self] _ in
            message.contentType = .revokeReciept
            message.senderNickname = "你"
            self?.updateMessage(message)
        })
    }

    func delete(message: MessageInfo) {
        IMController.shared.deleteMessage(message) { [weak self] _ in
            self?.removeMessage(message)
        }
    }

    func markAudio(messageId: String, isPlaying: Bool) {
        var origin = messagesRelay.value
        var changed = false
        for (index, item) in messagesRelay.value.enumerated() {
            if item.clientMsgID == messageId {
                var changedItem = item
                if changedItem.isPlaying != isPlaying {
                    changedItem.isPlaying = isPlaying
                    origin[index] = changedItem
                    changed = true
                }
            } else {
                item.isPlaying = false
            }
        }
        if changed {
            messagesRelay.accept(origin)
        }
    }

    private func addMessage(_ message: MessageInfo) {
        var origin = messagesRelay.value
        origin.append(message)
        messagesRelay.accept(origin)
        scrollsToBottom.onNext(())
    }

    private func updateMessage(_ message: MessageInfo) {
        var origin = messagesRelay.value
        var changed = false
        for (index, item) in messagesRelay.value.enumerated() {
            if item.clientMsgID == message.clientMsgID {
                origin[index] = message
                changed = true
            }
        }
        if changed {
            messagesRelay.accept(origin)
        }
    }

    private func markMessagesReaded(msgIds: [String]) {
        if msgIds.isEmpty { return }
        var origin = messagesRelay.value
        var changed = false
        for msgId in msgIds {
            for (index, item) in messagesRelay.value.enumerated() {
                if item.clientMsgID == msgId {
                    item.isRead = true
                    origin[index] = item
                    changed = true
                }
            }
        }
        if changed {
            messagesRelay.accept(origin)
        }
    }

    private func removeMessage(_ message: MessageInfo) {
        guard let messageId = message.clientMsgID else { return }
        removeMessage(messageId: messageId)
    }

    private func removeMessage(messageId: String) {
        var origin = messagesRelay.value
        var changed = false
        for (index, item) in messagesRelay.value.enumerated() {
            if item.clientMsgID == messageId {
                origin.remove(at: index)
                changed = true
            }
        }
        if changed {
            messagesRelay.accept(origin)
        }
    }

    private func getHistoryMessageList(userId: String?, groupId: String?, startCliendMsgId: String?, completion: (() -> Void)?) {
        IMController.shared.getHistoryMessageList(userId: userId, groupId: groupId, startCliendMsgId: startCliendMsgId, count: 20) { [weak self] (messages: [MessageInfo]) in
            guard let sself = self else { return }
            var origin = sself.messagesRelay.value
            origin.append(contentsOf: messages)
            let ret = origin.sorted(by: { $0.sendTime < $1.sendTime })
            self?.messagesRelay.accept(ret)
            completion?()
        }
    }

    private func sortMessages(messages: [MessageInfo]) -> [MessageInfo] {
        let ret = messages.sorted { lh, rh in
            lh.sendTime > rh.sendTime
        }
        return ret
    }
    
    func canContinueAskRobot() -> Bool {
        if !isRobot {
            return true
        }
        
        let last = messagesRelay.value.last;
        let enabled = last == nil ||
        last!.contentType.rawValue > 1000 ||
        robots.contains(last!.sendID!) ||
        (Date().timeIntervalSince1970 * 1000 - last!.sendTime) > 1 * 60 * 1000
        
        return enabled;
    }
}
