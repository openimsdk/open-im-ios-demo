






import Foundation

public struct CallBack {
    public typealias StringOptionalReturnVoid = (String?) -> Void
    typealias VoidReturnVoid = () -> Void
    typealias MessageReturnVoid = (MessageInfo) -> Void
    public typealias UserInfoOptionalReturnVoid = (UserInfo?) -> Void
    typealias FullUserInfosReturnVoid = ([FullUserInfo]) -> Void
    typealias GroupInfoOptionalReturnVoid = (GroupInfo?) -> Void
    typealias GroupInfosReturnVoid = ([GroupInfo]) -> Void
    typealias ConversationInfoOptionalReturnVoid = (ConversationInfo?) -> Void
    typealias GroupMembersReturnVoid = ([GroupMemberInfo]) -> Void
    public typealias ProgressReturnVoid = (Int) -> Void
    typealias SearchResultInfoOptionalReturnVoid = (SearchResultInfo?) -> Void
}
