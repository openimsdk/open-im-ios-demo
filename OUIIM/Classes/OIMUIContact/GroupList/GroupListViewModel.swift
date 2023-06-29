
import OUICore
import RxRelay
import RxSwift

class GroupListViewModel {
    let isICreateTableSelected: BehaviorRelay<Bool> = .init(value: true)
    let items: BehaviorRelay<[GroupInfo]> = .init(value: [])
    let myGroupsRelay: BehaviorRelay<[GroupInfo]> = .init(value: [])
    let lettersRelay: BehaviorRelay<[String]> = .init(value: [])

    private let _disposeBag = DisposeBag()
    private var iCreateGroups: [GroupInfo] = []
    private var iJoinedGroups: [GroupInfo] = []
    var members: [GroupMemberInfo] = []
    var contactSections: [[GroupMemberInfo]] = []

    init() {
        isICreateTableSelected.subscribe(onNext: { [weak self] (isICreated: Bool) in
            guard let sself = self else { return }
            if isICreated {
                self?.items.accept(sself.iCreateGroups)
            } else {
                self?.items.accept(sself.iJoinedGroups)
            }
        }).disposed(by: _disposeBag)
    }

    func getMyGroups() {
        IMController.shared.getJoinedGroupList { [weak self] (groups: [GroupInfo]) in
            let groups: [GroupInfo] = groups ?? []
            var createGroups: [GroupInfo] = []
            var joinedGroups: [GroupInfo] = []
            for group in groups {
                if group.creatorUserID == IMController.shared.uid {
                    createGroups.append(group)
                } else {
                    joinedGroups.append(group)
                }
            }
            self?.iCreateGroups = createGroups
            self?.iJoinedGroups = joinedGroups
            self?.myGroupsRelay.accept(groups)
            self?.isICreateTableSelected.accept(true)
        }
    }
    
    func getGroupMemberList(groupID: String) {
        IMController.shared.getGroupMemberList(groupId: groupID, offset: 0, count: 1000) { (members: [GroupMemberInfo]) in
            self.members = members
            self.divideUsersInSection(users: members)
        }
    }
    
    func getUsersAt(indexPaths: [IndexPath]) -> [UserInfo] {
        var users: [UserInfo] = []
        for indexPath in indexPaths {
            let member = contactSections[indexPath.section][indexPath.row]
            let user = UserInfo(userID: member.userID!, nickname: member.nickname, faceURL: member.faceURL)
            
            users.append(user)
        }
        return users
    }
    
    private func divideUsersInSection(users: [GroupMemberInfo]) {
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
                var sectionArr: [GroupMemberInfo] = []
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
}
