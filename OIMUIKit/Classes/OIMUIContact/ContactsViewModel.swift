
import Foundation
import RxCocoa
import RxSwift

public class ContactsViewModel {
    let newFriendCountRelay: BehaviorRelay<Int> = .init(value: 0)
    let newGroupCountRelay: BehaviorRelay<Int> = .init(value: 0)
    let companyDepartments: [Department] = [
        Department(isHost: true, name: "托云信息技术有限公司"),
        Department(isHost: false, name: "组织架构"),
        Department(isHost: false, name: "技术部"),
    ]
    let frequentContacts: BehaviorRelay<[UserInfo]> = .init(value: [])
    public weak var dataSource: ContactsDataSource?
    private let _disposeBag = DisposeBag()
    init() {
        Observable.combineLatest(newFriendCountRelay, newGroupCountRelay) { (friendCount: Int, groupCount: Int) -> Int in
            friendCount + groupCount
        }.bind(to: IMController.shared.contactUnreadSubject).disposed(by: _disposeBag)

        IMController.shared.friendApplicationChangedSubject.subscribe(onNext: { [weak self] _ in
            self?.getFriendApplications()
        }).disposed(by: _disposeBag)

        IMController.shared.groupApplicationChangedSubject.subscribe(onNext: { [weak self] _ in
            self?.getGroupApplications()
        }).disposed(by: _disposeBag)

        IMController.shared.conversationChangedSubject.subscribe(onNext: { [weak self] (conversations: [ConversationInfo]) in
            var uList: [UserInfo] = []
            for conversation in conversations {
                if conversation.conversationType == .c2c {
                    let user = UserInfo()
                    user.userID = conversation.userID ?? ""
                    user.nickname = conversation.showName
                    user.faceURL = conversation.faceURL
                    uList.append(user)
                }
            }
            if !uList.isEmpty {
                self?.dataSource?.setFrequentUsers(uList.compactMap { $0.toOIMUserInfo() })
                self?.getFrequentUsers()
            }
        }).disposed(by: _disposeBag)

        IMController.shared.friendInfoChangedSubject.subscribe(onNext: { [weak self] (userInfo: UserInfo?) in
            guard let userInfo = userInfo, let sself = self else { return }
            let oldValues = sself.frequentContacts.value
            if let user = oldValues.first(where: { $0.userID == userInfo.userID }) {
                user.nickname = userInfo.nickname
                user.faceURL = userInfo.faceURL
            }
            sself.frequentContacts.accept(oldValues)
        }).disposed(by: _disposeBag)

        NotificationCenter.default.addObserver(self, selector: #selector(applicationCountChangedHandler), name: ContactsViewModel.NotificationApplicationCountChanged, object: nil)
    }

    func getFriendApplications() {
        IMController.shared.getFriendApplicationList { [weak self] (applications: [FriendApplication]) in
            let ret = applications.compactMap { $0.handleResult == .normal ? $0 : nil }
            self?.newFriendCountRelay.accept(ret.count)
        }
    }

    func getGroupApplications() {
        IMController.shared.getGroupApplicationList { [weak self] (applications: [GroupApplicationInfo]) in
            let ret = applications.compactMap { $0.handleResult == .normal ? $0 : nil }
            self?.newGroupCountRelay.accept(ret.count)
        }
    }

    func getFrequentUsers() {
        guard let dataSource = dataSource else {
            return
        }

        let items = dataSource.getFrequentUsers()
        frequentContacts.accept(items.compactMap { $0.toUserInfo() })
    }

    @objc private func applicationCountChangedHandler() {
        getFriendApplications()
        getGroupApplications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    static let NotificationApplicationCountChanged = NSNotification.Name(rawValue: "OIMNotificationApplicationCountChanged")

    struct Department {
        let isHost: Bool
        let name: String
    }
}
