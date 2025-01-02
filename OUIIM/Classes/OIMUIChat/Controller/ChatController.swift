
import Foundation
import OUICore

#if ENABLE_LIVE_ROOM
import OUILive
#endif

protocol ChatController {

    func loadInitialMessages(completion: @escaping ([Section]) -> Void)
    func loadPreviousMessages(completion: @escaping ([Section]) -> Void)
    func loadMoreMessages(completion: @escaping ([Section]) -> Void)
    func sendMessage(_ data: Message.Data, completion: @escaping ([Section]) -> Void)
    func canRevokeMessage(msg: Message) -> Bool
    func revokeMessage(with id: String, completion: @escaping (Bool) -> Void)
    func typing(doing: Bool)
    
    func messageIsExsit(with id: String) -> Bool
    func defaultSelecteMessage(with id: String?, onlySelect: Bool)
    func defaultSelecteUsers(with usersID: [String])
    
    func deleteMessage(completion: (() -> Void)?)
    func forwardMessage(merge: Bool, usersID: [String]?, groupsID: [String]?, title: String, attachMessage: String?)
    func updateMessageLocalEx(messageID: String, ex: MessageEx)
    func uploadFile(image: UIImage, progress: @escaping (CGFloat) -> Void, completion: @escaping (String?) -> Void)
    
    func getConversation() -> ConversationInfo
    func getGroupMembers(userIDs: [String]?, memory: Bool, completion: @escaping ([GroupMemberInfo]) -> Void)
    func getGroupInfo(force: Bool, completion: @escaping (GroupInfo) -> Void)
    func getOtherInfo(completion: @escaping (FriendInfo) -> Void)
    func getSelfInfo() -> UserInfo?
    func getUsersInfo(userIDs: [String], completion: @escaping ([UserInfo]) -> Void)
    func getMessageInfo(ids: [String]) -> [MessageInfo]
    func getSelectedMessages() -> [MessageInfo]
    func getIsAdminOrOwner() -> Bool
    func getTitle()
    
    func addFriend(onSuccess: @escaping CallBack.StringOptionalReturnVoid, onFailure: @escaping CallBack.ErrorOptionalReturnVoid)
}

extension ChatController {
    func loadMoreMessages(_: @escaping ([Section]) -> Void) {}
    func uploadFile(_: UIImage, _: @escaping (CGFloat) -> Void, _: @escaping (String?) -> Void) {}
    
    func messageIsExsit(with _: String) -> Bool { true }
    func defaultSelecteUsers(with _: [String]) {}
    func defaultSelecteMessage(with _: String?, _: Bool) {}
    func deleteMessage(completion: (() -> Void)?) {}
    func forwardMessage(_: Bool, _: [String]?, _: [String]?, _: String, _: String?) {}
    func markMessageAsReaded(_: String?, _: (() -> Void)?) {}
    func updateMessageLocalEx(_: String, _: MessageEx) {}

    func revokeMessage(with _: String, _: @escaping () -> Void) {}
    func getMessageInfo( _: [String]) -> [MessageInfo] { [] }
    func getSelectedMessages() -> [MessageInfo] { [] }
    func getSelfInfo() -> UserInfo? { nil }
    func getUsersInfo(userIDs: [String], completion: @escaping ([UserInfo]) -> Void) {}
    func getIsAdminOrOwner() {}
    func getTitle() {}
}
