
import OUICore
import RxRelay

class MemberListViewModel {
    let lettersRelay: BehaviorRelay<[String]> = .init(value: [])
    var members: [GroupMemberInfo] = []
    var contactSections: [[GroupMemberInfo]] = []
    var targetUserId: String?
    let targetIndexRelay: BehaviorRelay<IndexPath?> = .init(value: nil)
    let ownerAndAdminRelay: BehaviorRelay<[GroupMemberInfo]> = .init(value: [])
    
    let groupInfo: GroupInfo
    private var offset = 0
    private let limit = 1000
    init(groupInfo: GroupInfo) {
        self.groupInfo = groupInfo
    }
    
    func resetMembersArray() {
        self.offset = 0
        self.members.removeAll()
    }
    
    func getOwnerAndAdmin() {
        IMController.shared.getGroupMemberList(groupId: groupInfo.groupID, filter: .superAndAdmin, offset: 0, count: limit) { [weak self] infos in
            self?.ownerAndAdminRelay.accept(infos)
        }
    }

    func getMoreMembers(completion: ((Bool) -> Void)?) {
        IMController.shared.getGroupMemberList(groupId: groupInfo.groupID, filter: .member, offset: offset, count: limit) { [weak self] (members: [GroupMemberInfo]) in
            guard let sself = self else { return }
            if !members.isEmpty {
                sself.offset += sself.limit
            }
            self?.members.append(contentsOf: members)
            if members.isEmpty {
                completion?(true)
                return
            }
            self?.divideUsersInSection(users: sself.members, completion: completion)
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

    private func divideUsersInSection(users: [GroupMemberInfo], completion: ((Bool)-> Void)?) {
        DispatchQueue.global().async { [weak self] in
            var letterSet: Set<String> = []
            for user in users {
                if let firstLetter = user.nickname?.getFirstPinyinUppercaseCharactor() {
                    letterSet.insert(firstLetter)
                }
            }

            var letterArr: [String] = Array(letterSet)
            var isContainsSharp = false
            if letterArr.contains("#") {
                isContainsSharp = true
                letterArr.removeAll { (value: String) in
                    return value == "#"
                }
            }
            var ret = letterArr.sorted()
            if isContainsSharp {
                ret.append("#")
            }
            var sections: [[GroupMemberInfo]] = []
            for letter in ret {
                var sectionArr: [GroupMemberInfo] = []
                for user in users {
                    if let first = user.nickname?.getFirstPinyinUppercaseCharactor(), first == letter {
                        sectionArr.append(user)
                    }
                }
                sections.append(sectionArr)
            }
            self?.contactSections = sections
            DispatchQueue.main.async {
                completion?(false)
                self?.lettersRelay.accept(ret)
                var indexPath: IndexPath?
                for (section, contacts) in sections.enumerated() {
                    for (row, contact) in contacts.enumerated() {
                        if contact.userID == self?.targetUserId {
                            indexPath = IndexPath.init(row: row, section: section)
                        }
                    }
                }
                self?.targetIndexRelay.accept(indexPath)
            }
        }
    }
}
