
import ChatLayout
import Foundation
import OUICore

final class DefaultChatController: ChatController {
    
    weak var delegate: ChatControllerDelegate?
    
    private let dataProvider: DataProvider
    
    private var typingState: TypingState = .idle
    
    private let dispatchQueue = DispatchQueue(label: "DefaultChatController", qos: .userInteractive)
    
    private var lastReadIDs: [String] = []
    
    private var hasReadUserID: String? // 群组中已读人
    
    private var unReadCount: Int = 0 // 左上角的未读数
    
    private var lastReceivedString: String?
    
    private let receiverId: String // 接收人的uid
    
    private let senderID: String // 发送人的uid
    
    private let conversationType: ConversationType // 会话类型
    
    private let conversation: ConversationInfo
    
    private var groupInfo: GroupInfo? // 将其缓存
    
    private var groupMembers: [GroupMemberInfo]?
    
    private var otherInfo: FullUserInfo?
    
    private var messages: [MessageInfo] = []
    
    private var selecteMessages: [MessageInfo] = [] // 选中的消息id， 可转发、删除、引用消息

    private var selectedUsers: [String] = [] // 选中的成员, 可做为@成员
        
    init(dataProvider: DataProvider, senderID: String, receiverId: String, conversationType: ConversationType, conversation: ConversationInfo) {
        self.dataProvider = dataProvider
        self.receiverId = receiverId
        self.senderID = senderID
        self.conversationType = conversationType
        self.conversation = conversation
        
        switch conversationType {
        case .undefine:
            break
        case .c2c:
            getOtherInfo { _ in }
        case .superGroup, .group:
            getGroupInfo { _ in }
            getGroupMembers { _ in }
        case .notification:
            break
        }
        markMessageAsReaded()
        getUnReadTotalCount()
    }
    
    deinit {
        print("controller - deinit")
        markMessageAsReaded()
    }
    
    // MARK: 协议相关
    
    func loadInitialMessages(completion: @escaping ([Section]) -> Void) {
        getBasicInfo { [weak self] in
            self?.dataProvider.loadInitialMessages { [weak self] messages in
                self?.appendConvertingToMessages(messages)
                self?.markAllMessagesAsReceived { [weak self] in
                    self?.markAllMessagesAsRead { [weak self] in
                        self?.propagateLatestMessages { sections in
                            completion(sections)
                        }
                    }
                }
            }
        }
    }
    
    func loadPreviousMessages(completion: @escaping ([Section]) -> Void) {
        dataProvider.loadPreviousMessages(completion: { [weak self] messages in
            self?.appendConvertingToMessages(messages)
            self?.markAllMessagesAsReceived { [weak self] in
                self?.markAllMessagesAsRead { [weak self] in
                    self?.propagateLatestMessages { [weak self]  sections in
                        completion(sections)
                    }
                }
            }
        })
    }
    
    func defaultSelecteMessage(with id: String?) {
        if let id {
            selecteMessages.removeAll()
            selecteMessage(with: id)
        } else {
            selecteMessages.removeAll()
        }
    }
    
    func defaultSelecteUsers(with usersID: [String]) {
        selectedUsers.append(contentsOf: usersID)
    }
    
    // 重置原始消息的选中状态
    private func resetSelectedStatus() {
        messages.forEach { $0.isSelected = false }
    }
    
    func deleteMessage(with id: String) {
    }
    
    func getConversation() -> ConversationInfo {
        return conversation
    }
    
    func getGroupMembers(completion: @escaping ([GroupMemberInfo]) -> Void) {
        if groupMembers == nil {
            IMController.shared.getGroupMemberList(groupId: receiverId,
                                                   filter: .all,
                                                   offset: 0,
                                                   count: 10000) { [weak self] ms in
                completion(ms)
                self?.groupMembers = ms
            }
        } else {
            completion(groupMembers!)
        }
    }
    
    func getMentionUsers(completion: @escaping ([GroupMemberInfo]) -> Void) {
        getGroupMembers { ms in
            var us = ms.filter({ $0.userID != IMController.shared.uid })
            let metionAll = GroupMemberInfo()
            metionAll.userID = "-1"
            metionAll.nickname = "所有人"
            us.insert(metionAll, at: 0)
            
            completion(us)
        }
    }
    
