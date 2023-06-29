import Foundation

public struct CallBack {
    public typealias StringOptionalReturnVoid = (String?) -> Void
    public typealias VoidReturnVoid = () -> Void
    public typealias MessageReturnVoid = (MessageInfo) -> Void
    public typealias UserInfoOptionalReturnVoid = (UserInfo?) -> Void
    public typealias UsersInfoOptionalReturnVoid = ([UserInfo]?) -> Void
    public typealias FullUserInfosReturnVoid = ([FullUserInfo]) -> Void
    public typealias GroupInfoOptionalReturnVoid = (GroupInfo?) -> Void
    public typealias GroupInfosReturnVoid = ([GroupInfo]) -> Void
    public typealias GroupSignalingInfoReturnVoid = (String, [GroupMemberInfo]) -> Void
    public typealias ConversationInfoOptionalReturnVoid = (ConversationInfo?) -> Void
    public typealias GroupMembersReturnVoid = ([GroupMemberInfo]) -> Void
    public typealias ProgressReturnVoid = (CGFloat) -> Void
    public typealias SearchResultInfoOptionalReturnVoid = (SearchResultInfo?) -> Void
    public typealias BlackListOptionalReturnVoid = ([BlackInfo]) -> Void
    public typealias SearchUsersInfoOptionalReturnVoid = ([SearchUserInfo]) -> Void
    public typealias SignalingInfoOptionalReturnVoid = (InvitationResultInfo) -> Void
    public typealias ErrorOptionalReturnVoid = (_ errCode: Int, _ errMsg: String?) -> Void
    public typealias MomentsNewMessageReturnVoid = ([MomentsNewMessageInfo]) -> Void
    public typealias MeetingReturnVoid = ([MeetingInfo]) -> Void
    public typealias DepartmentInfoReturnVoid = ([DepartmentInfo]) -> Void
    public typealias DepartmentMemberInfoReturnVoid = ([DepartmentMemberInfo]) -> Void
    public typealias UserInDepartmentInfoReturnVoid = ([UserInDepartmentInfo]) -> Void
    public typealias DepartmentMemberAndSubInfoReturnVoid = (DepartmentMemberAndSubInfo?) -> Void
}
