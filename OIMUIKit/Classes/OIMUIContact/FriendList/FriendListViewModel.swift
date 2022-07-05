
import Foundation
import RxRelay

class FriendListViewModel {
    let lettersRelay: BehaviorRelay<[String]> = .init(value: [])
    var myFriends: [UserInfo] = []
    var contactSections: [[UserInfo]] = []

    func getMyFriendList() {
        IMController.shared.getFriendList { [weak self] (users: [UserInfo]) in
            self?.myFriends = users
            self?.divideUsersInSection(users: users ?? [])
        }
    }

    func getUsersAt(indexPaths: [IndexPath]) -> [UserInfo] {
        var users: [UserInfo] = []
        for indexPath in indexPaths {
            let user = contactSections[indexPath.section][indexPath.row]
            users.append(user)
        }
        return users
    }

    func createConversationWith(users: [UserInfo], onSuccess: @escaping CallBack.VoidReturnVoid) {
        IMController.shared.createGroupConversation(users: users) { (_: GroupInfo?) in
            onSuccess()
        }
    }

    private func divideUsersInSection(users: [UserInfo]) {
        var letterSet: Set<String> = []
        for user in users {
            if let firstLetter = user.nickname?.pinyin()?[of: 0].uppercased() {
                letterSet.insert(firstLetter)
            }
        }

        let letterArr: [String] = Array(letterSet)
        let ret = letterArr.sorted { $0 < $1 }

        for letter in ret {
            var sectionArr: [UserInfo] = []
            for user in users {
                if let first = user.nickname?.pinyin()?[of: 0].uppercased(), first == letter {
                    sectionArr.append(user)
                }
            }
            contactSections.append(sectionArr)
        }
        lettersRelay.accept(ret)
    }
}