    func getMessageInfo(ids: [String]) -> [MessageInfo] {
        return messages.filter({ ids.contains($0.clientMsgID) })
    }
    
    private func getBasicInfo(completion: @escaping () -> Void) {
        if conversationType == .c2c {
            getOtherInfo { _ in
                completion()
            }
        } else {
            getGroupInfo { _ in
                completion()
            }
        }
    }
    
    func getOtherInfo(completion: @escaping (FullUserInfo) -> Void) {
        if otherInfo == nil {
            IMController.shared.getUserInfo(uids: [receiverId]) { [weak self] info in
                guard let r = info.first else { return }
                completion(r)
                self?.otherInfo = r
            }
        } else {
            completion(otherInfo!)
        }
    }

    func getGroupInfo(completion: @escaping (GroupInfo) -> Void) {
        guard groupInfo == nil else {
            completion(groupInfo!)
            return
        }
        dataProvider.getGroupInfo { [weak self] group in
            completion(group)
            self?.groupInfo = group
        }
    }
    
    func getSelectedMessages() -> [MessageInfo] {
        return selecteMessages
    }
    
    func getSelfInfo() -> UserInfo? {
        return IMController.shared.currentUserRelay.value
    }
    
    func addFriend(onSuccess: @escaping CallBack.StringOptionalReturnVoid, onFailure: @escaping CallBack.ErrorOptionalReturnVoid) {
        let reqMsg = "\(IMController.shared.currentUserRelay.value!.nickname)请求添加你为好友"
        IMController.shared.addFriend(uid: receiverId, reqMsg: reqMsg, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    // 主动撤回
    func revokeMessage(with id: String) {
        if var msg = messages.first(where: { $0.clientMsgID == id}) {
            IMController.shared.revokeMessage(conversationID: conversation.conversationID, clientMsgID: msg.clientMsgID) { [weak self] r in
                msg.contentType = .revoke
                
                let info = MessageRevoked()
                info.clientMsgID = msg.clientMsgID
                info.revokerNickname = IMController.shared.currentUserRelay.value?.nickname
                info.revokerID = IMController.shared.currentUserRelay.value?.userID
                info.sourceMessageSendID = msg.sendID
                info.sourceMessageSendTime = msg.sendTime
                info.sourceMessageSenderNickname = msg.senderNickname
                info.revokeTime = NSDate().timeIntervalSince1970
                info.sessionType = msg.sessionType
                msg.content = JsonTool.toJson(fromObject: info)
                
                self?.repopulateMessages(requiresIsolatedProcess: true)
            }
        }
    }
    
    func markMessageAsReaded(messageID: String? = nil) {
        IMController.shared.markMessageAsReaded(byConID: conversation.conversationID, msgIDList: messageID == nil ? [] : [messageID!]) { [weak self] r in
            if messageID != nil {
                self?.messages.first(where: { $0.clientMsgID == messageID })?.hasReadTime = Date().timeIntervalSince1970 * 1000
                self?.repopulateMessages(requiresIsolatedProcess: true)
            }
        }
    }
    
    // MARK: 发送消息
    
    func typing(doing: Bool) {
        IMController.shared.typingStatusUpdate(recvID: receiverId, msgTips: doing ? "yes" : "no")
    }
    
    func sendMessage(_ data: Message.Data, completion: @escaping ([Section]) -> Void) {
        switch data {
        case .text(let source):
            // 如果有选中的消息，说明是引用消息
            let quoteMsg = selecteMessages.first
            sendText(text: source.text, quoteMessage: quoteMsg, completion: completion)
            
        case .url(let url, isLocallyStored: _):
            break
            
        case .image(let source, isLocallyStored: _):
            sendImage(source: source, completion: completion)
            
        case .video(let source, isLocallyStored: _):
            // 发送的时候，图片选择器选择以后，传入的是路径
            sendVideo(source: source, completion: completion)
            
        case .attributeText(_), .custom(_):
            break
        }
    }
    
    private func sendText(text: String, to: String? = nil, conversationType: ConversationType? = nil, quoteMessage: MessageInfo? = nil, completion: (([Section]) -> Void)?) {
        IMController.shared.sendTextMessage(text: text,
                                            quoteMessage: quoteMessage,
                                            to: to ?? receiverId,
                                            conversationType: conversationType ?? self.conversationType) { [weak self] msg in
//            self?.appendMessage(msg, completion: completion) // 刷新太快，界面不好看
        } onComplete: { [weak self] msg in
            guard let completion else { return }
            self?.appendMessage(msg, completion: completion)
            self?.selecteMessages.removeAll() // 移除选中的引用消息
            self?.selectedUsers.removeAll()
        }
    }
    
    private func sendImage(source: MediaMessageSource, completion: @escaping ([Section]) -> Void) {
        
        let path = source.source.url!.path
        let image = UIImage(contentsOfFile: path)
        
        if let image {
            cacheImage(image: image, path: path)
        }
        
        IMController.shared.sendImageMessage(path: source.source.relativePath!,
                                             to: receiverId,
                                             conversationType: conversationType) { [weak self] msg in
            self?.appendMessage(msg, completion: completion)
        } onComplete: { [weak self] msg in
            if let image {
                self?.cacheImage(image: image, path: (msg.pictureElem?.sourcePicture?.url)!)
            }
            self?.replaceMessage(msg)
        }
    }
    
    private func sendVideo(source: MediaMessageSource, completion: @escaping ([Section]) -> Void) {
        
        let path = source.thumb!.url.path
        let image = UIImage(contentsOfFile: path)
        
        if let image {
            cacheImage(image: image, path: path)
        }
                
        IMController.shared.sendVideoMessage(path: source.source.relativePath!,
                                             duration: source.duration!,
                                             snapshotPath: (source.thumb?.relativePath)!,
                                             to: receiverId,
                                             conversationType: conversationType) { [weak self] msg in
            self?.appendMessage(msg, completion: completion)
        } onComplete: { [weak self] msg in
            if let image {
                self?.cacheImage(image: image, path: (msg.videoElem?.snapshotUrl)!)
            }
            self?.replaceMessage(msg)
//            self?.appendMessage(msg, completion: completion)
        }
    }
    
    private func cacheImage(image: UIImage, path: String) {
        do {
            try imageCache.store(entity: image, for: CacheableImageKey(url: URL(string: path)!))
        } catch (let e) {
            print("cache image failure:\(e)")
        }
    }
    
    // MARK: 更新数据源
    private func appendMessage(_ message: MessageInfo, completion: @escaping ([Section]) -> Void) {
        // 刷新数据源
        var exist = false
        
        for (i, item) in messages.enumerated() {
            if item.clientMsgID == message.clientMsgID {
                messages[i] = message
                exist = true
                break
            }
        }
        
        if !exist {
            messages.append(message)
        }
        
        // 刷新界面
        propagateLatestMessages(completion: completion)
    }
    
    private func replaceMessage(_ message: MessageInfo) {
        for (i, item) in messages.enumerated() {
            if item.clientMsgID == message.clientMsgID {
                messages[i] = message
                break
            }
        }
    }
    
    private func appendConvertingToMessages(_ rawMessages: [MessageInfo]) {
        var messages = messages
        messages.append(contentsOf: rawMessages)
        self.messages = messages.sorted(by: { $0.sendTime < $1.sendTime })
    }
    
    private func propagateLatestMessages(completion: @escaping ([Section]) -> Void) {

        var lastMessageStorage: Message?
        
        dispatchQueue.async { [weak self] in
            guard let self else {
                return
            }
            
            let messagesSplitByDay = self.messages
                .map { self.convertMessage($0) }
                .reduce(into: [[Message]]()) { result, message in
                    guard var section = result.last,
                          let prevMessage = section.last else {
                        let section = [message]
                        result.append(section)
                        return
                    }
                    if Calendar.current.isDate(prevMessage.date, equalTo: message.date, toGranularity: .hour) {
                        section.append(message)
                        result[result.count - 1] = section
                    } else {
                        let section = [message]
                        result.append(section)
                    }
                }
            
            let cells = messagesSplitByDay.enumerated().map { index, messages -> [Cell] in // 按天划分
                var cells: [Cell] = Array(messages.enumerated().map { index, message -> [Cell] in // 按发送者划分
                    
                    if message.contentType == .system, case .attributeText(let value) = message.data {
                        
                        let systemCell = Cell.systemMessage(SystemGroup(id: message.id, value: value))
                        return [systemCell]
                    }
                    
                    let bubble: Cell.BubbleType
                    if index < messages.count - 1 {
                        let nextMessage = messages[index + 1]
                        bubble = nextMessage.owner == message.owner ? .normal : .tailed
                    } else {
                        bubble = .tailed
                    }
                    guard message.type != .outgoing else {
                        lastMessageStorage = message
                        return [.message(message, bubbleType: bubble)]
                    }
                    
                    let titleCell = Cell.messageGroup(MessageGroup(id: message.id, title: "\(message.owner.name) \(Date.timeString(date: message.date))", type: message.type))
                    
                    if let lastMessage = lastMessageStorage {
                        if lastMessage.owner != message.owner {
                            lastMessageStorage = message
                            return [titleCell, .message(message, bubbleType: bubble)]
                        } else {
                            lastMessageStorage = message
                            return [.message(message, bubbleType: bubble)]
                        }
                    } else {
                        lastMessageStorage = message
                        return [titleCell, .message(message, bubbleType: bubble)]
                    }
                }.joined())
                
                if let firstMessage = messages.first {
                    let dateCell = Cell.date(DateGroup(id: firstMessage.id, date: firstMessage.date))
                    cells.insert(dateCell, at: 0)
                }
                
                if self.typingState == .typing,
                   index == messagesSplitByDay.count - 1 {
                    cells.append(.typingIndicator)
                }
                
                return cells // Section(id: sectionTitle.hashValue, title: sectionTitle, cells: cells)
            }.joined()
            
            DispatchQueue.main.async { [weak self] in
                guard self != nil else {
                    return
                }
                completion([Section(id: 0, title: "", cells: Array(cells))])
            }
        }
        
    }
    
    private func convertMessage(_ msg: MessageInfo) -> Message {
        
        return Message(id: msg.clientMsgID,
                       date: Date(timeIntervalSince1970: msg.sendTime / 1000),
                       contentType: msg.contentType.rawValue > MessageContentType.face.rawValue ? MessageRawType.system : MessageRawType.normal,
                       data: convert(msg),
                       owner: User(id: msg.sendID, name: msg.senderNickname ?? "", faceURL: msg.senderFaceUrl),
                       type: msg.isOutgoing ? .outgoing : .incoming,
                       status: msg.isOutgoing ? .sent : .received,
                       isSelected: msg.isSelected,
                       isAnchor: msg.isAnchor)
    }
    
    private func convert(_ msg: MessageInfo) -> Message.Data {
        var isLocalPath = msg.serverMsgID == nil // 本地发送，先把消息渲染到界面上；发送成功以后，再替换原消息
        
        switch msg.contentType {
            
        case .text:
            let textElem = msg.textElem!
            
            let source = TextMessageSource(text: textElem.content)
            
            return .text(source)
            
        case .image:
            let pictureElem = msg.pictureElem!
            let url = isLocalPath ? URL(string: pictureElem.sourcePath!)! : URL(string: pictureElem.snapshotPicture!.url!)!
            let isPresentLocally = imageCache.isEntityCached(for: CacheableImageKey(url: url))
            let source = MediaMessageSource(source: MediaMessageSource.Info(url: url))
            
            return .image(source, isLocallyStored: isPresentLocally)
            
        case .video:
            let videoElem = msg.videoElem!
            let url = isLocalPath ? URL(string: videoElem.videoPath!) : URL(string: videoElem.videoUrl!)!
            let thumbURL = isLocalPath ? URL(string: videoElem.snapshotPath!)! : URL(string: videoElem.snapshotUrl!)!
            let isPresentLocally = imageCache.isEntityCached(for: CacheableImageKey(url: thumbURL)) // 这个值，可以用来判断差分是否有效
            let duration = msg.videoElem!.duration
            
            let source = MediaMessageSource(source: MediaMessageSource.Info(url: url),
                                            thumb: MediaMessageSource.Info(url: thumbURL),
                                            duration: duration)
            
            return .video(source, isLocallyStored: isPresentLocally)
            
        case .groupAnnouncement:
            let noti = msg.notificationElem!

            let source = TextMessageSource(text: noti.group?.notification ?? "", type: .notice)
            
            return .text(source)
            
        case .custom:
            let value = MessageHelper.getCustomMessageValueOf(message: msg)
            let source = CustomMessageSource(data: msg.customElem?.data, attributedString: value)
            
            return .custom(source)
        default:
            let value = MessageHelper.getSystemNotificationOf(message: msg, isSingleChat: msg.sessionType == .c2c)
            
            return .attributeText(value!)
        }
    }
        
    private func repopulateMessages(requiresIsolatedProcess: Bool = false) {
        propagateLatestMessages { [weak self] sections in
            self?.delegate?.update(with: sections, requiresIsolatedProcess: requiresIsolatedProcess)
        }
    }
    
    // MARK: 操作消息
    
    private func deleteMessages(messages: [MessageInfo], completion: @escaping ([MessageInfo]) -> Void) {
        var result: [MessageInfo] = []
        var count = 0
        
        for (i, msg) in messages.enumerated() {
            IMController.shared.deleteMessage(conversation: conversation.conversationID,
                                              clientMsgID: msg.clientMsgID) { r in
                result.append(msg)
                count += 1
                
                if count == messages.count {
                    completion(result)
                }
            } onFailure: { errCode, errMsg in
                count += 1
                
                if count == messages.count {
                    completion(result)
                }
            }
        }
    }
    
    // MARK: 其它操作
    private func getUnReadTotalCount() {
        IMController.shared.getTotalUnreadMsgCount { [weak self] count in
            self?.unReadCount = count
            self?.delegate?.updateUnreadCount(count: count)
        }
    }
}

extension DefaultChatController: DataProviderDelegate {

    func isInGroup(with isIn: Bool) {
        delegate?.isInGroup(with: isIn)
    }
    
    func received(message: MessageInfo) {
        // 收到当前界面的消息
        if conversation.userID == message.sendID ||
            conversation.groupID == message.groupID {
            appendConvertingToMessages([message])
            markAllMessagesAsReceived { [weak self] in
                self?.markAllMessagesAsRead { [weak self] in
                    self?.repopulateMessages()
                }
            }
        } else {
         // 左上角未读数加1
            unReadCount += 1
            delegate?.updateUnreadCount(count: unReadCount)
        }
    }
    
    func receivedRevokedInfo(info: MessageRevoked) {
        if var msg = messages.first(where: { $0.clientMsgID == info.clientMsgID }) {
            msg.contentType = .revoke
            msg.content = JsonTool.toJson(fromObject: info)
            repopulateMessages()
        }
    }
    
    func typingStateChanged(to state: TypingState) {
        typingState = state
        repopulateMessages()
    }
    
    func lastReadIdsChanged(to ids: [String], readUserID: String?) {
        lastReadIDs = ids
        hasReadUserID = readUserID
        markAllMessagesAsRead { [weak self] in
            self?.repopulateMessages()
        }
    }
    
    func lastReceivedIdChanged(to id: String) {
        lastReceivedString = id
        markAllMessagesAsReceived { [weak self] in
            self?.repopulateMessages()
        }
    }
    
    func markAllMessagesAsReceived(completion: @escaping () -> Void) {
        completion()
    }
    
    func markAllMessagesAsRead(completion: @escaping () -> Void) {
        completion()
    }
    
}

extension DefaultChatController: ReloadDelegate {
    
    func reloadMessage(with id: String) {
        repopulateMessages()
    }
    
    func didTapAvatar(with id: String) {
        delegate?.didTapAvatar(with: id)
    }
    
    func didTapContent(with id: String, data: Message.Data) {
        
        delegate?.didTapContent(with: id, data: data)
    }
    
    func removeMessage(messageID: String) {
        defaultSelecteMessage(with: messageID)
        deleteMessage(with: messageID)
    }
}

extension DefaultChatController: EditingAccessoryControllerDelegate {

    func selecteMessage(with id: String) {
        // 将选中的消息计入，用来删除，转发等
        if let index = selecteMessages.firstIndex(where: { $0.clientMsgID == id}) {
            selecteMessages.remove(at: index)
            messages.first(where: { $0.clientMsgID == id})?.isSelected = false
        } else {
            if let item = messages.first(where: { $0.clientMsgID == id}) {
                item.isSelected = true // 多选的时候用来记录选中项，主要是cell重用问题。
                selecteMessages.append(item)
            }
        }
        
        repopulateMessages(requiresIsolatedProcess: true)
    }
}
