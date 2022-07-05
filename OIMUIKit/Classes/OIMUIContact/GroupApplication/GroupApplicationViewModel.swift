
import Foundation
import RxRelay

class GroupApplicationViewModel {
    let applicationItems: BehaviorRelay<[GroupApplicationInfo]> = .init(value: [])
    func getGroupApplications() {
        IMController.shared.getGroupApplicationList { [weak self] (applications: [GroupApplicationInfo]) in
            self?.applicationItems.accept(applications)
        }
    }

    func acceptApplicationWith(groupId: String, fromUserId: String) {
        IMController.shared.imManager.acceptGroupApplication(groupId, fromUserId: fromUserId, handleMsg: nil) { [weak self] _ in
            self?.getGroupApplications()
            // 发送通知，告诉列表入群申请或者好友申请数量发生改变
            NotificationCenter.default.post(name: ContactsViewModel.NotificationApplicationCountChanged, object: nil)
        }
    }
}
