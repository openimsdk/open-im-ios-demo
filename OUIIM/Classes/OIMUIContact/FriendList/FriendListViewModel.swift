
import OUICore
import RxRelay

class FriendListViewModel {
    let lettersRelay: BehaviorRelay<[String]> = .init(value: [])
    var myFriends: [UserInfo] = []
    var contactSections: [[UserInfo]] = []
    
    var myGroups: [GroupInfo] = []
    var groupsSections: [[GroupInfo]] = []
    
    func getMyFriendList() {
        IMController.shared.getFriendList { [weak self] users in
            let r = users.compactMap({ UserInfo(userID: $0.userID!, nickname: $0.showName, faceURL: $0.faceURL) })
            self?.myFriends = r
            self?.divideUsersInSection(users: r ?? [])
        }
    }
    
    func getGroups() {
        IMController.shared.getJoinedGroupList { [weak self] groups in
            self?.myGroups = groups
            self?.divideGroupsInSection(groups)
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
        DispatchQueue.global().async { [weak self] in
            var letterSet: Set<String> = []
            for user in users {
                if let firstLetter = user.nickname?.getFirstPinyinUppercaseCharactor() {
                    letterSet.insert(firstLetter)
                }
            }

            let letterArr: [String] = Array(letterSet)
            let ret = letterArr.sorted { $0 < $1 }

            for letter in ret {
                var sectionArr: [UserInfo] = []
                for user in users {
                    if let first = user.nickname?.getFirstPinyinUppercaseCharactor(), first == letter {
                        sectionArr.append(user)
                    }
                }
                self?.contactSections.append(sectionArr)
            }
            DispatchQueue.main.async {
                self?.lettersRelay.accept(ret)
            }
        }
    }
    
    private func divideGroupsInSection(_ users: [GroupInfo]) {
        DispatchQueue.global().async { [weak self] in
            var letterSet: Set<String> = []
            for user in users {
                if let firstLetter = user.groupName?.getFirstPinyinUppercaseCharactor() {
                    letterSet.insert(firstLetter)
                }
            }

            let letterArr: [String] = Array(letterSet)
            let ret = letterArr.sorted { $0 < $1 }

            for letter in ret {
                var sectionArr: [GroupInfo] = []
                for user in users {
                    if let first = user.groupName?.getFirstPinyinUppercaseCharactor(), first == letter {
                        sectionArr.append(user)
                    }
                }
                self?.groupsSections.append(sectionArr)
            }
            DispatchQueue.main.async {
                self?.lettersRelay.accept(ret)
            }
        }
    }
}
