
import Foundation
import RxCocoa
import RxSwift

class GroupChatSettingViewModel {
    private(set) var conversation: ConversationInfo

    let membersRelay: BehaviorRelay<[UserInfo]> = .init(value: [])
    let membersCountRelay: BehaviorRelay<Int> = .init(value: 0)
    let noDisturbRelay: BehaviorRelay<Bool> = .init(value: false)
    let setTopContactRelay: BehaviorRelay<Bool> = .init(value: false)
    let isSelfRelay: BehaviorRelay<Bool> = .init(value: false)
    let groupInfoRelay: BehaviorRelay<GroupInfo?> = .init(value: nil)
    let myInfoInGroup: BehaviorRelay<GroupMemberInfo?> = .init(value: nil)
    private(set) var allMembers: [String] = []

    init(conversation: ConversationInfo) {
        self.conversation = conversation
    }

    func getConversationInfo() {
        guard let gid = conversation.groupID else { return }

        IMController.shared.getConversation(sessionType: conversation.conversationType, sourceId: gid) { [weak self] (chat: ConversationInfo?) in
            guard let sself = self else { return }
            if let chat = chat {
                self?.conversation = chat
                self?.noDisturbRelay.accept(sself.conversation.recvMsgOpt != .receive)
                self?.setTopContactRelay.accept(sself.conversation.isPinned)
            }
        }

        IMController.shared.getGroupMemberList(groupId: gid, offset: 0, count: 6) { [weak self] (members: [GroupMemberInfo]) in
            var users = members.compactMap { $0.toUserInfo() }
            let fakeUser = UserInfo()
            fakeUser.isButton = true
            users.append(fakeUser)
            self?.membersRelay.accept(users)
        }

        IMController.shared.getGroupInfo(groupIds: [gid]) { [weak self] (groupInfos: [GroupInfo]) in
            guard let sself = self else { return }
            guard let groupInfo = groupInfos.first else { return }
            self?.groupInfoRelay.accept(groupInfo)
            self?.membersCountRelay.accept(groupInfo.memberCount)
            self?.isSelfRelay.accept(groupInfo.isSelf)
            IMController.shared.getGroupMemberList(groupId: groupInfo.groupID, offset: 0, count: groupInfo.memberCount) { (members: [GroupMemberInfo]) in
                self?.allMembers = members.compactMap { $0.userID }
            }
        }
        // 获取自己的组内信息
        IMController.shared.getGroupMembersInfo(groupId: gid, uids: [IMController.shared.uid]) { [weak self] (members: [GroupMemberInfo]) in
            for member in members {
                if member.isSelf {
                    self?.myInfoInGroup.accept(member)
                }
            }
        }
    }

    func updateGroupName(_ name: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        guard let group = groupInfoRelay.value else { return }
        group.groupName = name
        IMController.shared.setGroupInfo(group: group) { [weak self] resp in
            self?.groupInfoRelay.accept(group)
            onSuccess(resp)
        }
    }

    func clearRecord(completion: @escaping CallBack.StringOptionalReturnVoid) {
        guard let groupID = conversation.groupID else { return }
        IMController.shared.clearGroupHistoryMessages(groupId: groupID) { [weak self] resp in
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

    func setNoDisturbWithNotRecieve() {
        IMController.shared.setConversationRecvMessageOpt(conversationIds: [conversation.conversationID], status: .notReceive, completion: { [weak self] _ in
            guard let sself = self else { return }
            self?.noDisturbRelay.accept(true)
        })
    }

    func setNoDisturbWithNotNotify() {
        IMController.shared.setConversationRecvMessageOpt(conversationIds: [conversation.conversationID], status: .notNotify, completion: { [weak self] _ in
            guard let sself = self else { return }
            self?.noDisturbRelay.accept(true)
        })
    }

    func setNoDisturbOff() {
        IMController.shared.setConversationRecvMessageOpt(conversationIds: [conversation.conversationID], status: .receive, completion: { [weak self] _ in
            guard let sself = self else { return }
            self?.noDisturbRelay.accept(false)
        })
    }

    func dismissGroup(onSuccess: @escaping CallBack.VoidReturnVoid) {
        guard let groupId = conversation.groupID else { return }
        IMController.shared.dismissGroup(id: groupId) { [weak self] _ in
            guard let sself = self else { return }
            let event = EventGroupDismissed(conversationId: sself.conversation.conversationID)
            JNNotificationCenter.shared.post(event)
            onSuccess()
        }
    }

    func quitGroup(onSuccess: @escaping CallBack.VoidReturnVoid) {
        guard let groupId = conversation.groupID else { return }
        IMController.shared.quitGroup(id: groupId) { [weak self] _ in
            guard let sself = self else { return }
            let event = EventGroupDismissed(conversationId: sself.conversation.conversationID)
            JNNotificationCenter.shared.post(event)
            onSuccess()
        }
    }

    func updateMyNicknameInGroup(_ nickname: String, onSuccess: @escaping CallBack.VoidReturnVoid) {
        guard let group = groupInfoRelay.value else { return }
        IMController.shared.setGroupMemberNicknameOf(userid: IMController.shared.uid, inGroupId: group.groupID, with: nickname) { [weak self] _ in
            let member = self?.myInfoInGroup.value
            member?.nickname = nickname
            self?.myInfoInGroup.accept(member)
            onSuccess()
        }
    }
}

extension GroupMemberInfo {
    func toUserInfo() -> UserInfo {
        let user = UserInfo()
        user.userID = userID ?? ""
        user.faceURL = faceURL
        user.nickname = nickname
        return user
    }
}
