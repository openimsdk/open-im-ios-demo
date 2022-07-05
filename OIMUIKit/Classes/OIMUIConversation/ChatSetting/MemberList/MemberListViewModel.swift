
import Foundation
import RxRelay

class MemberListViewModel {
    let lettersRelay: BehaviorRelay<[String]> = .init(value: [])
    var members: [GroupMemberInfo] = []
    var contactSections: [[GroupMemberInfo]] = []

    private let groupId: String
    private var offset = 0
    private let count = 40
    init(groupId: String) {
        self.groupId = groupId
    }

    func getMemberList() {
        IMController.shared.getGroupMemberList(groupId: groupId, offset: offset, count: count) { [weak self] (members: [GroupMemberInfo]) in
            self?.members = members
            self?.divideUsersInSection(users: members)
        }
    }

    func getMoreMembers() {
        IMController.shared.getGroupMemberList(groupId: groupId, offset: offset, count: count) { [weak self] (members: [GroupMemberInfo]) in
            guard let sself = self else { return }
            self?.members.append(contentsOf: members)
            self?.divideUsersInSection(users: sself.members)
        }
    }

    func getUsersAt(indexPaths: [IndexPath]) -> [GroupMemberInfo] {
        var users: [GroupMemberInfo] = []
        for indexPath in indexPaths {
            let user = contactSections[indexPath.section][indexPath.row]
            users.append(user)
        }
        return users
    }

    private func divideUsersInSection(users: [GroupMemberInfo]) {
        var letterSet: Set<String> = []
        for user in users {
            if let firstLetter = user.nickname?.pinyin()?[of: 0].uppercased() {
                letterSet.insert(firstLetter)
            }
        }

        let letterArr: [String] = Array(letterSet)
        let ret = letterArr.sorted { $0 < $1 }

        for letter in ret {
            var sectionArr: [GroupMemberInfo] = []
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
