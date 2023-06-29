
import Foundation
import UIKit
import OUICore
import RxSwift

protocol DataProvider {

    func loadInitialMessages(completion: @escaping ([MessageInfo]) -> Void)

    func loadPreviousMessages(completion: @escaping ([MessageInfo]) -> Void)
    
    func getGroupInfo(groupInfoHandler: @escaping (GroupInfo) -> Void)
}

final class DefaultDataProvider: DataProvider {
    
    private let _disposeBag = DisposeBag()
    
    weak var delegate: DataProviderDelegate?
    
    private var startClientMsgID: String?
    
    private var lastMinSeq: Int = 0
    
    private var reverseStartClientMsgID: String?
    
    private var reverseLastMinSeq: Int = 0
    
    private var conversation: ConversationInfo!

    private var startingTimestamp = Date().timeIntervalSince1970

    private var typingState: TypingState = .idle

    private let users: [String] = []

    private let receiverId: String!

    private var lastMessageIndex: Int = 0

    private var lastReadString: String?

    private var lastReceivedString: String?

    private let dispatchQueue = DispatchQueue.global(qos: .userInteractive)

    private let enableTyping = true

    private let enableNewMessages = true

    private let enableRichContent = true
    
    private var isAdminOrOwner = false
    
    private var anchorID: String?

    private var allUsersIds: [String] {
        Array([users, [receiverId]].joined())
    }

    init(conversation: ConversationInfo, anchorID: String? = nil) {
        self.conversation = conversation
        self.receiverId = conversation.conversationType == .c2c ? conversation.userID! : conversation.groupID!
        self.anchorID = anchorID
        
        addObservers()
    }
    
    deinit {
        print("provider - deinit")
    }

    func loadInitialMessages(completion: @escaping ([MessageInfo]) -> Void) {
        if anchorID != nil {
            startClientMsgID = anchorID
            reverseStartClientMsgID = anchorID
            
            var r: [MessageInfo] = []
            let group = DispatchGroup()
            
            group.enter()
            getHistoryMessageList { ms in
                r.append(contentsOf: ms)
                group.leave()
            }
            group.enter()
            getHistoryMessageList(reverse: true) { ms in
                r.append(contentsOf: ms)
                group.leave()
            }
            
            group.notify(queue: .main) { [self]
                r = r.reduce([]) { partialResult, element in
                    return partialResult.contains(where: { $0.clientMsgID == element.clientMsgID }) ? partialResult : partialResult + [element]
                }
                r.sort(by: { $0.sendTime < $1.sendTime })
                r.first(where: { $0.clientMsgID == self.anchorID })?.isAnchor = true
       
                completion(r)
            }
        } else {
            
            getHistoryMessageList(completion: completion)
        }
    }

    func loadPreviousMessages(completion: @escaping ([MessageInfo]) -> Void) {
        getHistoryMessageList(completion: completion)
    }
    
    func getGroupInfo(groupInfoHandler: @escaping (GroupInfo) -> Void) {
        IMController.shared.getGroupInfo(groupIds: [receiverId]) { [weak self] (infos: [GroupInfo]) in
            guard let self, let groupInfo = infos.first else {
                return
            }
            groupInfoHandler(groupInfo)
        }
    }
    
    private func getHistoryMessageList(reverse: Bool = false, completion: @escaping ([MessageInfo]) -> Void) {

        if reverse {
            IMController.shared.getHistoryMessageListReverse(conversationID: conversation.conversationID,
                                                             startCliendMsgId: reverseStartClientMsgID,
                                                             lastMinSeq: reverseLastMinSeq) { [weak self] seq, ms in
                guard let self, !ms.isEmpty else {
                    completion([])
                    return
                }
                
                self.reverseLastMinSeq = seq
                self.reverseStartClientMsgID = ms.last?.clientMsgID
                completion(ms)
            }
        } else {
            IMController.shared.getHistoryMessageList(conversationID: conversation.conversationID,
                                                      conversationType: conversation.conversationType,
                                                      startCliendMsgId: startClientMsgID,
                                                      lastMinSeq: lastMinSeq) { [weak self] seq, ms in
                guard let self, !ms.isEmpty else {
                    completion([])
                    return
                }
                
                self.lastMinSeq = seq
                self.startClientMsgID = ms.first?.clientMsgID
                completion(ms)
            }
        }
    }
    
