
import Foundation
import RxCocoa
import RxSwift

class GroupDetailViewModel {
    let groupId: String

    let membersRelay: BehaviorRelay<[UserInfo]> = .init(value: [])
    let membersCountRelay: BehaviorRelay<Int> = .init(value: 0)
    let groupInfoRelay: BehaviorRelay<GroupInfo?> = .init(value: nil)
    let isInGroupSubject: PublishSubject<Bool> = .init()
    var allMembers: [String] = []

    init(groupId: String) {
        self.groupId = groupId
    }

    func getGroupInfo() {
        IMController.shared.getGroupMemberList(groupId: groupId, offset: 0, count: 6) { [weak self] (members: [GroupMemberInfo]) in
            var users = members.compactMap { $0.toUserInfo() }
            let fakeUser = UserInfo()
            fakeUser.isButton = true
            users.append(fakeUser)
            self?.membersRelay.accept(users)
        }

        IMController.shared.getGroupInfo(groupIds: [groupId]) { [weak self] (groupInfos: [GroupInfo]) in
            guard let sself = self else { return }
            guard let groupInfo = groupInfos.first else { return }
            self?.groupInfoRelay.accept(groupInfo)
            self?.membersCountRelay.accept(groupInfo.memberCount)
            IMController.shared.getGroupMemberList(groupId: sself.groupId, offset: 0, count: groupInfo.memberCount) { (members: [GroupMemberInfo]) in
                self?.allMembers = members.compactMap { $0.userID }
            }
        }
        // 获取自己的组内信息
        IMController.shared.getGroupMembersInfo(groupId: groupId, uids: [IMController.shared.uid]) { [weak self] (members: [GroupMemberInfo]) in
            self?.isInGroupSubject.onNext(!members.isEmpty)
        }
    }

    func joinCurrentGroup(onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        IMController.shared.joinGroup(id: groupId, reqMsg: nil, onSuccess: onSuccess)
    }
}
