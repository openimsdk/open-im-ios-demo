
import Foundation
import OUICore

protocol ChatController {

    func loadInitialMessages(completion: @escaping ([Section]) -> Void)
    func loadPreviousMessages(completion: @escaping ([Section]) -> Void)
    func sendMessage(_ data: Message.Data, completion: @escaping ([Section]) -> Void)

    func getConversation() -> ConversationInfo
    func getGroupMembers(completion: @escaping ([GroupMemberInfo]) -> Void)
    func getGroupInfo(completion: @escaping (GroupInfo) -> Void)
    func getOtherInfo(completion: @escaping (FullUserInfo) -> Void)
    func getSelfInfo() -> UserInfo?
    func getMessageInfo(ids: [String]) -> [MessageInfo]
    
    func addFriend(onSuccess: @escaping CallBack.StringOptionalReturnVoid, onFailure: @escaping CallBack.ErrorOptionalReturnVoid)
}

extension ChatController {
    func getMessageInfo( _: [String]) -> [MessageInfo] { [] }
    func getSelfInfo() -> UserInfo? { nil }
}
