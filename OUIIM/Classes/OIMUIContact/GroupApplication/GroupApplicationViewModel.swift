
import OUICore
import RxRelay

class GroupApplicationViewModel {
    let applicationItems: BehaviorRelay<[GroupApplicationInfo]> = .init(value: [])
    func getGroupApplications() {
        IMController.shared.getGroupApplicationList { [weak self] (applications: [GroupApplicationInfo]) in
            
            var t: [GroupApplicationInfo] = []
            
            applications.reversed().forEach { info in
                if info.handleResult == .normal {
                    t.insert(info, at: 0)
                } else {
                    t.append(info)
                }
            }
            
            self?.applicationItems.accept(t)
        }
    }

    func acceptApplicationWith(groupId: String, fromUserId: String) {
        IMController.shared.acceptGroupApplication(groupID: groupId, fromUserId: fromUserId) { [weak self] _ in
            self?.getGroupApplications()
            // 发送通知，告诉列表入群申请或者好友申请数量发生改变
            NotificationCenter.default.post(name: ContactsViewModel.NotificationApplicationCountChanged, object: nil)
        }
    }
    
    func apply(grouID: String, reqMsg: String?, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        IMController.shared.joinGroup(id: grouID, reqMsg: reqMsg, onSuccess: onSuccess)
    }
}
