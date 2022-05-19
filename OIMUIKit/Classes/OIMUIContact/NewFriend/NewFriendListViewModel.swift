//


//




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
        IMController.shared.imManager.acceptFriendApplication(uid, handleMsg: "") { [weak self] (resp: String?) in
            self?.getNewFriendApplications()
            
            NotificationCenter.default.post(name: ContactsViewModel.NotificationApplicationCountChanged, object: nil)
        }
    }
}
