
import Foundation
import RxRelay

class NewFriendListViewModel {
    let applications: BehaviorRelay<[FriendApplication]> = .init(value: [])

    func getNewFriendApplications() {
        IMController.shared.getFriendApplicationList { [weak self] (applications: [FriendApplication]) in
            self?.applications.accept(applications)
        }
    }

    func acceptFriendWith(uid: String) {
        IMController.shared.imManager.acceptFriendApplication(uid, handleMsg: "") { [weak self] (_: String?) in
            self?.getNewFriendApplications()
            // 发送通知，告诉列表入群申请或者好友申请数量发生改变
            NotificationCenter.default.post(name: ContactsViewModel.NotificationApplicationCountChanged, object: nil)
        }
    }
}