    private func getSelfInfoInGroup() {
        IMController.shared.getGroupMembersInfo(groupId: receiverId, uids: [IMController.shared.uid]) { [weak self] ms in
            if let self, let m = ms.first {
                self.isAdminOrOwner = m.isOwnerOrAdmin
                
            }
        }
    }

    // 接收消息
    private func addObservers() {
        
        IMController.shared.newMsgReceivedSubject.subscribe(onNext: { [weak self] (message: MessageInfo) in
            guard let self else { return }
            // 输入状态
            if case .typing = message.contentType {
                if (self.conversation.userID == message.sendID ||
                    self.conversation.groupID == message.groupID) {
                    self.typingState = message.isTyping() ? .typing : .idle
                    self.delegate?.typingStateChanged(to: self.typingState)
                }
            } else {
                self.receivedNewMessages(message: message)
            }
        }).disposed(by: _disposeBag)

            IMController.shared.c2cReadReceiptReceived.subscribe(onNext: { [weak self] (receiptInfos: [ReceiptInfo]) in
                let msgIDs = receiptInfos.flatMap { $0.msgIDList ?? [] }
                self?.delegate?.lastReadIdsChanged(to: msgIDs, readUserID: nil)
            }).disposed(by: _disposeBag)

            IMController.shared.groupReadReceiptReceived.subscribe(onNext: { [weak self] (receiptInfos: [ReceiptInfo]) in
                
                for receiptInfo in receiptInfos {
                    if let msgIDs = receiptInfo.msgIDList, !msgIDs.isEmpty {
                        self?.delegate?.lastReadIdsChanged(to: msgIDs, readUserID: receiptInfo.userID)
                    }
                }
                
            }).disposed(by: _disposeBag)
            
            IMController.shared.groupMemberInfoChange.subscribe(onNext: { [weak self] info in
                guard let info, let self, info.isSelf else { return }

            }).disposed(by: _disposeBag)
            
            IMController.shared.joinedGroupAdded.subscribe(onNext: { [weak self] info in
                // groupInfo.groupID 即为邀请你的群
                guard let self, self.receiverId == info?.groupID else { return }
                
                self.delegate?.isInGroup(with: true)

            }).disposed(by: _disposeBag)
            
            IMController.shared.joinedGroupDeleted.subscribe(onNext: { [weak self] info in
                // groupInfo.groupID 即为踢出你的群
                guard let self, self.receiverId == info?.groupID else { return }
                
                self.delegate?.isInGroup(with: false)
                
            }).disposed(by: _disposeBag)

        IMController.shared.msgRevokeReceived.subscribe(onNext: { [weak self] revokedInfo in
        }).disposed(by: _disposeBag)
        
        IMController.shared.friendInfoChangedSubject.subscribe { [weak self] (friendInfo: FriendInfo?) in
            guard let sself = self else { return }
//            if friendInfo?.userID == sself.userId {
//                var nickName: String? = self?.chatTitle.value
//                if let remark = friendInfo?.remark {
//                    nickName = remark
//                }
//                self?.chatTitle.accept(nickName)
//            }
        }.disposed(by: _disposeBag)
        
        IMController.shared.onBlackAddedSubject.subscribe { [weak self] (blcakInfo: BlackInfo?) in

        }.disposed(by: _disposeBag)
        
        IMController.shared.onBlackDeletedSubject.subscribe { [weak self] (blcakInfo: BlackInfo?) in

        }.disposed(by: _disposeBag)
        
        IMController.shared.groupInfoChangedSubject.subscribe { [weak self] (groupInfo: GroupInfo?) in
    
        }.disposed(by: _disposeBag)
    }
    
    private func receivedNewMessages(message: MessageInfo) {
        guard enableNewMessages else {
            return
        }

        delegate?.received(message: message)
        delegate?.lastReceivedIdChanged(to: message.clientMsgID)
    }
}
