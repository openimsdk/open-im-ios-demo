





import Foundation
import RxSwift
import RxCocoa

class GroupChatSettingViewModel {
    private(set) var conversation: ConversationInfo
    
    let membersRelay: BehaviorRelay<[UserInfo]> = .init(value: [])
    let membersCountRelay: BehaviorRelay<Int> = .init(value: 0)
    let noDisturbRelay: BehaviorRelay<Bool> = .init(value: false)
    let setTopContactRelay: BehaviorRelay<Bool> = .init(value: false)
    let isSelfRelay: BehaviorRelay<Bool> = .init(value: false)
    let groupInfoRelay: BehaviorRelay<GroupInfo?> = .init(value: nil)
    let myInfoInGroup: BehaviorRelay<GroupMemberInfo?> = .init(value: nil)
    
    init(conversation: ConversationInfo) {
        self.conversation = conversation
    }
    
    func getConversationInfo() {
        guard let gid = conversation.groupID else { return }

        IMController.shared.getConversation(sessionType: conversation.conversationType, sourceId: gid) { [weak self] (chat: ConversationInfo?) in
            guard let sself = self else { return }
            if let chat = chat {
                self?.conversation = chat
                self?.noDisturbRelay.accept(sself.conversation.recvMsgOpt == .notNotify)
                self?.setTopContactRelay.accept(sself.conversation.isPinned)
            }
        }
        
        IMController.shared.getGroupMemberList(groupId: gid, offset: 0, count: 6) { [weak self] (members: [GroupMemberInfo]) in
            var users = members.compactMap{ $0.toUserInfo() }
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
        }
        
        IMController.shared.getGroupMembersInfo(groupId: gid, uids: [IMController.shared.uid]) { [weak self] (members: [GroupMemberInfo]) in
            for member in members {
                if member.isSelf {
                    self?.myInfoInGroup.accept(member)
                }
            }
        }
    }
    
    func updateGroupName(_ name: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        guard let group = self.groupInfoRelay.value else { return }
        group.groupName = name
        IMController.shared.setGroupInfo(group: group) { [weak self] resp in
            self?.groupInfoRelay.accept(group)
            onSuccess(resp)
        }
    }
    
    func clearRecord(completion: @escaping CallBack.StringOptionalReturnVoid) {
        guard let uid = conversation.userID else { return }
        IMController.shared.clearC2CHistoryMessages(userId: uid) { [weak self] resp in
            guard let sself = self else { return }
            let event = EventRecordClear.init(conversationId: sself.conversation.conversationID)
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
    
    func dismissGroup() {
        guard let groupId = conversation.groupID else { return }
        IMController.shared.dismissGroup(id: groupId) { _ in
            
        }
    }
    
    func quitGroup() {
        guard let groupId = conversation.groupID else { return }
        IMController.shared.quitGroup(id: groupId) { _ in
            
        }
    }
    
    func updateMyNicknameInGroup(_ nickname: String, onSuccess: @escaping CallBack.VoidReturnVoid) {
        guard let group = self.groupInfoRelay.value else { return }
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
        user.userID = self.userID ?? ""
        user.faceURL = self.faceURL
        user.nickname = self.nickname
        return user
    }
}
