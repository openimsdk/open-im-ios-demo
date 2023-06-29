
import OUICore
import RxSwift
import RxRelay

class GroupDetailViewModel {
    let groupId: String

    let membersRelay: BehaviorRelay<[GroupMemberInfo]> = .init(value: [])
    let membersCountRelay: BehaviorRelay<Int> = .init(value: 0)
    let groupInfoRelay: BehaviorRelay<GroupInfo?> = .init(value: nil)
    let isInGroupSubject: PublishSubject<Bool> = .init()
    var allMembers: [String] = []

    init(groupId: String) {
        self.groupId = groupId
    }

    func getGroupInfo() {
        IMController.shared.getGroupMemberList(groupId: groupId, filter: .all, offset: 0, count: 6) { [weak self] (members: [GroupMemberInfo]) in
            self?.membersRelay.accept(members)
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
